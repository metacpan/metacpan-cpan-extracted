package App::Actions::Docker;

use strict;
use warnings;
use Carp qw(croak);

use File::Spec;
use Scalar::Util qw(blessed);

use App::Actions::Docker::Variable;
use App::Actions::Process;

# The variables the docker client reads for itself.  A job variable with one
# of these names stays on the command line: set in the client's environment
# it would change where the client connects, what it trusts or where it
# finds programs.
my $CLIENT_VARIABLE = qr/
    \A (?:
        DOCKER_\w* | BUILDKIT_\w* | COMPOSE_\w*
        | PATH | PATHEXT | HOME | USERPROFILE | APPDATA | LOCALAPPDATA
        | TMPDIR | TMP | TEMP | XDG_\w+
        | (?: HTTPS? | NO | ALL | FTP ) _PROXY
        | SSL_CERT_(?: FILE | DIR )
    ) \z
/xi;

# A name a process environment can carry on every platform.  - and . are
# allowed after the first character because GitHub's INPUT_* names keep
# them (INPUT_GITHUB-TOKEN), and such a value is often a secret.
my $VARIABLE_NAME = qr/\A[A-Za-z_][A-Za-z0-9_.-]*\z/;

our $VERSION = '0.002.0';

sub new {
    my ($class, %args) = @_;

    my %secret_names;
    my %secret_values;
    if ($args{secrets}) {
        for my $name (keys %{ $args{secrets} }) {
            $secret_names{$name} = 1;
            my $value = $args{secrets}{$name};
            next unless defined $value && length $value;
            $secret_values{$value} = 1;
        }
    }

    my $bin = $args{bin} || $ENV{DOCKER} || 'docker';

    return bless {
        bin           => $bin,
        interpreter   => [ _interpreter_prefix($bin) ],
        dry_run       => $args{dry_run} ? 1 : 0,
        # A dry run can also be the one that reports containers rather than
        # commands: the report is the point, so the commands stay out of it.
        explain       => $args{explain} ? 1 : 0,
        verbose       => $args{verbose} ? 1 : 0,
        quiet         => $args{quiet} ? 1 : 0,
        platform      => $args{platform},
        secret_names  => \%secret_names,
        secret_values => \%secret_values,
    }, $class;
}

# The Docker command may be a wrapper script instead of a native executable.
# Windows cannot start a shebang script directly, and a script without the
# executable bit cannot be started on Unix either, so a Perl wrapper is run
# with the current interpreter.  Anything else is used as given.
sub _interpreter_prefix {
    my ($bin) = @_;

    return () unless defined $bin && length $bin && !ref $bin;
    return () unless -f $bin;
    return () if $bin =~ /\.(?:exe|com|bat|cmd)\z/i;
    return ($^X) if $bin =~ /\.pl\z/i;

    # Only the first line matters, and the command may be a large binary, so
    # read a bounded amount rather than a whole line.
    open my $handle, '<', $bin or return ();
    my $header = '';
    read($handle, $header, 256);
    close $handle;

    return () unless defined $header && $header =~ /^#!.*\bperl/;

    return ($^X);
}

sub _command {
    my ($self, @args) = @_;
    return (@{ $self->{interpreter} }, $self->{bin}, @args);
}

sub bin     { return $_[0]->{bin} }
sub dry_run { return $_[0]->{dry_run} }
sub explain { return $_[0]->{explain} }
sub verbose { return $_[0]->{verbose} }
sub quiet   { return $_[0]->{quiet} }

sub platform_args {
    my ($self) = @_;
    return (defined $self->{platform} && length $self->{platform}) ? ('--platform', $self->{platform}) : ();
}

sub check {
    my ($self) = @_;

    return 1 if $self->{dry_run};

    my ($version, $version_rc) = $self->capture_silent('--version');
    if ($version_rc != 0) {
        croak "Docker executable '$self->{bin}' was not found or is not usable";
    }
    print $version if $self->{verbose} && !$self->{quiet} && length $version;

    my (undef, $rc) = $self->{quiet}
        ? $self->capture_silent('info', '--format', '{{.ServerVersion}}')
        : $self->capture('info', '--format', '{{.ServerVersion}}');
    if ($rc != 0) {
        croak "Cannot connect to the Docker daemon. Is Docker running, and can this user access it?";
    }

    return 1;
}

sub image_exists {
    my ($self, $image) = @_;

    # A dry run starts nothing, so every image is as good as present.
    my $rc = $self->{dry_run} ? 0 : ($self->capture_silent('image', 'inspect', '--format', '{{.Id}}', $image))[1];

    return $rc == 0 ? 1 : 0;
}

# The size of an image in bytes, or undef when the daemon does not have it.
# This is what the image cache reports, so it must not be an error for the
# image to be absent: an image removed outside the tool is a fact to show, not
# a reason to fail.
sub image_size {
    my ($self, $image) = @_;

    return undef if $self->{dry_run};

    my ($output, $rc) = $self->capture_silent(
        'image', 'inspect', '--format', '{{.Size}}', $image,
    );
    return undef if $rc != 0;

    $output = '' unless defined $output;
    $output =~ s/\s+//g;

    return $output =~ /\A\d+\z/ ? $output + 0 : undef;
}

sub pull {
    my ($self, $image) = @_;

    my @args = ('pull');
    push @args, $self->platform_args;
    push @args, $image;

    my $rc = $self->run(@args);
    # die, not croak, and with a trailing newline: this is advice for the
    # reader, not a place to point at source lines.
    die "Failed to pull Docker image '$image' (exit $rc)\n" if $rc != 0;
    return 1;
}

# Pull several images at once and report the exit status of each.  Docker's
# own output goes straight to the terminal, so a slow image is still visible
# while the others finish.  The result is keyed by image name, which lets the
# caller say which images failed and what needed them.
sub pull_many {
    my ($self, $images, %options) = @_;

    croak 'No images given' unless ref $images eq 'ARRAY' && @$images;

    # A caller that is building a machine-readable report asks for silence:
    # docker's own progress lines would not be part of any document.
    my $quiet = $options{quiet} ? 1 : 0;

    if ($self->{dry_run}) {
        for my $image (@$images) {
            print "[dry-run] $self->{bin} ",
                $self->_display('pull', $self->platform_args, $image), "\n"
                unless $self->{quiet} || $quiet || $self->{explain};
        }
        return { map { $_ => 0 } @$images };
    }

    # The command lines are printed before anything starts, because the
    # children then write to the same terminal in no particular order.
    if ($self->{verbose} && !$self->{quiet} && !$quiet) {
        for my $image (@$images) {
            print "+ $self->{bin} ",
                $self->_display('pull', $self->platform_args, $image), "\n";
        }
    }

    my @commands = map {
        [ $self->_command('pull', $self->platform_args, $_) ]
    } @$images;

    my %redirect;
    if ($quiet) {
        my $devnull = File::Spec->devnull;
        %redirect = (stdout => $devnull, stderr => $devnull);
    }

    my $codes = App::Actions::Process::run_parallel(
        \@commands,
        concurrency => $options{concurrency} || 4,
        %redirect,
    );

    my %results;
    for my $index (0 .. $#$images) {
        $results{ $images->[$index] } = $codes->[$index];
    }

    return \%results;
}

