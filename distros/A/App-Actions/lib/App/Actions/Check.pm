package App::Actions::Check;

use strict;
use warnings;
use Carp qw(croak);
use Config;
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Scalar::Util qw(blessed);

use App::Actions::Docker;
use App::Actions::Schema;

our $VERSION = '0.002.0';

# The shape of the JSON document this module prints.  Bump it whenever a key,
# a value type or an enum changes, and update the schema below and the examples
# in t/fixtures/ with it; a CI job asserts the number rather than discovering
# a changed shape at the point where its assertion fails for another reason.
#
# 2: docker.bin stopped being nullable.  It is always the resolved command, so
# the null type promised a shape no document can produce; t/schema.t requires
# every enum value and null variant to appear in the examples, which is what
# found it.
our $JSON_SCHEMA_VERSION = 2;

# The schema of the document check --json prints, so that the installed
# action-run can hand the contract to a caller instead of leaving it in the
# tests.  A change to the document belongs here, in $JSON_SCHEMA_VERSION and
# in the examples in t/fixtures/, which t/schema.t holds against this and
# fails when a key it names appears in none of them.
my $JSON_SCHEMA = <<'JSON';
{
  "title": "action-run check --json",
  "description": "The document action-run check --json prints.  Objects reject keys this file does not name, so a new key is a schema change.",
  "version": 2,
  "type": "object",
  "properties": {
    "schema_version": {
      "description": "The version of this shape; App::Actions::Check->json_schema_version returns it.",
      "type": "integer",
      "const": 2
    },
    "ready": {
      "description": "True only when every check passed.",
      "type": "boolean"
    },
    "problems": {
      "description": "How many problems were found.",
      "type": "integer"
    },
    "host": {
      "type": "object",
      "properties": {
        "os": { "type": "string" },
        "name": { "type": "string" },
        "perl": { "type": "string" },
        "archname": { "type": "string" }
      },
      "required": [ "os", "name", "perl", "archname" ]
    },
    "docker": {
      "type": "object",
      "properties": {
        "bin": { "type": "string" },
        "client": { "type": [ "string", "null" ] },
        "daemon": { "type": [ "string", "null" ] },
        "containers": { "type": [ "string", "null" ] }
      },
      "required": [ "bin", "client", "daemon", "containers" ]
    },
    "image": {
      "description": "The probe image, or null when no container was run.",
      "type": [ "string", "null" ]
    },
    "mounts": {
      "type": "array",
      "items": {
        "oneOf": [
          {
            "description": "The temporary directory the probe reads back from.",
            "type": "object",
            "properties": {
              "host": { "type": "string" },
              "container": { "type": "string" },
              "ok": { "type": "boolean" }
            },
            "required": [ "host", "container", "ok" ]
          },
          {
            "description": "The project directory, whose entry count is compared with the host's.",
            "type": "object",
            "properties": {
              "host": { "type": "string" },
              "container": { "type": "string" },
              "entries": { "type": [ "integer", "null" ] },
              "expected": { "type": [ "integer", "null" ] },
              "ok": { "type": "boolean" }
            },
            "required": [ "host", "container", "entries", "expected", "ok" ]
          }
        ]
      }
    },
    "issues": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "problem": { "type": "string" },
          "remedies": {
            "type": "array",
            "items": { "type": "string" }
          }
        },
        "required": [ "problem", "remedies" ]
      }
    }
  },
  "required": [
    "schema_version",
    "ready",
    "problems",
    "host",
    "docker",
    "image",
    "mounts",
    "issues"
  ]
}
JSON

sub json_schema {
    return JSON::PP->new->decode($JSON_SCHEMA);
}


my %PLATFORM_NAME = (
    linux   => 'Linux',
    darwin  => 'macOS',
    MSWin32 => 'Windows',
    cygwin  => 'Cygwin',
    msys    => 'MSYS',
);

