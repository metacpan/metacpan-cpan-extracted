package QDB::FakeDriver;
use strict;
use warnings;

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{
    <exit_code
    <run_seconds
    <start_script
    <shell_script
    <stop_signal
    <fast_stop_signal
    <serve
};

sub stop_sig {
    my $self = shift;
    return $self->{+STOP_SIGNAL} // $self->SUPER::stop_sig;
}

sub fast_stop_sig {
    my $self = shift;
    return $self->{+FAST_STOP_SIGNAL} // $self->SUPER::fast_stop_sig;
}

sub viable { (1, undef) }

# Only created when the server is told to serve; otherwise nothing but the
# server exiting can end start()'s wait.
sub socket {
    my $self = shift;
    return $self->{+DIR} . "/fake.sock";
}

sub start_command {
    my $self = shift;

    return ('/bin/sh', '-c', $self->{+SHELL_SCRIPT}) if defined $self->{+SHELL_SCRIPT};
    return ($^X, '-e', $self->{+START_SCRIPT}) if defined $self->{+START_SCRIPT};

    my $code    = $self->{+EXIT_CODE}   // 0;
    my $seconds = $self->{+RUN_SECONDS} // 0;

    # Create the socket so start() succeeds, for tests about teardown rather
    # than startup.
    return (
        $^X, '-MIO::Socket::UNIX', '-e',
        'IO::Socket::UNIX->new(Local => $ARGV[0], Listen => 1) or die $!; sleep $ARGV[1]; exit $ARGV[2]',
        $self->socket, $seconds, $code,
    ) if $self->{+SERVE};

    return ($^X, '-e', "sleep $seconds; exit $code");
}

sub bootstrap     { }
sub write_config  { }
sub load_sql      { }
sub connect_string { 'dbi:FakeDriver:' }
sub shell_command { ($^X, '-e', 'exit 0') }

1;

__END__

=head1 NAME

QDB::FakeDriver - Driver with no database, for testing the watcher itself.

=head1 DESCRIPTION

Drives the real watcher and the real L<DBIx::QuickDB::Driver/start> against a
"server" whose behavior the test dictates. Needs no database binaries, so it
runs anywhere the watcher does.

Use it to cover the wiring rather than a database. Unit tests around the
watcher's helpers prove those helpers work; only a real watch loop proves the
loop calls them and that C<start> acts on the result.

=head1 SYNOPSIS

    my $db = QDB::FakeDriver->new(dir => $dir, exit_code => 7, autostart => 0);
    eval { $db->start };    # fails fast with "exit value 7"

=head1 ATTRIBUTES

All are optional; without any of them the server exits 0 immediately.

=over 4

=item exit_code => $int

=item run_seconds => $int

Server sleeps this long, then exits with C<exit_code>.

=item start_script => $perl_code

Run the given code as the server via C<$^X -e> instead.

=item shell_script => $sh_code

Run the given code as the server via C</bin/sh -c> instead. Needed only when the
server must report the signal disposition it inherited: perl resets SIGCHLD at
interpreter startup, so a perl server cannot, while F<sh> passes it through.

=item serve => $bool

Have the server bind the socket C<start> polls for, so C<start> succeeds. For
tests about teardown rather than startup. Without it the socket is never
created, and only the server exiting ends the wait.

=item stop_signal => $sig

=item fast_stop_signal => $sig

Override the signals teardown sends. Pass something invalid, such as C<999>, to
exercise a teardown that cannot stop its server.

=back

=cut