sub image_remove {
    my ($self, $image) = @_;

    return $self->run_silent('image', 'rm', '-f', $image);
}

sub network_create {
    my ($self, $name) = @_;
    return $self->run_silent('network', 'create', $name);
}

sub network_remove {
    my ($self, $name) = @_;
    return $self->run_silent('network', 'rm', $name);
}

sub container_start {
    my ($self, @args) = @_;
    return $self->run_silent('run', '-d', @args);
}

# The same start, with what the daemon said kept rather than discarded.  A
# start that fails explains itself on standard error - the image it cannot
# use, the entrypoint the image does not have, the port already taken - and
# that text is the only account of the failure; the exit status alone leaves a
# reader comparing the command with the number.  Returns the output and the
# status, in the order capture uses.
sub container_start_captured {
    my ($self, @args) = @_;

    my ($output, $rc) = $self->capture_merged('run', '-d', @args);

    return (defined $output ? $output : '', $rc);
}

sub container_exec {
    my ($self, @args) = @_;
    return $self->run('exec', @args);
}

sub container_running {
    my ($self, $name) = @_;

    return 1 if $self->{dry_run};

    my ($output, $rc) = $self->capture_silent(
        'inspect', '--format', '{{.State.Running}}', $name,
    );
    return 1 if $rc == 0 && $output =~ /true/;
    return 0;
}

sub container_logs {
    my ($self, $name, $lines) = @_;

    $lines = 200 unless defined $lines;
    return $self->run('logs', '--tail', $lines, $name);
}

# The last lines a container printed, as text rather than streamed to the
# caller, with the container's standard error merged in: a container that
# stopped is as likely to have said why on one stream as the other, and a
# message that quotes it has room for both.
sub container_log_text {
    my ($self, $name, $lines) = @_;

    $lines = 10 unless defined $lines;

    return '' if $self->{dry_run};

    my ($output) = $self->capture_merged('logs', '--tail', $lines, $name);

    return defined $output ? $output : '';
}

# The status a container exited with, or undef when the daemon cannot say -
# the container may have been removed already, or the inspect may have raced a
# cleanup.
sub container_exit_code {
    my ($self, $name) = @_;

    # A dry run's containers all exit cleanly.
    my $output = $self->{dry_run} ? '0' : $self->_inspect_field($name, '{{.State.ExitCode}}');

    return defined $output && $output =~ /\A-?\d+\z/ ? $output + 0 : undef;
}

# The state the daemon reports for the container: running, restarting,
# exited, dead, or undef when the daemon cannot describe it.
sub container_status {
    my ($self, $name) = @_;

    # A dry run's containers are all running.
    my $output = $self->{dry_run} ? 'running' : $self->_inspect_field($name, '{{.State.Status}}');

    return defined $output && length $output ? $output : undef;
}

# How many times the restart policy has restarted the container, or undef when
# the daemon cannot say.  0 is the normal answer for one that has stayed up.
sub container_restart_count {
    my ($self, $name) = @_;

    # A dry run's containers never restart.
    my $output = $self->{dry_run} ? '0' : $self->_inspect_field($name, '{{.RestartCount}}');

    return defined $output && $output =~ /\A\d+\z/ ? $output + 0 : undef;
}

# _inspect_field
# Purpose:     Ask the daemon for one field of a container's inspect output.
# Entry:       $name - the container; $format - a Go template such as
#              '{{.State.Status}}'.
# Exit status: Returns the field with all white space removed, or undef when
#              the inspect failed (the container is gone, or the daemon is).
# Side effects: Runs docker inspect, with its standard error discarded.
sub _inspect_field {
    my ($self, $name, $format) = @_;

    my ($output, $rc) = $self->capture_silent('inspect', '--format', $format, $name);

    # Every field read this way is a single token, so white space is only
    # the trailing newline and any CR a Windows client adds.
    (my $field = defined $output ? $output : '') =~ s/\s+//g;

    return $rc == 0 ? $field : undef;
}

sub container_remove {
    my ($self, $name) = @_;
    return $self->run_silent('rm', '-f', $name);
}

sub run {
    my ($self, @args) = @_;

    return $self->_announce(@args)
        ? $self->_spawn(\&App::Actions::Process::stream, @args)
        : 0;
}

sub run_silent {
    my ($self, @args) = @_;

    return $self->_announce(@args)
        ? $self->_spawn(\&App::Actions::Process::run_quiet, @args)
        : 0;
}

# _spawn
# Purpose:     Start the docker client with the job's variables kept off its
#              command line.  Every user of the host can read a process's
#              arguments (ps, /proc/PID/cmdline), so "-e TOKEN=value" there
#              publishes the value; the client's environment is readable only
#              by its own user.  docker reads "-e NAME" from that environment.
# Entry:       $starter - the App::Actions::Process function to run it with;
#              @args - the docker arguments.
# Exit status: Returns what $starter returns.
# Side effects: Sets the hidden variables in %ENV for the duration of the call.
sub _spawn {
    my ($self, $starter, @args) = @_;

    my ($command, $hidden) = $self->_hide_variables(@args);
    local @ENV{ keys %{$hidden} } = values %{$hidden};

    return $starter->([ $self->_command(@{$command}) ]);
}