sub new {
    my ($class, %args) = @_;

    my $image = defined $args{image} && length $args{image}
        ? $args{image}
        : 'alpine:3.20';

    return bless {
        docker_bin => $args{docker_bin},
        image      => $image,
        platform   => $args{platform},
        directory  => $args{directory},
        # The platform decides the wording of the remedies, so it is a value
        # rather than a call to $^O buried in the messages.
        os         => defined $args{os} && length $args{os} ? $args{os} : $^O,
        output     => $args{output} || \*STDOUT,
        # A caller that prints its own heading and verdict, such as the smoke
        # test, can ask for the report without them.
        title      => exists $args{title} ? $args{title} : 'action-run check',
        summary    => exists $args{summary} && !$args{summary} ? 0 : 1,
        # A caller that probes before a workflow wants silence when all is
        # well, and the whole report when it is not.
        quiet      => $args{quiet} ? 1 : 0,
        # A machine-readable report instead of the text one, for CI.
        json       => $args{json} ? 1 : 0,
        # The text report names the schema the JSON document is written
        # against, so a pasted report says which contract it came from.  A
        # caller whose own report is not that document - the preflight, which
        # has a document of its own, and the smoke test, which prints none -
        # turns the line off.
        schema_line => exists $args{schema_line} && !$args{schema_line} ? 0 : 1,
        problems   => 0,
        data       => { mounts => [], issues => [] },
    }, $class;
}

sub image { return $_[0]->{image} }

sub json_schema_version { return $JSON_SCHEMA_VERSION }

# Report the host, the Docker daemon and a real bind mount.  Returns 0 when
# every check passed and 2 when something needs fixing, matching the exit
# codes of the rest of the command line tool.
sub run {
    my ($self) = @_;

    # The report is built in a buffer so that a quiet run can drop it when
    # every check passed, without the checks themselves knowing.
    # local puts the caller's handle back however the checks end, so one
    # that dies cannot leave the object writing into a buffer nobody reads.
    my $target = $self->{output};
    my $report = '';
    open my $buffer, '>', \$report or croak "Unable to buffer the check report: $!";

    my $exit = do {
        local $self->{output} = $buffer;
        $self->_run_checks;
    };
    close $buffer;

    # The JSON report replaces the text one rather than joining it, so that
    # its output can be piped straight into jq or a CI assertion.
    if ($self->{json}) {
        print {$target} $self->_json_report($exit), "\n";
        return $exit;
    }

    print {$target} $report if $self->{problems} || !$self->{quiet};

    return $exit;
}

sub _run_checks {
    my ($self) = @_;

    $self->{problems} = 0;
    $self->{data} = { mounts => [], issues => [] };
    my $out = $self->{output};

    print {$out} "$self->{title}\n" if defined $self->{title} && length $self->{title};
    print {$out} '  host      ', $self->_host_description, "\n";

    $self->{data}{host} = $self->host_info;

    my $docker = App::Actions::Docker->new(
        bin      => $self->{docker_bin},
        platform => $self->{platform},
        quiet    => 1,
    );
    $self->{data}{docker} = { bin => $docker->bin };
    print {$out} '  docker    ', $docker->bin, "\n";

    if ($self->_check_daemon($docker)) {
        $self->_check_mounts($docker);
    }

    # The version comes before the verdict, so a report pasted into an issue
    # says which contract the lines above were written against.
    if ($self->{schema_line}) {
        print {$out} '  schema    version ', $JSON_SCHEMA_VERSION,
            " (action-run schema check)\n";
    }

    if ($self->{problems}) {
        if ($self->{summary}) {
            my $plural = $self->{problems} == 1 ? '' : 's';
            print {$out} "Result: not ready ($self->{problems} problem$plural)\n";
        }
        return 2;
    }

    print {$out} "Result: ready\n" if $self->{summary};
    return 0;
}

# The host part of the report.  It is local knowledge rather than probe
# knowledge, so a caller that skips the checks (a preflight with --skip-check)
# can still report a host instead of an empty object the schema would reject.
sub host_info {
    my ($invocant, $os) = @_;

    # An object is blessed, so ref() names its class, not HASH.
    $os = $invocant->{os} if !(defined $os && length $os) && blessed $invocant;
    $os = $^O unless defined $os && length $os;

    return {
        os       => $os,
        name     => $PLATFORM_NAME{$os} || $os,
        perl     => sprintf('%vd', $^V),
        archname => $Config{archname},
    };
}

sub _host_description {
    my $os = $_[0]->{os};
    my $name = $PLATFORM_NAME{$os} || $os;

    return sprintf '%s (%s), perl %vd, %s', $name, $os, $^V, $Config{archname};
}

