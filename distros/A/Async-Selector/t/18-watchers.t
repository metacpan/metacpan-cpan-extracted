use strict;
use warnings;
use Test::More;
use Async::Selector;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Async::Selector::testutils;

note('Test watchers(@res) API.');


my $s = Async::Selector->new();

sub simplewatch {
    my (@resources) = @_;
    return $s->watch(
        (map { $_ => 0 } @resources),
        sub {  }
    );
}

$s->register(
    a => sub { 'a' },
    b => sub { 'b' },
    c => sub { 'c' },
    d => sub { 'd' },
    e => sub { 'e' },
);
my @w = ();
$w[ 0] = simplewatch(qw(a));
$w[ 1] = simplewatch(qw(b));
$w[ 2] = simplewatch(qw(c));
$w[ 3] = simplewatch(qw(d));
$w[ 4] = simplewatch(qw(e));
$w[ 5] = simplewatch(qw(f)); ##
$w[ 6] = simplewatch(qw(a b));
$w[ 7] = simplewatch(qw(a d)); ##
$w[ 8] = simplewatch(qw(a e)); ##
$w[ 9] = simplewatch(qw(b c));
$w[10] = simplewatch(qw(b d));
$w[11] = simplewatch(qw(b e));
$w[12] = simplewatch(qw(c d));
$w[13] = simplewatch(qw(a b c));
$w[14] = simplewatch(qw(b c e));
$w[15] = simplewatch(qw(b d e));
$w[16] = simplewatch(qw(c d e));
$w[17] = simplewatch(qw(a b c d)); ##
$w[18] = simplewatch(qw(a b d e));
$w[19] = simplewatch(qw(b c d e));
$w[20] = simplewatch(qw(a b c d e));
$w[21] = simplewatch(qw(b d f g)); ##
$w[22] = simplewatch(qw(a f g h)); ##
$w[23] = simplewatch(qw(f g h)); ##
$w[24] = simplewatch('');

ok(!simplewatch()->active, "empty watch returns inactive watcher");
ok($_->active, "the watchers are all active") foreach @w;

checkArray "all watchers", [$s->watchers], @w;
checkArray "'a'", [$s->watchers('a')], @w[0,6,7,8,13,17,18,20,22];
checkArray "'b'", [$s->watchers('b')], @w[1,6,9,10,11,13,14,15,17,18,19,20,21];
checkArray "'c'", [$s->watchers('c')], @w[2,9,12,13,14,16,17,19,20];
checkArray "'d'", [$s->watchers('d')], @w[3,7,10,12,15,16,17,18,19,20,21];
checkArray "'e'", [$s->watchers('e')], @w[4,8,11,14,15,16,18,19,20];
checkArray "'f'", [$s->watchers('f')], @w[5,21,22,23];
checkArray "'g'", [$s->watchers('g')], @w[21,22,23];
checkArray "'h'", [$s->watchers('h')], @w[22,23];
checkArray "'i'", [$s->watchers('i')], ();
checkArray "'j'", [$s->watchers('j')], ();

checkArray "'a', 'd'", [$s->watchers('a', 'd')], @w[0,3,6,7,8,10,12,13,15,16,17,18,19,20,21,22];
checkArray "'c', 'e'", [$s->watchers('c', 'e')], @w[2,4,8,9,11,12,13,14,15,16,17,18,19,20];
checkArray "'d', 'f'", [$s->watchers('d', 'f')], @w[3,5,7,10,12,15,16,17,18,19,20,21,22,23];
checkArray "'a', 'b', 'c', 'g'", [$s->watchers('a', 'b', 'c', 'g')],
    @w[0,1,2,6..23];
checkArray "'a', 'b', 'c', 'd', 'e'", [$s->watchers('a', 'b', 'c', 'd', 'e')], @w[0..4, 6..22];


note('--- watchers() should not obtain canceled watchers');
$w[$_]->cancel() foreach (5, 7, 8, 17, 21, 22, 23);
checkArray "'a'", [$s->watchers('a')], @w[0,6,13,18,20];
checkArray "'d', 'f'", [$s->watchers('d', 'f')], @w[3,10,12,15,16,18,19,20];
checkArray "all", [$s->watchers], @w[0..4,6,9..16,18..20,24];

note('--- watchers(undef) should be simply ignored.');
checkArray "empty resource name", [$s->watchers('')], $w[24];
checkArray 'undef', [$s->watchers(undef)], ();
checkArray "'g', undef", [$s->watchers('g', undef)], ();
checkArray "undef, undef, 'b'", [$s->watchers(undef, undef, 'b')], @w[1,6,9,10,11,13,14,15,18,19,20];

done_testing();