# _hide_variables
# Purpose:     Turn each job variable (an App::Actions::Docker::Variable, as
#              App::Actions::Runner::Support::env_args makes them) into
#              "NAME" plus an environment entry, and every other argument into
#              the string it is.  Only those objects are touched, so a "-e"
#              meant for the program in the container is left alone.
# Entry:       @args.
# Exit status: Returns (\@arguments, \%environment).
# Side effects: None.
sub _hide_variables {
    my (undef, @args) = @_;

    # On Windows names differ only in case are one variable, so a name that
    # clashes with another in the same command stays on the command line.
    my %seen;
    $seen{ lc $_->name }++ for grep { blessed($_) && $_->isa('App::Actions::Docker::Variable') } @args;

    my (@command, %hidden);
    for my $arg (@args) {
        if (!(blessed($arg) && $arg->isa('App::Actions::Docker::Variable'))) {
            push @command, $arg;
            next;
        }

        my ($name, $value) = ($arg->name, $arg->value);
        my $hideable = $name =~ $VARIABLE_NAME && $name !~ $CLIENT_VARIABLE
            && $seen{ lc $name } == 1 && index($value, "\0") < 0;

        push @command, $hideable ? $name : "$name=$value";
        $hidden{$name} = $value if $hideable;
    }

    return (\@command, \%hidden);
}

# _announce
# Purpose:     Print the command about to run, the way the mode asks for.
# Entry:       @args - the Docker arguments.
# Exit status: Returns 1 when the command should be run, 0 in a dry run.
# Side effects: Prints "[dry-run] ..." in a dry run (unless quiet or
#              explaining) and "+ ..." when verbose (unless quiet).  Secrets
#              are redacted from what is printed, never from what is run.
sub _announce {
    my ($self, @args) = @_;

    my $display = $self->_display(@args);

    if ($self->{dry_run}) {
        print "[dry-run] $self->{bin} $display\n"
            unless $self->{quiet} || $self->{explain};
        return 0;
    }

    print "+ $self->{bin} $display\n" if $self->{verbose} && !$self->{quiet};

    return 1;
}

sub capture {
    my ($self, @args) = @_;
    return $self->_capture(0, 0, @args);
}

sub capture_silent {
    my ($self, @args) = @_;
    return $self->_capture(1, 0, @args);
}

# Capture both of the command's streams, as if it had been run with 2>&1.
sub capture_merged {
    my ($self, @args) = @_;
    return $self->_capture(1, 1, @args);
}

sub _capture {
    my ($self, $quiet_stderr, $merge_stderr, @args) = @_;

    return ('', 0) unless $self->_announce(@args);

    my ($command, $hidden) = $self->_hide_variables(@args);
    local @ENV{ keys %{$hidden} } = values %{$hidden};

    return App::Actions::Process::capture(
        [ $self->_command(@{$command}) ],
        quiet_stderr => $quiet_stderr,
        merge_stderr => $merge_stderr,
    );
}

sub redact {
    my ($self, $text) = @_;

    return $text unless defined $text;

    # Longest first: when one secret contains another, replacing the shorter
    # one first would leave the rest of the longer one in the text ("abc" and
    # "abcdef" would print "***def").
    for my $secret (sort { length $b <=> length $a || $a cmp $b } keys %{ $self->{secret_values} }) {
        $text =~ s/\Q$secret\E/***/g;
    }

    return $text;
}

sub _display {
    my ($self, @args) = @_;

    my @copy = @args;
    for my $arg (@copy) {
        next unless defined $arg;
        if ($arg =~ /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/s
            && $self->{secret_names}{$1}) {
            $arg = "$1=***";
            next;
        }
        $arg = $self->redact($arg);
    }

    return join ' ', map { _quote($_) } @copy;
}

