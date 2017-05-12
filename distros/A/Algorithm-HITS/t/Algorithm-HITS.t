use Test::More tests => 9;
use ExtUtils::testlib;
use Algorithm::HITS;
ok(1);

ok($h = new Algorithm::HITS);
$h->graph(
	  [
	   0 => 1,
	   0 => 2,
	   
	   1 => 0,
	   1 => 2,
	   
	   2 => 1,
	   ]
	  );

ok($h->iterate(2));

my $r = $h->result;

@a = (0.343559000588321,0.572598334313868,0.744377834608029);
@h = (0.721994872381155,0.618852747755276,0.309426373877638);
@authority = $r->{authority}->list;
@hub = $r->{hub}->list;

foreach (0..$#authority){
    ok(abs($authority[$_] - $a[$_]) < 0.000001);
    ok(abs($hub[$_] - $h[$_]) < 0.000001);
}