sub _check_daemon {
    my ($self, $docker) = @_;

    my ($client, $client_rc) = $docker->capture_silent(
        'version', '--format', '{{.Client.Version}}',
    );
    if ($client_rc != 0 || !length _trim($client)) {
        $self->_problem(
            "the Docker command '$docker->{bin}' could not be run",
            $self->_is_windows()
                ? 'install Docker Desktop, or pass --docker with the full path to docker.exe'
                : 'install Docker, or pass --docker with the full path to the docker executable',
        );
        return 0;
    }
    $self->{data}{docker}{client} = _trim($client);
    print {$self->{output}} '  client    ', _trim($client), "\n";

    my ($server, $server_rc) = $docker->capture_silent(
        'version', '--format', '{{.Server.Version}}',
    );
    if ($server_rc != 0 || !length _trim($server)) {
        my @remedies = $self->_is_windows()
            ? (   'start Docker Desktop and wait until it is running, then try again',
                  'if the engine will not start, run "wsl --shutdown" and start Docker Desktop again',
              )
            : (   'start the Docker daemon, for example "sudo systemctl start docker"',
                  'or point DOCKER_HOST at a daemon that is already running',
              );
        $self->_problem(
            'the daemon is not reachable; is Docker running and can this user access it?',
            @remedies,
        );
        return 0;
    }

    my ($ostype, $ostype_rc) = $docker->capture_silent(
        'info', '--format', '{{.OSType}}',
    );
    my $containers = $ostype_rc == 0 && length _trim($ostype)
        ? lc _trim($ostype)
        : 'unknown';

    $self->{data}{docker}{daemon}     = _trim($server);
    $self->{data}{docker}{containers} = $containers;
    print {$self->{output}} '  daemon    ', _trim($server), ", $containers containers\n";

    if ($containers ne 'linux') {
        $self->_problem(
            "the daemon runs '$containers' containers; action-run needs Linux containers",
            $self->_is_windows()
                ? 'right-click the Docker Desktop tray icon and choose "Switch to Linux containers"'
                : 'point DOCKER_HOST at a daemon that runs Linux containers',
        );
        return 0;
    }

    return 1;
}