sub _quote {
    my ($argument) = @_;

    # Empty becomes '', a safe word stays bare, and anything else is single
    # quoted with each embedded quote closed, escaped and reopened.
    my $copy = defined $argument ? $argument : '';

    return !length $copy ? q{''}
        : $copy =~ /\A[A-Za-z0-9_@%+=:,.\/-]+\z/ ? $copy
        : "'" . ($copy =~ s/'/'\\''/gr) . "'";
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Docker - run Docker commands for the workflow runner

=head1 SYNOPSIS

Check that Docker works, then pull an image:

    use App::Actions::Docker;

    my $docker = App::Actions::Docker->new(verbose => 1);
    $docker->check;                  # dies if Docker is missing or not running
    $docker->pull('perl:5.40');      # dies if the pull fails

Start a container, run a command in it, and remove it:

    $docker->container_start('--name', 'job1', 'perl:5.40', 'sleep', 'infinity');
    my $status = $docker->container_exec('job1', 'perl', '-v');
    $docker->container_remove('job1');

Pass a secret without showing it to other users:

    use App::Actions::Docker::Variable;

    my $docker = App::Actions::Docker->new(secrets => { TOKEN => $token });
    $docker->run('run', '--rm',
        '-e', App::Actions::Docker::Variable->new(TOKEN => $token),
        'alpine', 'sh', '-c', 'test -n "$TOKEN"');

See what would run, without running it:

    my $docker = App::Actions::Docker->new(dry_run => 1);
    $docker->run('run', '--rm', 'alpine', 'true');
    # prints: [dry-run] docker run --rm alpine true

Read the output of a command:

    my ($output, $status) = $docker->capture('ps', '--format', '{{.Names}}');

=head1 DESCRIPTION

This module is the only place where the distribution starts the C<docker>
program.  It gives the rest of the code one method for each Docker task, and
it adds four things on top of the plain command line:

=over 4

=item * B<Dry run.>  With C<dry_run>, nothing is started.  Each command is
printed with C<[dry-run]> in front, and each method returns the answer that
a successful command would give.

=item * B<Verbose output.>  With C<verbose>, each command is printed with
C<+> in front before it runs.

=item * B<Secret redaction.>  Every printed command has the values of the
known secrets replaced by C<***>.  This changes only what is printed, never
what runs.

=item * B<Private job variables.>  See L</Job variables>.

=back

The Docker program does not have to be the real C<docker> binary.  It is
chosen in this order: the C<bin> argument, the C<DOCKER> environment
variable, then C<docker> on the C<PATH>.  If it is a Perl script (its first
line is a C<#!> line naming C<perl>, or its name ends in C<.pl>), it is run
with the same Perl as this program.  So a Perl wrapper works on Windows too,
where the system cannot start a C<#!> script by itself.

No method uses a shell.  Arguments are passed to Docker exactly as given,
so spaces, quotes and C<$> in them are safe.

=head2 Job variables

Every user of the host can read a process's arguments (with C<ps>, or from
F</proc/PID/cmdline>), so a C<-e TOKEN=value> on the docker client's command
line would publish the value.  A job variable is therefore passed as an
L<App::Actions::Docker::Variable> object after C<-e>.  When the command
runs, the object becomes a bare C<-e NAME>, and the value is put in the
client's environment, which only its own user can read, for that one
command.  The client reads C<-e NAME> from its environment.

A variable stays on the command line as C<NAME=VALUE> when hiding it would
change what the command does:

=over 4

=item * the name is not one an environment can carry (letters, digits,
C<_>, C<-> and C<.>, starting with a letter or C<_>);

=item * the name is one the docker client reads for itself, such as
C<DOCKER_HOST>, C<PATH>, C<HOME>, C<TMPDIR>, C<HTTPS_PROXY> or
C<SSL_CERT_FILE>: set in the client's environment it would change where the
client connects, what it trusts or where it finds programs;

=item * another variable in the same command has the same name in a
different case, which Windows would treat as one variable;

=item * the value contains a NUL character, which no environment can hold.

=back

Arguments that are plain strings, including a C<-e NAME=VALUE> meant for the
program inside the container, are passed exactly as given.  What is printed
in verbose and dry-run modes is the C<NAME=VALUE> form, with secrets
redacted.

=head1 METHODS

=head2 new

    my $docker = App::Actions::Docker->new(%options);

Makes a Docker object.  Nothing is run yet.

=head3 ARGUMENTS

All are optional.

=over 4

=item * C<bin> - the Docker program.  Default: C<$ENV{DOCKER}>, then
C<docker>.

=item * C<dry_run> - true to print commands instead of running them.

=item * C<explain> - true in a dry run that prints a report of its own:
then the C<[dry-run]> lines are not printed.

=item * C<verbose> - true to print each command before it runs.

=item * C<quiet> - true to print nothing extra.  It wins over C<verbose>.

=item * C<platform> - a platform such as C<linux/amd64>, given to C<docker
pull> as C<--platform>.

=item * C<secrets> - a hash reference of secret names to values.  Their
values are replaced by C<***> in printed commands, and a C<NAME=VALUE>
argument whose name is a secret prints as C<NAME=***>.

=back

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

Reads the first 256 bytes of the Docker program, to see if it is a Perl
script.

=head3 EXAMPLE

    my $docker = App::Actions::Docker->new(
        bin      => '/usr/local/bin/docker',
        verbose  => 1,
        platform => 'linux/arm64',
        secrets  => { API_KEY => $key },
    );

=head3 API SPECIFICATION

=head4 INPUT

    {
        bin      => { type => 'string', min => 1, optional => 1 },
        dry_run  => { type => 'boolean', optional => 1 },
        explain  => { type => 'boolean', optional => 1 },
        verbose  => { type => 'boolean', optional => 1 },
        quiet    => { type => 'boolean', optional => 1 },
        platform => { type => 'string', optional => 1 },
        secrets  => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'object', isa => 'App::Actions::Docker' }

=head3 MESSAGES

None.

=head2 bin

    my $program = $docker->bin;

Returns the Docker program this object runs, as chosen by L</new>.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 dry_run

    if ($docker->dry_run) { ... }

Returns 1 in a dry run, else 0.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 explain

    if ($docker->explain) { ... }

Returns 1 if the object was made with C<explain>, else 0.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 verbose

    if ($docker->verbose) { ... }

Returns 1 if the object was made with C<verbose>, else 0.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 quiet

    if ($docker->quiet) { ... }

Returns 1 if the object was made with C<quiet>, else 0.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 platform_args

    my @args = $docker->platform_args;

Returns C<('--platform', $platform)> if a platform was given to L</new>,
or an empty list.  Add it to your own C<docker> commands that accept
C<--platform>.

=head3 EXAMPLE

    $docker->run('run', $docker->platform_args, '--rm', 'alpine', 'uname', '-m');

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'array', max => 2 }

=head3 MESSAGES

None.

=head2 check

    $docker->check;

Makes sure that the Docker program exists and that the Docker daemon (the
background service) answers.

=head3 ARGUMENTS

None.

=head3 RETURNS

1.  In a dry run, 1 at once, without checking.

=head3 SIDE EFFECTS

Runs C<docker --version> and C<docker info>.  When C<verbose>, prints the
version.  Unless C<quiet>, the error output of C<docker info> is shown.

=head3 EXAMPLE

    eval { $docker->check; 1 } or die "Please start Docker first: $@";

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 1 ] }

=head3 MESSAGES

    +-------------------------------------------+-------------------------+-------------------------------+
    | Exception (croak)                         | Meaning                 | What to do                    |
    +-------------------------------------------+-------------------------+-------------------------------+
    | Docker executable 'BIN' was not found or  | "BIN --version" failed  | install Docker, or set DOCKER |
    | is not usable                             |                         | or --docker to the program    |
    | Cannot connect to the Docker daemon. Is   | "BIN info" failed       | start Docker; add your user   |
    | Docker running, and can this user access  |                         | to the docker group           |
    | it?                                       |                         |                               |
    +-------------------------------------------+-------------------------+-------------------------------+

=head2 image_exists

    if ($docker->image_exists('perl:5.40')) { ... }

Says whether the image is already on this computer.

=head3 ARGUMENTS

=over 4

=item * C<$image> - an image name, such as C<perl:5.40>.

=back

=head3 RETURNS

1 if it is, 0 if not.  Always 1 in a dry run.

=head3 SIDE EFFECTS

Runs C<docker image inspect>.

=head3 API SPECIFICATION

