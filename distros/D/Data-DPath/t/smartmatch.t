use strict;
use warnings;
use Test::More;
BEGIN {
    if ($] < 5.010 || $] >= 5.038 ) {
        plan skip_all => "smartmatch overload tests require perl >= 5.10 and < 5.38. This is ".$];
    }
}

no if $] >= 5.018, warnings => 'experimental::smartmatch';
use Test::Deep;
use Data::DPath 'dpath', 'dpathr';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

my $data = {
            AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                    },
            some => { where => { else => {
                                          AAA => { BBB => { CCC => 'affe' } },
                                         } } },
            strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
           };


my $resultlist;

cmp_bag($data ~~ dpath('/AAA/BBB/CCC'),    [ ['XXX', 'YYY', 'ZZZ'] ], "KEYs" );
cmp_bag($data ~~ dpath('/AAA/BBB/CCC/..'), [ { CCC => ['XXX', 'YYY', 'ZZZ'] } ], "KEYs + PARENT" );
cmp_bag($data ~~ dpath('/AAA/BBB/CCC/../..'), [
                                                 {
                                                  BBB => { CCC => ['XXX', 'YYY', 'ZZZ'] },
                                                  RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                                  DDD => { EEE => [ qw/ uuu vvv www / ] },
                                                 }
                                                ], "KEYs + PARENT + PARENT" );
cmp_bag($data ~~ dpath('/AAA/BBB/CCC/../../DDD'), [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + PARENT + KEY" );
cmp_bag($data ~~ dpath('/AAA/*/CCC/../../DDD'), [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + ANYSTEP + PARENT + KEY no double results" );
cmp_bag($data ~~ dpath('/'), [ $data ], "ROOT" );
cmp_bag($data ~~ dpath('/AAA/*/CCC'), [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "KEYs + ANYSTEP" );


my $dpath = dpath('//AAA/*/CCC');
$resultlist = $data ~~ $dpath;
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and variable" );
$dpath = dpath('///AAA/*/CCC');
$resultlist = $data ~~ $dpath;
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and variable" );

$resultlist = $data ~~ dpath('//AAA/*/CCC');
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath()" );
$resultlist = $data ~~ dpath('///AAA/*/CCC');
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath()" );

$resultlist = $data ~~ dpathr('///AAA/*/CCC');
cmp_bag($resultlist, [ \($data->{some}{where}{else}{AAA}{BBB}{CCC}),
                       \($data->{AAA}{BBB}{CCC}),
                       \($data->{AAA}{RRR}{CCC}),
                     ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath() (REFERENCES)" );


$resultlist = $data ~~ dpath '//AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );
$resultlist = $data ~~ dpath '///AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );

$resultlist = $data ~~ dpath '//AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );
$resultlist = $data ~~ dpath '///AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );

done_testing;
