# $Id: 01-key.t 60 2008-09-02 12:11:49Z johntrammell $
# $URL: https://algorithm-voting.googlecode.com/svn/tags/rel-0.01-1/t/sortition/01-key.t $

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Digest::MD5 'md5_hex';

my $avs = 'Algorithm::Voting::Sortition';

use_ok($avs);

# verify that things "stringify" as expected
{
    is($avs->stringify("foo"),"foo.");
    is($avs->stringify(["foo"]),"foo.");
    is($avs->stringify(['a','b','c']),"a.b.c.");
    is($avs->stringify(['a','c','b']),"a.b.c.");
    is($avs->stringify([1,2,3,4]),"1.2.3.4.");
    is($avs->stringify([4,3,2,1]),"1.2.3.4.");
    is($avs->stringify({a => 1}),"a:1.");
    is($avs->stringify({a => 1, b => 2}),"a:1.b:2.");
}

# can only stringify arrayrefs and hashrefs for now
dies_ok { $avs->stringify(\"fiddle-dee-dee") } "can't stringify scalarrref";

# verify that class method "make_keystring" works correctly
{
    my $x = [1,2,3];
    my $y = [1,3,2];
    my @tests = (
        [ [ $x ] => q(1.2.3./) ],
    );
    foreach my $i (0 .. $#tests) {
        my @in = @{ $tests[$i][0] };
        my $out = $tests[$i][1];
        is($avs->make_keystring(@in),$out);
    }
}

# verify that the keystring() method works correctly 
{
    my $s = $avs->new(candidates => ['a'..'e']);
    $s->source(1 .. 4);
    is($s->keystring(), q(1./2./3./4./));
    is($s->keystring(), q(1./2./3./4./));
    is($s->keystring(), q(1./2./3./4./));
}

# make sure the example source data from RFC3797 stringifies correctly
{
    my @src = (
        9319,
        [ 2, 5, 12, 8, 10 ],
        [ 9, 18, 26, 34, 41, 45 ],
    );
    is($avs->make_keystring(@src),q(9319./2.5.8.10.12./9.18.26.34.41.45./));

}