=head4 INPUT

    { image => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 image_size

    my $bytes = $docker->image_size('perl:5.40');

Returns the size of a local image in bytes.

=head3 ARGUMENTS

=over 4

=item * C<$image> - an image name.

=back

=head3 RETURNS

The size, or C<undef> if the image is not on this computer, Docker cannot
say, or this is a dry run.  A missing image is not an error.

=head3 SIDE EFFECTS

Runs C<docker image inspect>.

=head3 API SPECIFICATION

=head4 INPUT

    { image => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, optional => 1 }

=head3 MESSAGES

None.

=head2 pull

    $docker->pull('perl:5.40');

Downloads an image.  Docker's progress is shown on the terminal.

=head3 ARGUMENTS

=over 4

=item * C<$image> - an image name.

=back

=head3 RETURNS

1 on success.

=head3 SIDE EFFECTS

Runs C<docker pull>, with C<--platform> if one was given to L</new>.

=head3 API SPECIFICATION

=head4 INPUT

    { image => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', memberof => [ 1 ] }

=head3 MESSAGES

    +------------------------------------------+---------------------+-------------------------------+
    | Exception (die)                          | Meaning             | What to do                    |
    +------------------------------------------+---------------------+-------------------------------+
    | Failed to pull Docker image 'IMAGE'      | docker pull failed  | check the name, your network  |
    | (exit N)                                 | with status N       | and "docker login"            |
    +------------------------------------------+---------------------+-------------------------------+

=head2 pull_many

    my $results = $docker->pull_many(\@images, concurrency => 4);

Downloads several images at the same time.

=head3 ARGUMENTS

=over 4

=item * C<\@images> - the image names.  At least one.

=item * C<concurrency> - optional.  How many pulls run at once.  Default 4.

=item * C<quiet> - optional.  True to hide Docker's output, for example when
you are building a report.

=back

=head3 RETURNS

A hash reference from each image name to the exit status of its pull.  0
means success.  In a dry run, every status is 0.

=head3 SIDE EFFECTS

Starts one C<docker pull> per image, at most C<concurrency> at a time.  When
C<verbose>, all the commands are printed first, because the pulls then write
to the terminal in no fixed order.

=head3 EXAMPLE

    my $results = $docker->pull_many(['alpine:3', 'perl:5.40']);
    my @failed = grep { $results->{$_} != 0 } sort keys %{$results};

=head3 API SPECIFICATION

=head4 INPUT

    {
        images      => { type => 'arrayref', min => 1, element_type => 'string' },
        concurrency => { type => 'integer', min => 1, optional => 1, default => 4 },
        quiet       => { type => 'boolean', optional => 1 },
    }

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

    +------------------+-----------------------------+------------------------+
    | Exception (croak)| Meaning                     | What to do             |
    +------------------+-----------------------------+------------------------+
    | No images given  | the list was empty or not   | pass an array          |
    |                  | an array reference          | reference with names   |
    +------------------+-----------------------------+------------------------+

=head2 image_remove

    my $status = $docker->image_remove('perl:5.40');

Removes a local image, even if a stopped container uses it (C<docker image
rm -f>).

=head3 RETURNS

The exit status of the command: 0 on success.  0 in a dry run.

=head3 SIDE EFFECTS

Runs the command with its output hidden.

=head3 API SPECIFICATION

=head4 INPUT

    { image => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.  Check the status.

=head2 network_create

    my $status = $docker->network_create('job-net');

Makes a Docker network, so that a job container and its service containers
can reach each other by name.

=head3 RETURNS

The exit status: 0 on success.  0 in a dry run.

=head3 SIDE EFFECTS

Runs C<docker network create> with its output hidden.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.  Check the status.

=head2 network_remove

    my $status = $docker->network_remove('job-net');

Removes a Docker network.

=head3 RETURNS

The exit status: 0 on success.  0 in a dry run.

=head3 SIDE EFFECTS

Runs C<docker network rm> with its output hidden.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.  Check the status.

=head2 container_start

    my $status = $docker->container_start(@run_arguments);

Starts a container in the background (C<docker run -d ...>).

=head3 ARGUMENTS

=over 4

=item * C<@run_arguments> - everything after C<docker run -d>: options, the
image and the command.  L<App::Actions::Docker::Variable> objects after
C<-e> are kept off the command line.

=back

=head3 RETURNS

The exit status: 0 if the container started.  0 in a dry run.

=head3 SIDE EFFECTS

Runs the command with its output hidden.

=head3 EXAMPLE

    $docker->container_start('--name', 'job1', '--network', 'job-net', 'perl:5.40', 'sleep', 'infinity');

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.  Use L</container_start_captured> to learn why a start failed.

=head2 container_start_captured

    my ($output, $status) = $docker->container_start_captured(@run_arguments);

Like L</container_start>, but also returns what Docker printed, with its
error output included.  When a start fails, that text says why (for example
"port is already allocated").

=head3 RETURNS

A list of two values: the text (never C<undef>), and the exit status.

=head3 SIDE EFFECTS

Runs C<docker run -d>.  Nothing is printed.

=head3 EXAMPLE

    my ($output, $status) = $docker->container_start_captured('--name', 'db', 'postgres:16');
    die "The database did not start: $output" if $status != 0;

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'array', min => 2, max => 2 }    # (string, integer)

=head3 MESSAGES

None.

=head2 container_exec

    my $status = $docker->container_exec('job1', 'sh', '-c', 'make test');

Runs a command in a running container (C<docker exec ...>).  Its output is
shown on the terminal as it happens.

=head3 RETURNS

The exit status of the command in the container.  0 in a dry run.

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 2 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.

=head2 container_running

    if ($docker->container_running('job1')) { ... }

Says whether a container is running now.

=head3 RETURNS

1 if it is, 0 if it is not or does not exist.  Always 1 in a dry run.

=head3 SIDE EFFECTS

Runs C<docker inspect>.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head2 container_logs

    $docker->container_logs('job1', 50);

Shows the last lines a container printed, on the terminal.

=head3 ARGUMENTS

=over 4

=item * C<$name> - the container.

=item * C<$lines> - optional.  How many lines.  Default 200.

=back

=head3 RETURNS

The exit status of C<docker logs>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        name  => { type => 'string', min => 1 },
        lines => { type => 'integer', min => 0, optional => 1, default => 200 },
    }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.

=head2 container_log_text

    my $text = $docker->container_log_text('db', 10);

Returns the last lines a container printed, with its error output included,
as text.  Use it to put the reason a service failed into an error message.
Nothing is printed.

=head3 ARGUMENTS

=over 4

=item * C<$name> - the container.

=item * C<$lines> - optional.  How many lines.  Default 10.

=back

=head3 RETURNS

The text.  The empty string in a dry run or if Docker says nothing.

=head3 API SPECIFICATION

=head4 INPUT

    {
        name  => { type => 'string', min => 1 },
        lines => { type => 'integer', min => 0, optional => 1, default => 10 },
    }

=head4 OUTPUT

    { type => 'string' }

=head3 MESSAGES

None.

=head2 container_exit_code

    my $status = $docker->container_exit_code('job1');

Returns the status a container exited with.

=head3 RETURNS

The status, or C<undef> when Docker cannot say, for example because the
container was already removed.  0 in a dry run.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', optional => 1 }

=head3 MESSAGES

None.

=head2 container_status

    my $state = $docker->container_status('db');

Returns the container's state as Docker says it, for example C<running>,
C<restarting>, C<exited> or C<dead>.

=head3 RETURNS

The state, or C<undef> when Docker cannot say.  C<running> in a dry run.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'string', min => 1, optional => 1 }

=head3 MESSAGES

None.