# Mount a temporary directory and, when asked, the project directory, then
# read a token back from inside a container.  A bind mount that silently maps
# something else fails this, which is what happens on Windows when Docker
# Desktop does not share the drive.
sub _check_mounts {
    my ($self, $docker) = @_;

    my $temp = File::Temp->newdir('action-run-check-XXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $token = join '-', time, $$;
    my $marker = File::Spec->catfile("$temp", 'marker');
    open my $handle, '>', $marker
        or return $self->_problem(
            "cannot write '$marker': $!",
            'check the permissions of the temporary directory, or set TMPDIR',
        );
    binmode $handle;
    print {$handle} $token;
    close $handle;

    my @mounts = ("$temp:/action-run-check");
    my $project;
    if (defined $self->{directory}) {
        $project = File::Spec->rel2abs($self->{directory});
        if (!-d $project) {
            return $self->_problem(
                "'$project' is not a directory",
                'pass a directory that exists, or leave the argument out',
            );
        }
        push @mounts, "$project:/check-project:ro";
    }

    my $command = 'cat /action-run-check/marker; echo; ';
    $command .= defined $project ? 'ls -A /check-project | wc -l' : 'echo 0';

    my @args = ('run', '--rm', '--network', 'none');
    push @args, $docker->platform_args;
    push @args, '-v', $_ for @mounts;
    push @args, $self->{image}, 'sh', '-c', $command;

    $self->{data}{image} = $self->{image};
    print {$self->{output}} '  image     ', $self->{image}, "\n";

    my ($output, $rc) = $docker->capture(@args);
    if ($rc != 0) {
        return $self->_problem(
            "the probe container failed (exit $rc)",
            "run \"docker pull $self->{image}\" by hand to see the error",
            'on an ARM host add --platform linux/amd64 for x86-only images',
        );
    }

    my ($returned) = split /\n/, defined $output ? $output : '', 2;
    if (!defined $returned || _trim($returned) ne $token) {
        return $self->_problem(
            'the container could not read the mounted temporary directory',
            $self->_is_windows()
                ? 'share the drive that holds the temporary directory in Docker Desktop > Settings > Resources > File sharing'
                : 'a bind mount needs a local daemon; a remote DOCKER_HOST cannot see this machine\'s paths',
        );
    }
    push @{ $self->{data}{mounts} }, {
        host      => "$temp",
        container => '/action-run-check',
        ok        => JSON::PP::true(),
    };
    print {$self->{output}} "  mount     $temp -> /action-run-check: OK\n";

    return 1 unless defined $project;

    my (undef, $seen) = split /\n/, defined $output ? $output : '';
    $seen = _trim($seen);
    my $expected = _entry_count($project);
    my $manifest = {
        host      => $project,
        container => '/check-project',
        entries   => defined $seen && $seen =~ /\A\d+\z/ ? $seen + 0 : undef,
        expected  => $expected,
        ok        => JSON::PP::false(),
    };
    push @{ $self->{data}{mounts} }, $manifest;

    if (!defined $seen || $seen !~ /\A\d+\z/) {
        return $self->_problem("could not count the entries in '$project'");
    }
    if (!defined $expected || $seen != $expected) {
        my $host = defined $expected ? $expected : 'unknown';
        return $self->_problem(
            "'$project' -> /check-project sees $seen entries, the host has $host",
            $self->_is_windows()
                ? "share the drive that holds '$project' in Docker Desktop > Settings > Resources > File sharing"
                : 'choose a directory the daemon can see, or point DOCKER_HOST at a local daemon',
        );
    }

    $manifest->{ok} = JSON::PP::true();
    my $unit = $seen == 1 ? 'entry' : 'entries';
    print {$self->{output}}
        "  mount     $project -> /check-project: OK ($seen $unit)\n";

    return 1;
}

sub _entry_count {
    my ($directory) = @_;

    # An unreadable directory has no count, which is not the same as empty.
    my $count;
    if (opendir my $handle, $directory) {
        $count = grep { $_ ne '.' && $_ ne '..' } readdir $handle;
        closedir $handle;
    }

    return $count;
}

# Report a problem with the concrete step that fixes it.  A diagnosis without
# a remedy is only half a check: the reader is left to guess whether to start
# Docker, share a drive, or switch container types.
sub _problem {
    my ($self, $message, @remedies) = @_;

    print {$self->{output}} "  problem   $message\n";
    my @given;
    for my $remedy (@remedies) {
        next unless defined $remedy && length $remedy;
        print {$self->{output}} "  remedy    $remedy\n";
        push @given, $remedy;
    }
    $self->{problems}++;

    push @{ $self->{data}{issues} }, {
        problem  => $message,
        remedies => \@given,
    };

    return 0;
}

# The report as data, so that a caller can add to it (the preflight adds the
# images it prepared) or assert on it without parsing text.  The keys are
# stable and values that could not be discovered are null rather than absent.
# "ready" is a plain 0 or 1 here; the JSON encoder turns it into true or false.
sub summary {
    my ($self, $exit) = @_;

    my $data = $self->{data} || {};
    my $docker = $data->{docker} || {};

    return {
        schema_version => $JSON_SCHEMA_VERSION,
        ready    => $exit == 0 ? 1 : 0,
        problems => $self->{problems} + 0,
        host     => $data->{host} || {},
        docker   => {
            bin        => $docker->{bin},
            client     => $docker->{client},
            daemon     => $docker->{daemon},
            containers => $docker->{containers},
        },
        image    => $data->{image},
        mounts   => $data->{mounts} || [],
        issues   => $data->{issues} || [],
    };
}

# The machine-readable form of the report, for CI.  The document is held to
# its own schema before it is encoded, so a key that was added, removed or
# retyped without the schema changing stops the report here rather than in an
# assertion at the far end of a pipeline.
sub _json_report {
    my ($self, $exit) = @_;

    my $summary = $self->summary($exit);
    $summary->{ready} = $exit == 0 ? JSON::PP::true() : JSON::PP::false();

    App::Actions::Schema::assert_valid(
        $summary, $self->json_schema,
        'the action-run check --json document does not match App::Actions::Check->json_schema',
    );

    return JSON::PP->new->canonical->encode($summary);
}

sub _is_windows {
    my $os = $_[0]->{os};

    return $os eq 'MSWin32' || $os eq 'cygwin' || $os eq 'msys';
}

sub _trim {
    my ($value) = @_;

    my $trimmed = defined $value ? $value : '';
    $trimmed =~ s/^\s+//;
    $trimmed =~ s/\s+$//;

    return $trimmed;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Check - find out whether this computer can run workflows with Docker

=head1 SYNOPSIS

Check the computer and print a report (this is C<action-run check>):

    use App::Actions::Check;

    my $status = App::Actions::Check->new->run;    # 0 = ready, 2 = not ready
    exit $status;

Also check that Docker can see your project directory:

    my $check = App::Actions::Check->new(directory => '/home/me/src/project');
    exit $check->run;

Print a JSON report for a CI job (C<action-run check --json>):

    my $check = App::Actions::Check->new(json => 1);
    $check->run;    # prints one JSON object

Print nothing unless something is wrong:

    my $check = App::Actions::Check->new(quiet => 1);
    die "Docker is not ready\n" if $check->run;

Get the report as data, without printing it:

    open my $sink, '>', \my $ignored;
    my $check = App::Actions::Check->new(output => $sink);
    my $status = $check->run;
    my $report = $check->summary($status);
    print "Docker $report->{docker}{daemon}\n";

=head1 DESCRIPTION

Most failures to run a workflow locally have one of a few causes: Docker is
not installed, the Docker service is not running, it runs Windows containers
instead of Linux ones, or it cannot see the folders on this computer.  This
module checks each of these, in order, and stops at the first that fails:

=over 4

=item 1. B<The host.>  Which system and Perl this is.  This never fails.

=item 2. B<The Docker program.>  Can C<docker version> run?

=item 3. B<The Docker service (daemon).>  Does it answer?  Does it run
Linux containers?

=item 4. B<Folder sharing (bind mounts).>  It writes a file in a new
temporary folder, starts one small container (C<alpine:3.20> by default)
with that folder mounted, and reads the file back.  If you give a
C<directory>, it also mounts that folder read-only and compares the number
of entries seen inside the container with the number on the computer.  This
finds a drive that Docker Desktop does not share.

=back

Every problem is followed by one or more C<remedy> lines that say how to fix
it, in the words of the system the check runs on (for example Docker Desktop
settings on Windows, C<systemctl> on Linux).

A text report looks like this:

    action-run check
      host      Linux (linux), perl 5.40.0, x86_64-linux
      docker    docker
      client    29.0.1
      daemon    29.0.1, linux containers
      image     alpine:3.20
      mount     /tmp/action-run-check-AbC123 -> /action-run-check: OK
      schema    version 2 (action-run schema check)
    Result: ready

=head1 METHODS

=head2 new

    my $check = App::Actions::Check->new(%options);

Makes a check.  Nothing is checked yet.

=head3 ARGUMENTS

All are optional.

=over 4

=item * C<docker_bin> - the Docker program.  Default as in
L<App::Actions::Docker/new>.

=item * C<image> - the small image used for the folder test.  Default
C<alpine:3.20>.

=item * C<platform> - passed to Docker as C<--platform>, for example
C<linux/amd64> on an ARM computer.

=item * C<directory> - a folder to test as well, for example your project.

=item * C<output> - where to print.  A file handle.  Default C<STDOUT>.

=item * C<title> - the first line.  Default C<action-run check>.  An empty
string leaves it out.

=item * C<summary> - default true.  False leaves out the last C<Result:>
line, for a caller that prints its own.

=item * C<quiet> - true to print the text report only if there is a problem.

=item * C<json> - true to print one JSON object instead of the text report.
See L</JSON OUTPUT>.

=item * C<schema_line> - default true.  False leaves out the C<schema> line,
for a caller whose report is not this document.

=item * C<os> - the system whose remedies are printed, as in C<$^O>
(C<linux>, C<darwin>, C<MSWin32>, ...).  Default: this computer's.

=back

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my $check = App::Actions::Check->new(platform => 'linux/amd64', title => '');

=head3 API SPECIFICATION

=head4 INPUT

    {
        docker_bin  => { type => 'string', optional => 1 },
        image       => { type => 'string', optional => 1, default => 'alpine:3.20' },
        platform    => { type => 'string', optional => 1 },
        directory   => { type => 'string', optional => 1 },
        output      => { type => 'object', optional => 1 },
        title       => { type => 'string', optional => 1, default => 'action-run check' },
        summary     => { type => 'boolean', optional => 1, default => 1 },
        quiet       => { type => 'boolean', optional => 1 },
        json        => { type => 'boolean', optional => 1 },
        schema_line => { type => 'boolean', optional => 1, default => 1 },
        os          => { type => 'string', optional => 1 },
    }

=head4 OUTPUT

    { type => 'object', isa => 'App::Actions::Check' }

=head3 MESSAGES

None.

=head2 run

    my $status = $check->run;

Runs the checks and prints the report.

=head3 ARGUMENTS

None.

=head3 RETURNS

0 if everything is ready; 2 if there is a problem.  These are the exit
statuses C<action-run check> uses.

=head3 SIDE EFFECTS

Runs Docker commands; may download the probe image; starts and removes one
container with no network; creates and removes a temporary folder; prints
the report to C<output>.  Calling C<run> again starts a fresh report.

=head3 EXAMPLE

    if ($check->run != 0) {
        print STDERR "Fix the problems above, then try again.\n";
    }

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 0, 2 ] }

