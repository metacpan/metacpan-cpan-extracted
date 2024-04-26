package DBIx::QuickDB::Driver;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak confess/;
use File::Path qw/remove_tree/;
use File::Temp qw/tempdir/;
use POSIX ":sys_wait_h";
use Scalar::Util qw/blessed/;
use Time::HiRes qw/sleep time/;

use DBIx::QuickDB::Util qw/clone_dir/;

use DBIx::QuickDB::Watcher;

use DBIx::QuickDB::Util::HashBase qw{
    -root_pid
    -dir
    -_cleanup
    -autostop -autostart
    verbose
    -_log_id
    username
    password
    env_vars
    <watcher
};

sub viable { (0, "viable() is not implemented for the " . $_[0]->name . " driver") }

sub socket         { confess "socket() is not implemented for the " . $_[0]->name . " driver" }
sub load_sql       { confess "load_sql() is not implemented for the " . $_[0]->name . " driver" }
sub bootstrap      { confess "bootstrap() is not implemented for the " . $_[0]->name . " driver" }
sub connect_string { confess "connect_string() is not implemented for the " . $_[0]->name . " driver" }
sub start_command  { confess "start_command() is not implemented for the " . $_[0]->name . " driver" }
sub shell_command  { confess "shell_command() is not implemented for the " . $_[0]->name . " driver" }

sub list_env_vars { qw/DBI_USER DBI_PASS DBI_DSN/ }

sub version_string { 'unknown' }

sub stop_sig { 'TERM' }

sub write_config {}

sub do_in_env {
    my $self = shift;
    my ($code) = @_;

    my $old = $self->mask_env_vars;

    my $ok = eval { $code->(); 1 };
    my $err = $@;

    $self->unmask_env_vars($old);

    die $err unless $ok;

    return;
}

sub mask_env_vars {
    my $self = shift;

    my %old;

    for my $var ($self->list_env_vars) {
        next unless defined $ENV{$var};
        $old{$var} = delete $ENV{$var};
    }

    my $env_vars = $self->env_vars || {};
    for my $var (keys %$env_vars) {
        $old{$var} = delete $ENV{$var} unless defined $old{$var};
        $ENV{$var} = $env_vars->{$var};
    }

    return \%old;
}

sub unmask_env_vars {
    my $self = shift;
    my ($old) = @_;

    for my $var (keys %$old) {
        my $val = $old->{$var};

        if (defined $val) {
            $ENV{$var} = $val;
        }
        else {
            delete $ENV{$var};
        }
    }

    return;
}

sub name {
    my $in = shift;
    my $type = blessed($in) || $in;

    $in =~ s/^DBIx::QuickDB::Driver:://;

    return $in;
}

sub init {
    my $self = shift;

    confess "'dir' is a required attribute" unless $self->{+DIR};

    $self->{+ROOT_PID} = $$;
    $self->{+_CLEANUP} = delete $self->{cleanup};

    $self->{+USERNAME} = '' unless defined $self->{+USERNAME};
    $self->{+PASSWORD} = '' unless defined $self->{+PASSWORD};

    $self->{+ENV_VARS} ||= {};

    return;
}

sub clone_data {
    my $self = shift;

    return (
        USERNAME()  => $self->{+USERNAME},
        PASSWORD()  => $self->{+PASSWORD},
        VERBOSE()   => $self->{+VERBOSE},
        AUTOSTOP()  => $self->{+AUTOSTOP},
        AUTOSTART() => $self->{+AUTOSTART},

        cleanup => $self->{+_CLEANUP},

        ENV_VARS() => {%{$self->{+ENV_VARS}}},
    );
}

