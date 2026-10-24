use strict;
use warnings;
use Test::More;
use POSIX ":sys_wait_h";

use Colouring::In::XS;

# The method rewrite walks a sub's ops by op_next, and a loop's ops lead back
# round to its start: 0.11 never finished compiling a `while` loop. A spin in C
# cannot be interrupted, so each case compiles in a child, given 15 seconds.
sub compiles {
    my ($code, $name) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $ok = eval "$code; 1";
        POSIX::_exit($ok ? 0 : 2);
    }
    my $waited = 0;
    while ($waited < 150) {
        my $done = waitpid($pid, WNOHANG);
        if ($done == $pid) {
            is($? >> 8, 0, $name);
            return;
        }
        select undef, undef, undef, 0.1;
        $waited++;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
    fail("$name: still compiling after 15 seconds");
}

compiles(q{my $i = 0; while (1) { last if $i++ > 3 }}, 'a while (1) loop compiles');
compiles(q{my $i = 0; until ($i > 3) { $i++ }}, 'an until loop');
compiles(q{my $c = Colouring::In::XS->new('#101820'); my $n = 0; while ($n < 3) { $c = $c->lighten('5%'); $n++ } die unless $c->toHEX(1) eq '#283d52'},
         'a loop of lighten calls compiles, and still uses the fast op');
compiles(q{for (my $i = 0; $i < 3; $i++) { my $x = Colouring::In::XS->new('#fff')->darken('10%') } }, 'a C-style for loop');
compiles(q{my @x = (1) x 3; do { shift @x } while (@x)}, 'a do-while loop');

done_testing;
