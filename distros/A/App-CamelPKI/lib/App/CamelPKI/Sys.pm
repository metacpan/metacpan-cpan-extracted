#!perl -w

use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::Sys> - Operating System-oriented bag of tricks.

=cut

package App::CamelPKI::Sys;

=head1 FUNCTIONS

All functions are exportable, but none are by default.

=cut

use base "Exporter";
our @EXPORT_OK = qw(fork_and_do);

=head2 fork_and_do($sub)

Runs $sub in a forked process, and returns the PID it runs under.  The
child process calls $sub in void context, and terminates when $sub
does so; if $sub terminates normally, the exit code of the child
process will be 0, otherwise it will be 1.  The child process will
B<not> perform global destruction, even if $sub contains an explicit
call to L<perlfunc/exit>.

=cut

sub fork_and_do (&) {
    my ($sub) = @_;
    require POSIX; # For _exit, which unlike L<perlfunc/exit> refrains
    # from doing global destruction, which would be a Bad Thing (even
    # from a forked process this may have unwanted consequences such
    # as saying goodbye on network sockets, destroying temporary
    # files, etc.)
    defined(my $pid = fork) or die "fork_and_do: fork failed";
    return $pid if $pid;

    # In child process only:
    eval 'END { POSIX::_exit($?) }';
    eval { $sub->();  exit(0) };
    warn $@; exit(1);
}

require My::Tests::Below unless caller;

__END__

use Test::More qw(no_plan);
use Test::Group;

use App::CamelPKI::Sys qw(fork_and_do);

test "fork_and_do" => sub {
    my $pid = fork_and_do {
        1;
    };
    waitpid($pid, 0); is($?, 0, "sub terminating normally");

    $pid = fork_and_do {
        die "don't worry, this message is normal\n";
    };
    waitpid($pid, 0); is($?, 1 << 8, "sub throwing an exception");

    $pid = fork_and_do {
        exit(42);
    };
    waitpid($pid, 0); is($?, 42 << 8, "sub exits with custom code");

    $pid = fork_and_do {
        sleep 10;
    };
    kill 9 => $pid;
    waitpid($pid, 0); is($? & 127, 9, "we get signal");
};