=head3 MESSAGES

Problems are printed, not thrown.  Each C<problem> line has its own
C<remedy> lines:

    +--------------------------------------------------+-----------------------------------------+
    | Problem                                          | Usual cause                             |
    +--------------------------------------------------+-----------------------------------------+
    | the Docker command 'BIN' could not be run        | Docker not installed, or not on PATH    |
    | the daemon is not reachable; is Docker running   | Docker not started, or no permission    |
    | and can this user access it?                     | (add the user to the docker group)      |
    | the daemon runs 'windows' containers; action-run | Docker Desktop in Windows mode          |
    | needs Linux containers                           |                                         |
    | cannot write 'FILE': ERR                         | temporary folder not writable           |
    | 'DIR' is not a directory                         | wrong "directory" option                |
    | the probe container failed (exit N)              | image cannot be pulled, or wrong        |
    |                                                  | platform                                |
    | the container could not read the mounted         | drive not shared, or a remote Docker    |
    | temporary directory                              | (DOCKER_HOST) that cannot see this disk |
    | could not count the entries in 'DIR'             | the probe printed something unexpected  |
    | 'DIR' -> /check-project sees N entries, the host | drive not shared; Docker sees an empty  |
    | has M                                            | or different folder                     |
    +--------------------------------------------------+-----------------------------------------+

