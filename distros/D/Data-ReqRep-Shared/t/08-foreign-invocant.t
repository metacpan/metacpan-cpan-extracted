use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::ReqRep::Shared;

# Isolated in a forked child so a crash is reported rather than taking the test run down.
plan skip_all => 'fork required' unless $Config{d_fork};

my $pid = fork;
plan skip_all => "fork: $!" unless defined $pid;
unless ($pid) {
    my $foreign = bless \( my $x = 0x5 ), 'Some::Foreign::Class';
    # eval only keeps a future croak from confusing the exit code.
    eval { Data::ReqRep::Shared::DESTROY($foreign) };
    POSIX::_exit(0);
}
waitpid $pid, 0;
my $st = $?;

ok !( $st & 127 ), 'DESTROY on a foreign blessed ref does not crash'
    or diag 'died from signal ' . ( $st & 127 );
is $st >> 8, 0, '... and the child exits cleanly';

done_testing;