=head2 container_restart_count

    my $count = $docker->container_restart_count('db');

Returns how many times Docker has restarted the container because of its
restart policy.  A container that is crashing again and again can look
"running" between restarts; a count above 0 shows the problem.

=head3 RETURNS

The count, or C<undef> when Docker cannot say.  0 in a dry run.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, optional => 1 }

=head3 MESSAGES

None.

=head2 container_remove

    my $status = $docker->container_remove('job1');

Stops and removes a container (C<docker rm -f>).

=head3 RETURNS

The exit status: 0 on success.  0 in a dry run.

=head3 SIDE EFFECTS

Runs the command with its output hidden.

=head3 API SPECIFICATION

=head4 INPUT

    { name => { type => 'string', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.

=head2 run

    my $status = $docker->run(@arguments);

Runs any Docker command.  Its output is shown on the terminal as it
happens.

=head3 ARGUMENTS

=over 4

=item * C<@arguments> - everything after C<docker>.  Strings, and
L<App::Actions::Docker::Variable> objects after C<-e>.

=back

=head3 RETURNS

The exit status.  A command killed by a signal gives 128 plus the signal
number, as a shell does.  0 in a dry run.

=head3 SIDE EFFECTS

Prints the command first if C<verbose> or C<dry_run> (secrets redacted).
Sets the hidden job variables in C<%ENV> while the command runs.

=head3 EXAMPLE

    my $status = $docker->run('image', 'prune', '-f');

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.  Check the status.

=head2 run_silent

    my $status = $docker->run_silent(@arguments);

Like L</run>, but the command's output and error output are thrown away.

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

None.

=head2 capture

    my ($output, $status) = $docker->capture(@arguments);

Runs a Docker command and returns what it printed.  Its error output still
goes to the terminal.

=head3 RETURNS

A list of two values: the output (Windows line ends C<\r\n> become C<\n>),
and the exit status.  In a dry run, C<('', 0)>.

=head3 SIDE EFFECTS

As for L</run>.

=head3 EXAMPLE

    my ($names) = $docker->capture('ps', '--format', '{{.Names}}');
    my @running = split /\n/, $names;

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'array', min => 2, max => 2 }    # (string, integer)

=head3 MESSAGES

None.

=head2 capture_silent

    my ($output, $status) = $docker->capture_silent(@arguments);

Like L</capture>, but the error output is thrown away.

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'array', min => 2, max => 2 }    # (string, integer)

=head3 MESSAGES

None.

=head2 capture_merged

    my ($output, $status) = $docker->capture_merged(@arguments);