Thrown:

    +----------------------------------------------+------------------------------------+------------------+
    | Exception                                    | Meaning                            | What to do       |
    +----------------------------------------------+------------------------------------+------------------+
    | App::Actions::Schema::Invalid: the           | (json only) a bug: the document    | report it; exit  |
    | action-run check --json document does not    | does not match its schema; nothing | status 70        |
    | match App::Actions::Check->json_schema: ...  | is printed                         |                  |
    | Unable to buffer the check report: ERR (die) | out of memory                      |                  |
    +----------------------------------------------+------------------------------------+------------------+

=head2 summary

    my $report = $check->summary($status);

Returns the last report as data instead of text.  Call it after L</run>.

=head3 ARGUMENTS

=over 4

=item * C<$status> - what L</run> returned.

=back

=head3 RETURNS

A hash reference with the keys described in L</JSON OUTPUT>.  Here C<ready>
is 1 or 0, not a JSON boolean; convert it before you encode it as JSON.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my $report = $check->summary($check->run);
    print "$_->{problem}\n" for @{ $report->{issues} };

=head3 API SPECIFICATION

=head4 INPUT

    { exit => { type => 'integer', memberof => [ 0, 2 ] } }

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.

=head2 host_info

    my $host = App::Actions::Check->host_info;
    my $host = $check->host_info;
    my $host = App::Actions::Check->host_info('MSWin32');

Describes this computer, without running any check.

=head3 ARGUMENTS

=over 4

=item * C<$os> - optional.  The system name to report.  Default: the
object's C<os>, or C<$^O>.

=back

=head3 RETURNS

A hash reference: C<os> (as in C<$^O>), C<name> (for people, such as
C<macOS>), C<perl> (the version, such as C<5.40.0>) and C<archname>.

=head3 SIDE EFFECTS

None.

=head3 API SPECIFICATION