sub clone {
    my $self = shift;
    my %params = @_;

    confess "Cannot clone a started database, please stop it first."
        if $self->started;

    my $orig_dir = $self->{+DIR};
    my $new_dir  = delete $params{dir} // tempdir('DB-QUICK-CLONE-XXXXXX', CLEANUP => 0, TMPDIR => 1);

    clone_dir($orig_dir, $new_dir, verbose => (($self->{+VERBOSE} // 0) > 2) ? 1 : 0);

    my $class = ref($self);
    my %ok = (
        cleanup => 1,
        map {$_ => 1} DBIx::QuickDB::Util::HashBase::attr_list($class),
    );
    my @bad = grep { !$ok{$_} } keys %params;

    confess "Invalid options to clone(): " . join(', ' => @bad)
        if @bad;

    my $clone = $class->new(
        $self->clone_data,

        %params,

        DIR() => $new_dir,

        WATCHER()  => undef,
    );

    $clone->write_config();
    $clone->start if $clone->{+AUTOSTART};

    return $clone;
}

sub gen_log {
    my $self = shift;
    return if $self->no_log(@_);
    return $self->{+DIR} . "/cmd-log-$$-" . $self->{+_LOG_ID}++;
}

sub no_log {
    my $self = shift;
    my ($params) = @_;
    return $self->{+VERBOSE} || $params->{no_log} || $ENV{DB_VERBOSE};
}

sub run_command {
    my $self = shift;
    my ($cmd, $params) = @_;

    my $no_log = $self->no_log($params);
    my $log_file = $params->{log_file} || ($no_log ? undef : $self->gen_log);

    my $pid = fork();
    croak "Could not fork" unless defined $pid;

    if ($pid) {
        local $?;
        return ($pid, $log_file) if $params->{no_wait};
        my $ret = waitpid($pid, 0);
        my $exit = $?;
        die "waitpid returned $ret" unless $ret == $pid;

        return unless $exit;

        my $log = "";
        unless ($no_log) {
            open(my $fh, '<', $log_file) or warn "Failed to open log: $!";
            $log = eval { join "" => <$fh> };
        }
        croak "Failed to run command '" . join(' ' => @$cmd) . "' ($exit)\n$log";
    }

    $self->mask_env_vars;

    unless ($no_log) {
        open(my $log, '>', $log_file) or die "Could not open log file ($log_file): $!";
        close(STDOUT);
        open(STDOUT, '>&', $log);
        close(STDERR);
        open(STDERR, '>&', $log);
    }

    if (my $file = $params->{stdin}) {
        close(STDIN);
        open(STDIN, '<', $file) or die "Could not open new STDIN ($file): $!";
    }

    exec(@$cmd);
}

sub should_cleanup { shift->{+_CLEANUP} }

sub cleanup {
    my $self = shift;

    # Ignore errors here.
    my $err = [];
    remove_tree($self->{+DIR}, {safe => 1, error => \$err}) if -d $self->{+DIR};
    return;
}

sub connect {
    my $self = shift;
    my ($db_name, %params) = @_;

    %params = (AutoCommit => 1, RaiseError => 1) unless @_ > 1;

    my $dbh;
    $self->do_in_env(
        sub {
            my $cstring = $self->connect_string($db_name);
            require DBI;
            $dbh = DBI->connect($cstring, $self->username, $self->password, \%params);
        }
    );

    return $dbh;
}

sub started {
    my $self = shift;

    my $socket = $self->socket;
    return 1 if $self->{+WATCHER} || -S $socket;
    return 0;
}

sub start {
    my $self = shift;
    my @args = @_;

    my $dir = $self->{+DIR};
    my $socket = $self->socket;

    return if $self->{+WATCHER} || -S $socket;

    my $watcher = $self->{+WATCHER} = DBIx::QuickDB::Watcher->new(db => $self, args => \@args);

    my $start = time;
    until (-S $socket) {
        my $waited = time - $start;

        if ($waited > 10) {
            $watcher->eliminate();
            confess "Timed out waiting for server to start";
            last;
        }

        sleep 0.01;
    }

    return;
}

sub stop {
    my $self = shift;
    my %params = @_;

    my $watcher = delete $self->{+WATCHER} or return;

    DBI->visit_handles(
        sub {
            my ($driver_handle) = @_;

            $driver_handle->disconnect
               if $driver_handle->{Type} && $driver_handle->{Type} eq 'db'
               && $driver_handle->{Name} && index($driver_handle->{Name}, $self->{+DIR}) >= 0;

            return 1;
        }
    );

    $watcher->stop();

    my $start = time;
    unless ($params{no_wait}) {
        $watcher->wait();

        while (-S $self->socket) {
            my $waited = time - $start;

            if ($waited > 10) {
                confess "Timed out waiting for server to stop";
                last;
            }

            sleep 0.01;
        }
    }

    return;
}

sub shell {
    my $self = shift;
    my ($db_name) = @_;
    $db_name = 'quickdb' unless defined $db_name;

    system($self->shell_command($db_name));
}

sub DESTROY {
    my $self = shift;
    return unless $self->{+ROOT_PID} && $self->{+ROOT_PID} == $$;

    if (my $watcher = delete $self->{+WATCHER}) {
        $watcher->eliminate();
    }
    elsif ($self->should_cleanup) {
        $self->cleanup();
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver - Base class for DBIx::QuickDB drivers.

=head1 DESCRIPTION

Base class for DBIx::QuickDB drivers.

=head1 SYNOPSIS

    package DBIx::QuickDB::Driver::MyDriver;
    use strict;
    use warnings;

    use parent 'DBIx::QuickDB::Driver';

    use DBIx::QuickDB::Util::HashBase qw{ ... };

    sub viable { ... ? 1 : (0, "This driver will not work because ...") }

    sub init {
        my $self = shift;

        $self->SUPER::init();

        ...
    }

    # Methods most drivers should implement

    sub version_string { ... }
    sub socket         { ... }
    sub load_sql       { ... }
    sub bootstrap      { ... }
    sub connect_string { ... }
    sub start_command  { ... }
    sub shell_command  { ... }

    # Implement if necessary
    sub write_config { ... }
    sub stop_sig { return $SIG }

    1;

=head1 METHODS PROVIDED HERE

=over 4

=item $bool = $db->autostart

True if this db was created with 'autostart' requested.

=item $bool = $db->autostop

True if this db was created with 'autostop' requested.

=item $db->cleanup

This will completely delete the database directory. B<BE CAREFUL>.

=item $dbh = $db->connect()

=item $dbh = $db->connect($db_name)

=item $dbh = $db->connect($db_name, %connect_params)

Connect to the database server. If no C<%connect_params> are specified then
C<< (AutoCommit => 1) >> will be used.

Behavior for an undef (or omitted) C<$db_name> is driver specific.

This will use the username in C<username()> and the password in C<password()>.
The connection string is defined by C<connect_string()> which must be overriden
in each driver subclass.

B<NOTE:> connect will hide all DBI and driver specific environment variables
when it establishes a connection. If you want any environment variables to be
used you must set them in the C<< $db->env_vars() >> hashref.

=item $path = $db->dir

Get the path to the database directory.

=item $db->init

This is called automatically during object construction. You B<SHOULD NOT> call
this directly, except in a subclass which overrides C<init()>.

=item $path = $db->log_file

If the database is running this will point to the log file. If the database is
not yet running, or has been stopped, this will be undef.

=item $driver_name = $db->name

Get the short name of the driver ('DBIx::QuickDB::Driver::' has been stripped).

=item $pw = $db->password

=item $db->password($pw)

Get/Set the password to use when calling C<connect()>.

=item $pid = $db->pid

=item $db->pid($pid)

If the server is running then this will have the pid. If the server is stopped
this will be undef.

B<NOTE:> This will also be undef if the server is running independantly of this
object, if the server is running, but this is undef, it means another
object/process is in control of it.

=item $pid = $db->root_pid

This should contain the original pid of the process in which the instance was
created.

=item $db->run_command(\@cmd)

=item $db->run_command(\@cmd, \%params)

=item ($pid, $logfile) = $db->run_command(\@cmd, {no_wait => 1})

This will execute the command specified in C<@cmd>. If the command fails an
exception will be thrown. By default all output will be captured into log files
and ignored. If the command fails the output will be attached to the exception.
Normally this will block until the command exits. if C<verbose()> is set then
all output is always shown.

Normally there is no return value. If the 'no_wait' param is specified then
the command will be run non-blocking and the pid and log file will be returned.

B<NOTE:> C<run_command()> will clear any DBI and driver specific environment
variables before running any commands. If you want any of the vars to be set
then you must set them in the C<< $db->env_vars() >> hashref.

Allowed params:

=over 4

=item no_log => bool

Show the output in realtime, do not redirect it.

=item no_wait => bool

Do not block, instead return the pid and log file to use later.

=item stdin => path_to_file

Run the command with the specified file is input.

=back

=item $db->shell

Launch a database shell. This depends on the C<shell_command> method, which
drivers should provide. Not all driver may support this.

=item $bool = $db->should_cleanup

True if the instance was created with the 'cleanup' specification. If this is
true then the database directory will be deleted when the program ends.

=item $db->start

Start the database. Most drivers will make this a no-op if the db is already
running.

=item $db->stop

Stop the database. Most drivers will make this a no-op if the db is already
stopped.

=item $user = $db->username

=item $db->username($user)

Get/set the username to use in C<connect()>.

=item $bool = $db->verbose

=item $db->verbose($bool)

If this is true then all output from C<run_command> will be shown at all times.

=item $clone = $db->clone()

=item $clone = $db->clone(%params)

Create a copy of the database. This database should be identical, except it
should not share any state changes moving forward, that means a new copy of all
data, etc.

=item %data = $db->clone_data()

Data to use when cloning

=item $db->write_config()

no-op on the base class, used in cloning.

=item $sig = $db->stop_sig()

What signal to send to the database server to stop it. Default: C<'TERM'>.

=item $db->DESTROY

Used to stop the server and delete the data dir (if desired) when the program
exits.

=back

=head1 ENVIRONMENT VARIABLE HANDLING

All DBI and driver specific environment variables will be hidden Whenever a
driver uses C<run_command()> or when the C<connect()> method is called. This is
to prevent you from accidentally connecting to a real/production database
unintentionally.

If there are DBI or driver specific env vars you want to be honored you must
add them to the hashref returned by C<< $db->env_vars >>. Any vars set in the
C<env_vars> hashref will be set during C<connect()> and C<run_command()>.

=head2 ENVIRONMENT VARIABLE METHODS

=over 4

=item $hashref = $db->env_vars()

Get the hashref of env vars to set whenever C<run_command()>, C<connect()>,
C<do_in_env()>, or C<mask_env_vars()> are called.

You cannot replace te hashref, but you are free to add/remove keys.

=item @vars = $db->list_env_vars

This will return a list of all DBI and driver-specific environment variables.
This is just a list of variable names, not their values.

The base class provides the following list, drivers may add more:

=over 4

=item DBI_USER

=item DBI_PASS

=item DBI_DSN

=back

=item $db->do_in_env(sub { ... })

This will execute the provided codeblock with the environment variables masked,
and any vars listed in C<env_vars()> will be set. Once the codeblock is
complete the old environment vars will be unmaskd, even if an exception is
thrown.

B<NOTE:> The return value of the codeblock is ignored.

=item $old = $db->mask_env_vars

=item $db->unmask_env_vars($old)

These methods are used to mask/unmask DBI and driver specific environment
variables.

The first method will completely clear any DBI/driver environment variables,
then apply any variables in the C<env_vars()> hash. The value returned is a
hashref needed to unmask/restore the original environment variables later.

The second method will unmask/restore the original environment variables using
the hashref returned by the first.

=back

=head1 METHODS SUBCLASSES SHOULD PROVIDE

Drivers may override C<clone()> or C<clone_data()> to control cloning.

=over

=item ($bool, $why) = $db->viable()

=item ($bool, $why) = $db->viable(\%spec)

This should check if it is possible to launch this db type on the current
system with the given spec.

See L<DBIx::QuickDB/"SPEC HASH"> for what might be in C<%spec>.

The first return value is a simple boolean, true if the driver is viable, false
if it is not. The second value should be an explanation as to why the driver is
not viable (in cases where it is not).

=item $string = Your::Driver::version_string()

=item $string = Your::Driver::version_string(\%PARAMS)

=item $string = Your::Driver->version_string()

=item $string = Your::Driver->version_string(\%PARAMS)

=item $string = $db->version_string()

=item $string = $db->version_string(\%PARAMS)

The default implementation returns 'unknown'.

This is complicated because it can be called as a function, a class method, or
an object method. It can also optionally be called with a hashref of PARAMS
that MAY be later used to construct an instance.

Lets assume your driver uses the C<start_my_db> command to launch a database.
Normally you default to the C<start_my_db> found in the $PATH environment
variable. Alternatively someone can pass in an alternative path to the binary
with the 'launcher' parameter. Here is a good implementation:

    use Scalar::Util qw/reftype/;

    sub version_string {
        my $binary;

        # Go in reverse order assuming the last param hash provided is most important
        for my $arg (reverse @_) {
            my $type = reftype($arg) or next; # skip if not a ref
            next $type eq 'HASH'; # We have a hashref, possibly blessed

            # If we find a launcher we are done looping, we want to use this binary.
            $binary = $arg->{launcher} and last;
        }

        # If no args provided one to use we fallback to the default from $PATH
        $binary ||= DEFAULT_BINARY;

        # Call the binary with '-V', capturing and returning the output using backticks.
        return `$binary -V`;
    }

=item $socket = $db->socket()

Unix Socket used to communicate with the db. If the db type does not use
sockets (such as SQLite) then this can be skipped. B<NOTE:> If you skip this
you will need to override C<stop()> and C<start()> to account for it. See
L<DBIx::QuickDB::Driver::SQLite> for an example.

=item $db->load_sql($db_name, $file)

Load the specified sql file into the specified db. It is possible that
C<$db_name> will be undef in some drivers.

=item $db->bootstrap()

Initialize the database server and create the 'quickdb' database.

=item $string = $db->connect_string()

=item $string $db->connect_string($db_name)

String to pass into C<< DBI->connect >>.

Example: C<"dbi:Pg:dbname=$db_name;host=$socket">

=item @cmd = $db->start_command()

Command used to start the server.

=item @cmd = $db->shell_command()

Command used to launch a shell into the database.

=back

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