Like L</capture>, but the error output is included in the returned text, in
the order the command wrote it (like the shell's C<2E<gt>&1>).

=head3 API SPECIFICATION

=head4 INPUT

    { args => { type => 'array', min => 1 } }

=head4 OUTPUT

    { type => 'array', min => 2, max => 2 }    # (string, integer)

=head3 MESSAGES

None.

=head2 redact

    my $safe = $docker->redact($text);

Replaces every known secret value in a text with C<***>.

=head3 ARGUMENTS

=over 4

=item * C<$text> - any text, or C<undef>.

=back

=head3 RETURNS

The text with the secrets replaced.  C<undef> stays C<undef>.  When one
secret contains another, the longer one is replaced first, so no part of it
is left.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my $docker = App::Actions::Docker->new(secrets => { PASS => 'hunter2' });
    print $docker->redact('login with hunter2');    # login with ***

=head3 API SPECIFICATION

=head4 INPUT

    { text => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'string', optional => 1 }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Most methods return a status; they do not die.>  Only L</check>,
L</pull> and L</pull_many> (with no images) throw exceptions.  Always look at
the returned status of L</run>, L</container_exec> and the others.

=item * B<A dry run answers "yes".>  In a dry run, L</image_exists> and
L</container_running> return 1, statuses are 0, and L</image_size> is
C<undef>.  Do not use a dry run to learn about the real computer.

=item * B<capture returns a list.>  C<my $output = $docker-E<gt>capture(...)>
gives you the I<status> (the last element), not the output.  Write C<my
($output, $status) = ...>.

=item * B<Redaction works on whole values.>  A secret is hidden only where
its complete value appears.  If a command prints the secret encoded (for
example in base64) or split, it is not hidden.  An empty secret is never
redacted.

=item * B<Plain C<NAME=VALUE> strings are not hidden.>  Only
L<App::Actions::Docker::Variable> objects are kept off the command line.

=item * B<Variables named like Docker's own stay visible.>  A job variable
called C<DOCKER_TOKEN> or C<HOME> is passed on the command line.  See
L</Job variables>.

=item * B<A secret must be given to L</new> to be redacted.>  Values the
object was not told about are printed as they are.

=back

=head1 ENCODING

Arguments are passed to Docker as bytes.  Pass ASCII, or text you have
already encoded (for example with C<Encode::encode('UTF-8', $text)>):
non-ASCII characters and emoji then work in image names, commands and
variable values as far as Docker itself allows them.  Captured output is
returned as bytes, as Docker printed it; decode it yourself if you need
characters.  A value with a NUL character cannot be passed in an environment,
so such a variable stays on the command line.

=head1 LIMITATIONS

=over 4

=item * Variables kept on the command line, as listed under
L</Job variables>, can be read there by other users of the host.

=item * Only job variables are hidden.  A secret in a docker action's
C<args>, or in a C<-e NAME=VALUE> written in a workflow's container
C<options>, is an ordinary argument and stays visible.

=item * The daemon keeps each container's environment, and anyone who can
reach it (members of the C<docker> group, for example) can read it with
C<docker inspect>.

=item * Captured output is read into memory, so a command that prints a lot
uses a lot of memory.

=back

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞDocker> means the routine changes
nothing in the object.  The lines below the rule are always true when the
routine returns.

    [ARG, TEXT, STATUS == ℕ]
    exec : seq ARG → TEXT × STATUS          the command's output and status
    printed : seq TEXT                       what this module has printed

    ┌─ Docker ──────────────────────────────────────────
    │ bin           : seq CHAR
    │ dry_run, explain, verbose, quiet : 𝔹
    │ platform      : optional seq CHAR
    │ secret_names  : ℙ NAME
    │ secret_values : ℙ seq CHAR
    ├───────────────────────────────────────────────────
    │ ⟨⟩ ∉ secret_values
    └───────────────────────────────────────────────────

    ┌─ Announce ────────────────────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ go!   : 𝔹
    ├───────────────────────────────────────────────────
    │ dry_run ∧ ¬quiet ∧ ¬explain ⇒ printed' = printed ⁀ ⟨"[dry-run] " ⁀ display(args?)⟩
    │ ¬dry_run ∧ verbose ∧ ¬quiet ⇒ printed' = printed ⁀ ⟨"+ " ⁀ display(args?)⟩
    │ go! ⇔ ¬dry_run
    │ ∀ s ∈ secret_values • s not in display(args?)
    └───────────────────────────────────────────────────

    hide(args) = (argv, env) where each Variable(n, v) that is hideable
    becomes n in argv and n ↦ v in env, and every other value is itself.

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Docker'
    │ options? : NAME ⇸ VALUE
    ├───────────────────────────────────────────────────
    │ bin' = first non-empty of ⟨options?.bin, ENV.DOCKER, "docker"⟩
    │ dry_run' = bool(options?.dry_run)   (and so for explain, verbose, quiet)
    │ secret_names' = dom options?.secrets
    │ secret_values' = { v : ran options?.secrets | v ≠ ⊥ ∧ v ≠ ⟨⟩ }
    └───────────────────────────────────────────────────

=head2 bin

    ┌─ Bin ─────────────────────────────────────────────
    │ ΞDocker
    │ r! : seq CHAR
    ├───────────────────────────────────────────────────
    │ r! = bin
    └───────────────────────────────────────────────────

=head2 dry_run

    ┌─ DryRun ──────────────────────────────────────────
    │ ΞDocker
    │ r! : {0, 1}
    ├───────────────────────────────────────────────────
    │ r! = 1 ⇔ dry_run
    └───────────────────────────────────────────────────

=head2 explain

    ┌─ Explain ─────────────────────────────────────────
    │ ΞDocker
    │ r! : {0, 1}
    ├───────────────────────────────────────────────────
    │ r! = 1 ⇔ explain
    └───────────────────────────────────────────────────

=head2 verbose

    ┌─ Verbose ─────────────────────────────────────────
    │ ΞDocker
    │ r! : {0, 1}
    ├───────────────────────────────────────────────────
    │ r! = 1 ⇔ verbose
    └───────────────────────────────────────────────────

=head2 quiet

    ┌─ Quiet ───────────────────────────────────────────
    │ ΞDocker
    │ r! : {0, 1}
    ├───────────────────────────────────────────────────
    │ r! = 1 ⇔ quiet
    └───────────────────────────────────────────────────

=head2 platform_args

    ┌─ PlatformArgs ────────────────────────────────────
    │ ΞDocker
    │ r! : seq ARG
    ├───────────────────────────────────────────────────
    │ platform ≠ ⊥ ∧ platform ≠ ⟨⟩ ⇒ r! = ⟨"--platform", platform⟩
    │ otherwise r! = ⟨⟩
    └───────────────────────────────────────────────────

=head2 check

    ┌─ Check ───────────────────────────────────────────
    │ ΞDocker
    │ r! : {1}
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = 1
    │ ¬dry_run ∧ second(exec(⟨"--version"⟩)) ≠ 0 ⇒ raises NotUsable(bin)
    │ ¬dry_run ∧ second(exec(⟨"info", ...⟩)) ≠ 0 ⇒ raises NoDaemon
    │ otherwise r! = 1
    └───────────────────────────────────────────────────

=head2 image_exists

    ┌─ ImageExists ─────────────────────────────────────
    │ ΞDocker
    │ image? : seq CHAR
    │ r!     : {0, 1}
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = 1
    │ ¬dry_run ⇒ (r! = 1 ⇔ second(exec(⟨"image", "inspect", ..., image?⟩)) = 0)
    └───────────────────────────────────────────────────

=head2 image_size

    ┌─ ImageSize ───────────────────────────────────────
    │ ΞDocker
    │ image? : seq CHAR
    │ r!     : optional ℕ
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = ⊥
    │ (out, s) = exec(⟨"image", "inspect", "--format", "{{.Size}}", image?⟩)
    │ ¬dry_run ∧ s = 0 ∧ strip(out) ∈ DIGITS⁺ ⇒ r! = number(strip(out))
    │ otherwise r! = ⊥
    └───────────────────────────────────────────────────

=head2 pull

    ┌─ Pull ────────────────────────────────────────────
    │ ΞDocker
    │ image? : seq CHAR
    │ r!     : {1}
    ├───────────────────────────────────────────────────
    │ s = Run(⟨"pull"⟩ ⁀ platform_args ⁀ ⟨image?⟩)
    │ s = 0 ⇒ r! = 1
    │ s ≠ 0 ⇒ raises PullFailed(image?, s)
    └───────────────────────────────────────────────────

=head2 pull_many

    ┌─ PullMany ────────────────────────────────────────
    │ ΞDocker
    │ images?      : seq₁ seq CHAR
    │ concurrency? : ℕ₁
    │ r!           : seq CHAR ⇸ STATUS
    ├───────────────────────────────────────────────────
    │ images? = ⟨⟩ ⇒ raises NoImages
    │ dom r! = ran images?
    │ dry_run ⇒ ∀ i ∈ ran images? • r!(i) = 0
    │ ¬dry_run ⇒ ∀ i ∈ ran images? • r!(i) = second(exec(⟨"pull"⟩ ⁀ platform_args ⁀ ⟨i⟩))
    │ at most concurrency? pulls run at the same time
    └───────────────────────────────────────────────────

=head2 image_remove

    ┌─ ImageRemove ─────────────────────────────────────
    │ ΞDocker
    │ image? : seq CHAR
    │ r!     : STATUS
    ├───────────────────────────────────────────────────
    │ r! = RunSilent(⟨"image", "rm", "-f", image?⟩)
    └───────────────────────────────────────────────────

=head2 network_create

    ┌─ NetworkCreate ───────────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ r! = RunSilent(⟨"network", "create", name?⟩)
    └───────────────────────────────────────────────────

=head2 network_remove

    ┌─ NetworkRemove ───────────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ r! = RunSilent(⟨"network", "rm", name?⟩)
    └───────────────────────────────────────────────────

=head2 container_start

    ┌─ ContainerStart ──────────────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ r! = RunSilent(⟨"run", "-d"⟩ ⁀ args?)
    └───────────────────────────────────────────────────

=head2 container_start_captured

    ┌─ ContainerStartCaptured ──────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ r!    : TEXT × STATUS
    ├───────────────────────────────────────────────────
    │ r! = CaptureMerged(⟨"run", "-d"⟩ ⁀ args?)
    │ first(r!) ≠ ⊥
    └───────────────────────────────────────────────────

=head2 container_exec

    ┌─ ContainerExec ───────────────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ r! = Run(⟨"exec"⟩ ⁀ args?)
    └───────────────────────────────────────────────────

=head2 container_running

    ┌─ ContainerRunning ────────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : {0, 1}
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = 1
    │ (out, s) = exec(⟨"inspect", "--format", "{{.State.Running}}", name?⟩)
    │ ¬dry_run ⇒ (r! = 1 ⇔ s = 0 ∧ "true" in out)
    └───────────────────────────────────────────────────

=head2 container_logs

    ┌─ ContainerLogs ───────────────────────────────────
    │ ΞDocker
    │ name?  : seq CHAR
    │ lines? : optional ℕ
    │ r!     : STATUS
    ├───────────────────────────────────────────────────
    │ r! = Run(⟨"logs", "--tail", if lines? = ⊥ then 200 else lines?, name?⟩)
    └───────────────────────────────────────────────────

=head2 container_log_text

    ┌─ ContainerLogText ────────────────────────────────
    │ ΞDocker
    │ name?  : seq CHAR
    │ lines? : optional ℕ
    │ r!     : TEXT
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = ⟨⟩
    │ ¬dry_run ⇒ r! = first(CaptureMerged(⟨"logs", "--tail", n, name?⟩))
    │     where n = if lines? = ⊥ then 10 else lines?
    └───────────────────────────────────────────────────

=head2 container_exit_code

    ┌─ ContainerExitCode ───────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : optional ℤ
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = 0
    │ ¬dry_run ∧ field(name?, ".State.ExitCode") ∈ INTEGER ⇒ r! = that number
    │ otherwise r! = ⊥
    └───────────────────────────────────────────────────

=head2 container_status

    ┌─ ContainerStatus ─────────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : optional seq₁ CHAR
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = "running"
    │ ¬dry_run ∧ field(name?, ".State.Status") = f ∧ f ≠ ⟨⟩ ⇒ r! = f
    │ otherwise r! = ⊥
    └───────────────────────────────────────────────────

=head2 container_restart_count

    ┌─ ContainerRestartCount ───────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : optional ℕ
    ├───────────────────────────────────────────────────
    │ dry_run ⇒ r! = 0
    │ ¬dry_run ∧ field(name?, ".RestartCount") ∈ DIGITS⁺ ⇒ r! = that number
    │ otherwise r! = ⊥
    └───────────────────────────────────────────────────

=head2 container_remove

    ┌─ ContainerRemove ─────────────────────────────────
    │ ΞDocker
    │ name? : seq CHAR
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ r! = RunSilent(⟨"rm", "-f", name?⟩)
    └───────────────────────────────────────────────────

=head2 run

    ┌─ Run ─────────────────────────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ r!    : STATUS
    ├───────────────────────────────────────────────────
    │ Announce(args?)
    │ ¬go! ⇒ r! = 0
    │ go! ∧ hide(args?) = (argv, env) ⇒
    │     r! = second(exec(⟨bin⟩ ⁀ argv)) with ENV ⊕ env during the call
    │     ∧ ENV' = ENV
    │ the output goes to the caller's terminal
    └───────────────────────────────────────────────────

=head2 run_silent

    ┌─ RunSilent ───────────────────────────────────────
    │ Run
    ├───────────────────────────────────────────────────
    │ the output and error output are discarded
    └───────────────────────────────────────────────────

=head2 capture

    ┌─ Capture ─────────────────────────────────────────
    │ ΞDocker
    │ args? : seq ARG
    │ r!    : TEXT × STATUS
    ├───────────────────────────────────────────────────
    │ Announce(args?)
    │ ¬go! ⇒ r! = (⟨⟩, 0)
    │ go! ⇒ r! = (crlf_to_lf(out), s) where (out, s) = exec(⟨bin⟩ ⁀ argv)
    │ the error output goes to the caller's terminal
    └───────────────────────────────────────────────────

=head2 capture_silent

    ┌─ CaptureSilent ───────────────────────────────────
    │ Capture
    ├───────────────────────────────────────────────────
    │ the error output is discarded
    └───────────────────────────────────────────────────

=head2 capture_merged

    ┌─ CaptureMerged ───────────────────────────────────
    │ Capture
    ├───────────────────────────────────────────────────
    │ first(r!) holds the output and the error output, in the order written
    └───────────────────────────────────────────────────

=head2 redact

    ┌─ Redact ──────────────────────────────────────────
    │ ΞDocker
    │ text? : optional TEXT
    │ r!    : optional TEXT
    ├───────────────────────────────────────────────────
    │ text? = ⊥ ⇒ r! = ⊥
    │ text? ≠ ⊥ ⇒ r! = text? with each s ∈ secret_values replaced by "***",
    │     longest s first
    │ ∀ s ∈ secret_values • s not in r!  (unless "***" itself forms one)
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object's settings never change after L</new>.  What changes is the
state of each command it runs:

                      new(%options)
                           |
                           v
                   +---------------+
                   |     READY     |<-------------------------------+
                   +---------------+                                |
                           |                                        |
                           | run / run_silent / capture* /           |
                           | container_* / image_* / network_* /     |
                           | pull / check                            |
                           v                                        |
                   +---------------+                                |
                   |  ANNOUNCING   |  verbose: print "+ cmd"        |
                   |               |  dry run: print "[dry-run] cmd"|
                   +---------------+  (secrets shown as ***)        |
                     |           |                                  |
            dry_run  |           | not dry_run                      |
                     v           v                                  |
          +-------------+  +------------------+                     |
          | SKIPPED     |  | HIDING VARIABLES |  Variable objects   |
          | returns the |  +------------------+  -> "-e NAME";      |
          | success     |           |            values -> %ENV     |
          | answer      |           v                               |
          +-------------+  +------------------+                     |
                 |         |     RUNNING      |  docker client runs,|
                 |         +------------------+  no shell           |
                 |                  |                               |
                 |                  | client exits                  |
                 |                  v                               |
                 |         +------------------+  %ENV restored;     |
                 |         |     FINISHED     |  status (and output)|
                 |         +------------------+  returned           |
                 |              |         |                          |
                 +--------------+         | check / pull fail        |
                        |                 v                          |
                        |        +------------------+                |
                        |        |  ERROR (thrown)  |                |
                        |        +------------------+                |
                        +--------------------------------------------+

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