=head4 INPUT

    { os => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.

=head2 image

    my $image = $check->image;

Returns the image used for the folder test.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 json_schema

    my $schema = App::Actions::Check->json_schema;

Returns the JSON schema of the C<check --json> document, as a hash
reference.  C<action-run schema check> prints the same schema.

=head3 ARGUMENTS

None.

=head3 RETURNS

A new hash reference each time, so you may change it.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.

=head2 json_schema_version

    my $version = App::Actions::Check->json_schema_version;

Returns the version of the JSON document's shape.  The document carries the
same number as C<schema_version>.  It goes up whenever the shape changes.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', min => 1 }

=head3 MESSAGES

None.

=head1 JSON OUTPUT

With C<json>, the report is one JSON object.  Every key is always there.  A
value that could not be found out is C<null>:

    {
      "schema_version": 2,
      "ready": true,
      "problems": 0,
      "host": { "os": "linux", "name": "Linux", "perl": "5.40.0", "archname": "x86_64-linux" },
      "docker": { "bin": "docker", "client": "29.0.1", "daemon": "29.0.1", "containers": "linux" },
      "image": "alpine:3.20",
      "mounts": [
        { "host": "/tmp/action-run-check-XXXX", "container": "/action-run-check", "ok": true },
        { "host": "/src/project", "container": "/check-project", "entries": 17, "expected": 17, "ok": true }
      ],
      "issues": [ { "problem": "...", "remedies": [ "..." ] } ]
    }

C<schema_version> is the number L</json_schema_version> returns.  The schema
itself is what C<action-run schema check> prints.  The examples in
F<t/fixtures/check.json>, F<check-unready.json>, F<check-unreachable.json>
and F<check-uncounted.json> show a ready computer, a folder mismatch, a
Docker that could not be run, and a folder whose entries could not be
counted.

Before the document is printed, it is checked against its schema.  If it
does not match (a bug), nothing is printed and an
L<App::Actions::Schema::Invalid> is thrown; C<action-run> then exits with
70.  The return value of L</run> is the same with or without C<json>.

=head1 COMMON PITFALLS

=over 4

=item * B<The check stops at the first failure.>  If Docker is not running,
the folder test is not tried.  Run the check again after each fix.

=item * B<It downloads an image.>  The first run pulls C<alpine:3.20> (a few
megabytes).  Without internet access, pass an C<image> you already have.

=item * B<The image needs C<sh>, C<cat>, C<ls> and C<wc>.>  A "distroless"
or "scratch" image will fail the probe.

=item * B<A remote Docker cannot see your files.>  With C<DOCKER_HOST>
pointing at another computer, the folder test fails.  That is a real
problem: workflows will not see your project either.

=item * B<C<summary> is only meaningful after C<run>.>  Before it, the
report is empty.

=item * B<In C<summary>, C<ready> is 0 or 1, not a JSON boolean.>

=item * B<C<quiet> does not silence C<json>.>  With C<json>, the document is
always printed.

=back

=head1 ENCODING

Folder names may contain any characters your system allows, including
non-ASCII and emoji; they are passed to Docker as bytes and reported as
bytes.  The text report itself is ASCII except for those names and for what
Docker prints.  The JSON report is UTF-8 encoded only if the input strings
are; decode folder names with your system's encoding if you need characters.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΔCheck> means the routine can change
the object.  The lines below the rule are always true when the routine
returns.

    [ISSUE, MOUNT]
    STAGE ::= host | program | daemon | linux | mounts | project
    passes : STAGE → 𝔹                   what the computer would answer

    ┌─ Check ───────────────────────────────────────────
    │ image    : seq₁ CHAR
    │ problems : ℕ
    │ issues   : seq ISSUE
    │ mounts   : seq MOUNT
    ├───────────────────────────────────────────────────
    │ problems = #issues
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Check'
    │ image? : optional seq CHAR
    ├───────────────────────────────────────────────────
    │ image' = if image? = ⊥ ∨ image? = ⟨⟩ then "alpine:3.20" else image?
    │ problems' = 0 ∧ issues' = ⟨⟩ ∧ mounts' = ⟨⟩
    └───────────────────────────────────────────────────

=head2 run

    ┌─ Run ─────────────────────────────────────────────
    │ ΔCheck
    │ r! : {0, 2}
    ├───────────────────────────────────────────────────
    │ order = ⟨program, daemon, linux, mounts, project⟩
    │ failed = first s in order with ¬passes(s), or ⊥
    │ failed = ⊥ ⇒ r! = 0 ∧ problems' = 0
    │ failed ≠ ⊥ ⇒ r! = 2 ∧ problems' = 1
    │ ∀ s after failed in order • s is not tried
    │ project is tried only when a directory was given
    └───────────────────────────────────────────────────

=head2 summary

    ┌─ Summary ─────────────────────────────────────────
    │ ΞCheck
    │ exit? : {0, 2}
    │ r!    : KEY ⇸ VALUE
    ├───────────────────────────────────────────────────
    │ r!.ready = (if exit? = 0 then 1 else 0)
    │ r!.problems = problems ∧ r!.issues = issues ∧ r!.mounts = mounts
    │ r!.schema_version = json_schema_version
    └───────────────────────────────────────────────────

=head2 host_info

    ┌─ HostInfo ────────────────────────────────────────
    │ os? : optional seq CHAR
    │ r!  : KEY ⇸ VALUE
    ├───────────────────────────────────────────────────
    │ r!.os = first non-empty of ⟨os?, self.os, $^O⟩
    │ r!.name = displayName(r!.os) if known, else r!.os
    │ dom r! = {os, name, perl, archname}
    └───────────────────────────────────────────────────

=head2 image

    ┌─ Image ───────────────────────────────────────────
    │ ΞCheck
    │ r! : seq₁ CHAR
    ├───────────────────────────────────────────────────
    │ r! = image
    └───────────────────────────────────────────────────

=head2 json_schema

    ┌─ JsonSchema ──────────────────────────────────────
    │ r! : SCHEMA
    ├───────────────────────────────────────────────────
    │ r! = decode(JSON_SCHEMA) ∧ r! is a new object
    └───────────────────────────────────────────────────

=head2 json_schema_version

    ┌─ JsonSchemaVersion ───────────────────────────────
    │ r! : ℕ₁
    ├───────────────────────────────────────────────────
    │ r! = JSON_SCHEMA_VERSION
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

L</run> moves through these states.  Any failed test records one problem
with its remedies and jumps to NOT READY:

     new(%options)
          |
          v
    +-----------+  run   +------------+       +----------------+  fails  +-----------+
    |  CREATED  |------->| HOST       |------>| DOCKER PROGRAM |-------->|           |
    +-----------+        | (always ok)|       | docker version |         |           |
          ^              +------------+       +----------------+         |           |
          |                                          | ok                |           |
          |                                          v                   |           |
          |                                   +----------------+  fails  |           |
          |                                   | DAEMON         |-------->|           |
          |                                   | server version |         |           |
          |                                   +----------------+         |           |
          |                                          | ok                |           |
          |                                          v                   |    NOT    |
          |                                   +----------------+  not    |   READY   |
          |                                   | LINUX          |  linux  |  status 2 |
          |                                   | CONTAINERS?    |-------->|           |
          |                                   +----------------+         |           |
          |                                          | yes               |           |
          |                                          v                   |           |
          |                                   +----------------+  fails  |           |
          |                                   | TEMP MOUNT     |-------->|           |
          |                                   | write, run,    |         |           |
          |                                   | read back      |         |           |
          |                                   +----------------+         |           |
          |                                          | ok                |           |
          |                          no directory    v                   |           |
          |                        +---------+---------------+  differ   |           |
          |                        |         | PROJECT MOUNT |---------->|           |
          |                        |         | count entries |           +-----------+
          |                        |         +---------------+                 |
          |                        v                 | same                     |
          |                  +-----------+           |                          |
          |                  |   READY   |<----------+                          |
          |                  |  status 0 |                                      |
          |                  +-----------+                                      |
          |                        |                                            |
          |                        +--------------------+-----------------------+
          |                                             v
          |                                  +---------------------+
          |                                  | REPORT              |  json: check against the
          |                                  | text, or JSON       |  schema, then print (or
          |                                  | (quiet: only if not |  throw Schema::Invalid)
          |                                  |  ready)             |
          |                                  +---------------------+
          |                                             |
          +---------------- run again ------------------+   summary($status) reads the report

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
