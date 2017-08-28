#! /usr/bin/env perl

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Test::More;
use Test::Deep;
use Data::DPath 'dpath', 'dpathr';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

BEGIN {
        if ($] < 5.010) {
                plan skip_all => "Perl 5.010 required for the smartmatch overloaded tests. This is ".$];
        }
}

use_ok( 'Data::DPath' );

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

my @resultlist;
my $resultlist;
my $context;

# trivial matching

@resultlist = dpath('/AAA/BBB/CCC')->match($data);
cmp_bag(\@resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "KEYs" );

@resultlist = dpathr('/AAA/BBB/CCC')->match($data);
cmp_bag(\@resultlist, [ \($data->{AAA}{BBB}{CCC}) ], "KEYs (REFERENCES)" );

@resultlist = dpath('/AAA/./BBB/./CCC')->match($data);
cmp_bag(\@resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "KEYs + NOSTEPs" );

@resultlist = dpathr('/AAA/./BBB/./CCC')->match($data);
cmp_bag(\@resultlist, [ \($data->{AAA}{BBB}{CCC}) ], "KEYs + NOSTEPs (REFERENCES)" );

@resultlist = dpath('/AAA/BBB/CCC/..')->match($data);
cmp_bag(\@resultlist, [ { CCC => ['XXX', 'YYY', 'ZZZ'] } ], "KEYs + PARENT" );

@resultlist = dpathr('/AAA/BBB/CCC/..')->match($data);
cmp_bag(\@resultlist, [ \($data->{AAA}{BBB}) ], "KEYs + PARENT (REFERENCES)" );

@resultlist = dpath('/AAA/BBB/CCC/../.')->match($data);
cmp_bag(\@resultlist, [ { CCC => ['XXX', 'YYY', 'ZZZ'] } ], "KEYs + PARENT + NOSTEP" );

@resultlist = dpath('//../CCC')->match($data);
#print Dumper(\@resultlist);
cmp_bag(\@resultlist, [ [ qw/ XXX YYY ZZZ / ],
                          [ qw/ RR1 RR2 RR3 / ],
                          'affe',                      # missing due to reduction to HASH|ARRAY in _any?
                          'zomtec',
                        ], "KEYs + PARENT + ANYWHERE" );

# here only CCC that is 2 levels above leafs are expected, affe/zomtec do not match for a valid reason
@resultlist = dpath('//../../CCC')->match($data);
#print Dumper(\@resultlist);
cmp_bag(\@resultlist, [ [ qw/ XXX YYY ZZZ / ],
                          [ qw/ RR1 RR2 RR3 / ],
                        ], "KEYs + TOO MANY PARENT + ANYWHERE" );

@resultlist = dpath('//./.././CCC/.')->match($data);
#print Dumper(\@resultlist);
cmp_bag(\@resultlist, [ [ qw/ XXX YYY ZZZ / ],
                          [ qw/ RR1 RR2 RR3 / ],
                          'affe',                      # missing due to reduction to HASH|ARRAY in _any?
                          'zomtec',
                        ], "KEYs + PARENT + ANYWHERE + NOSTEP" );

@resultlist = dpath('/AAA/BBB/CCC/../..')->match($data);
cmp_bag(\@resultlist, [
                         {
                          BBB => { CCC => ['XXX', 'YYY', 'ZZZ'] },
                          RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                          DDD => { EEE => [ qw/ uuu vvv www / ] },
                         }
                        ], "KEYs + PARENT + PARENT" );

@resultlist = dpathr('/AAA/BBB/CCC/../..')->match($data);
cmp_bag(\@resultlist, [ \($data->{AAA}) ], "KEYs + PARENT + PARENT (REFERENCES)" );

@resultlist = dpath('/AAA/././././BBB/./CCC/../././../././.')->match($data);
cmp_bag(\@resultlist, [
                         {
                          BBB => { CCC => ['XXX', 'YYY', 'ZZZ'] },
                          RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                          DDD => { EEE => [ qw/ uuu vvv www / ] },
                         }
                        ], "KEYs + PARENT + PARENT + NOSTEPs" );

@resultlist = dpath('/AAA/BBB/CCC/../../DDD')->match($data);
cmp_bag(\@resultlist, [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + PARENT + KEY" );

@resultlist = dpath('/AAA/*/CCC/../../DDD')->match($data);
cmp_bag(\@resultlist, [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + ANYSTEP + PARENT + KEY no double results" );

# -------------------- ::ancestor --------------------

@resultlist = dpath('/AAA/BBB/CCC/::ancestor')->match($data);
cmp_deeply(\@resultlist, [
                          # order matters!
                          { CCC  => [ qw/ XXX YYY ZZZ / ] },
                          {
                           BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                           RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                           DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                          },
                          {
                           AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                                     RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                     DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                                   },
                           some => { where => { else => {
                                                         AAA => { BBB => { CCC => 'affe' } },
                                                        } } },
                           strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
                          },
                         ], "KEYs + ANCESTOR" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[0]')->match($data);
cmp_deeply(\@resultlist, [
                          { CCC  => [ qw/ XXX YYY ZZZ / ] },
                         ], "KEYs + ANCESTOR + FILTER int 0" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[1]')->match($data);
cmp_deeply(\@resultlist, [
                          {
                           BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                           RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                           DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                          },
                         ], "KEYs + ANCESTOR + FILTER int 1" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[2]')->match($data);
cmp_deeply(\@resultlist, [
                          {
                           AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                                     RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                     DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                                   },
                           some => { where => { else => {
                                                         AAA => { BBB => { CCC => 'affe' } },
                                                        } } },
                           strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
                          },
                         ], "KEYs + ANCESTOR + FILTER int 2" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[3]')->match($data);
cmp_deeply(\@resultlist, [ ], "KEYs + ANCESTOR + FILTER int outofbound" );

# -------------------- ::ancestor-or-self --------------------

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self')->match($data);
cmp_deeply(\@resultlist, [
                          # order matters!
                          [ qw/ XXX YYY ZZZ / ],
                          { CCC  => [ qw/ XXX YYY ZZZ / ] },
                          {
                           BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                           RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                           DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                          },
                          {
                           AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                                     RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                     DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                                   },
                           some => { where => { else => {
                                                         AAA => { BBB => { CCC => 'affe' } },
                                                        } } },
                           strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
                          },
                         ], "KEYs + ANCESTOR_OR_SELF" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[0]')->match($data);
cmp_deeply(\@resultlist, [
                          [ qw/ XXX YYY ZZZ / ],
                         ], "KEYs + ANCESTOR_OR_SELF + FILTER int 0" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[1]')->match($data);
cmp_deeply(\@resultlist, [
                          { CCC  => [ qw/ XXX YYY ZZZ / ] },
                         ], "KEYs + ANCESTOR_OR_SELF + FILTER int 1" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[2]')->match($data);
cmp_deeply(\@resultlist, [
                          {
                           BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                           RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                           DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                          },
                         ], "KEYs + ANCESTOR_OR_SELF + FILTER int 2" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[3]')->match($data);
cmp_deeply(\@resultlist, [
                          {
                           AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                                     RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                     DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                                   },
                           some => { where => { else => {
                                                         AAA => { BBB => { CCC => 'affe' } },
                                                        } } },
                           strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
                          },
                         ], "KEYs + ANCESTOR_OR_SELF + FILTER int 3" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[4]')->match($data);
cmp_deeply(\@resultlist, [ ], "KEYs + ANCESTOR_OR_SELF + FILTER int outofbound" );

@resultlist = dpath('/AAA/BBB/CCC/"::ancestor-or-self"')->match($data);
cmp_deeply(\@resultlist, [ ], "KEYs + quoted ANCESTOR_OR_SELF" );

# -------------------- misc --------------------

@resultlist = dpath('/')->match($data);
cmp_bag(\@resultlist, [ $data ], "ROOT" );

@resultlist = dpath('/AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "KEYs + ANYSTEP" );

# --- same with operator ---

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

# --- ---

@resultlist = dpath('//AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], ['RR1', 'RR2', 'RR3'] ], "ANYWHERE + KEYs + ANYSTEP" );
@resultlist = dpath('///AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], ['RR1', 'RR2', 'RR3'] ], "2xANYWHERE + KEYs + ANYSTEP" );


@resultlist = Data::DPath->match($data, '//AAA/*/CCC');
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP as function" );
@resultlist = Data::DPath->match($data, '///AAA/*/CCC');
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP as function" );

# from now on more via Perl 5.10 smart matching

# --------------------

$resultlist = $data ~~ dpath '/some//CCC';
cmp_bag($resultlist, [ 'affe' ], "ROOT + ANYWHERE + KEY + KEY" );

$resultlist = $data ~~ dpath '//some//CCC';
cmp_bag($resultlist, [ 'affe' ], "ANYWHERE + KEY + ANYWHERE + KEY" );

$resultlist = $data ~~ dpath '/some//else//CCC';
cmp_bag($resultlist, [ 'affe' ], "ROOT + KEY + ANYWHEREs + KEY" );

$resultlist = $data ~~ dpath '//some//else//CCC';
cmp_bag($resultlist, [ 'affe' ], "ANYWHERE + KEYs + ANYWHEREs" );

$resultlist = $data ~~ dpathr '//some//else//CCC';
cmp_bag($resultlist, [ \($data->{some}{where}{else}{AAA}{BBB}{CCC}) ], "ANYWHERE + KEYs + ANYWHEREs (REFERENCES)" );

# --------------------

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

$resultlist = $data ~~ dpath('//AAA');
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                      { BBB => { CCC => 'affe' } },
                     ], "ANYWHERE + KEY" );

$resultlist = $data ~~ dpath('//AAA/*');
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + KEY + ANYSTEP" );

$resultlist = $data ~~ dpath('//AAA/*[size == 3]');
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = $data ~~ dpath('//AAA[size == 3]');
cmp_bag($resultlist, [
                      { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                        RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                        DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                      }
                     ], "ANYWHERE + KEY + FILTER size == 3" );

$resultlist = $data ~~ dpath('//AAA[size != 3]');
cmp_bag($resultlist, [
                      { BBB => { CCC => 'affe' } }
                     ], "ANYWHERE + KEY + FILTER size != 3" );

$resultlist = $data ~~ dpath('//AAA/*/*[size == 3]');
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      [ qw/ uuu vvv www / ],
                     ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = $data ~~ dpath('//.[size == 3]');
cmp_bag($resultlist, [
                      $data,
                      $data->{AAA},
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      [ qw/ uuu vvv www / ],
                     ], "ANYWHERE + FILTER size" );

$resultlist = $data ~~ dpath('//AAA/*[size == 1]');
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = $data ~~ dpath '//AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );
$resultlist = $data ~~ dpath '///AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );

$resultlist = $data ~~ dpath '//AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );
$resultlist = $data ~~ dpath '///AAA/*/CCC';
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );

$resultlist = $data ~~ dpath '/AAA/*/CCC/*';
cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3' ], "trailing .../* unpacks" );

$resultlist = $data ~~ dpath '/strange_keys/DD DD/"EE/E"/CCC';
$resultlist = $data ~~ dpath '/strange_keys/"DD DD"/"EE/E"/CCC';
cmp_bag($resultlist, [ 'zomtec' ], "quoted KEY containg slash" );

$resultlist = $data ~~ dpath '//AAA/*/CCC[size == 3]'; # array with 3 elements
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], 'FILTER size == 3' );

$resultlist = $data ~~ dpath '//AAA/*/CCC[size == 1]'; # array with 1 elements
cmp_bag($resultlist, [ 'affe' ], 'FILTER size == 1' );

$resultlist = $data ~~ dpath '//AAA/*/CCC[size >= 1]'; # array with >= elements
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ], 'affe' ], 'FILTER size >= 1' );

$resultlist = $data ~~ dpath '/AAA[size == 3]'; # hash with >= elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      }
                     ], 'FILTER hash size == 3' );

$resultlist = $data ~~ dpath '/AAA[size != 3]'; # hash with keys
cmp_bag($resultlist, [ ], 'FILTER hash size != 3' );

$resultlist = $data ~~ dpath '//AAA[size >= 1]'; # hash with >= elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                      { BBB => { CCC => 'affe' } },
                     ], 'FILTER hash size >= 1' );

$resultlist = $data ~~ dpath '//AAA[ size >= 3 ]'; # hash with >= 3 elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                     ], 'FILTER hash size >= 3' );

$resultlist = $data ~~ dpath '//AAA[size == 1]'; # hash with >= elements
cmp_bag($resultlist, [
                      { BBB => { CCC => 'affe' } },
                     ], 'ANYWHERE + FILTER hash size == 1' );

$resultlist = $data ~~ dpath '//AAA/*/CCC/*';
cmp_bag($resultlist, [ 'affe', 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3' ] );

TODO: {

        local $TODO = 'far away future spec';

        $resultlist = $data ~~ dpath '/AAA/*/CCC/* | /some/where/else/AAA/BBB/CCC';
        # ( 'XXX', 'YYY', 'ZZZ', 'affe' )
        cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3', 'affe' ] );

}

$resultlist = $data ~~ dpath '/AAA/*/CCC/*[0]';
cmp_bag($resultlist, [ 'XXX', 'RR1' ], "ANYSTEP + FILTER int 0" );
$resultlist = $data ~~ dpath '/AAA/*/CCC/*[ 0 ]';
cmp_bag($resultlist, [ 'XXX', 'RR1' ], "ANYSTEP + FILTER int 0 whitespace" );

$resultlist = $data ~~ dpath '/AAA/*/CCC/*[2]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int 2" );
$resultlist = $data ~~ dpath '/AAA/*/CCC/*[ 2 ]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int 2 whitespace" );

$resultlist = $data ~~ dpath '/AAA/*/CCC/*[-1]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int -1" );
$resultlist = $data ~~ dpath '/AAA/*/CCC/*[ -1 ]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int -1 whitespace" );

$resultlist = $data ~~ dpath '//AAA/*/CCC/*[0]';
cmp_bag($resultlist, [ 'XXX', 'RR1', 'affe' ], "ANYWHERE + ANYSTEP + FILTER int 0" );
$resultlist = $data ~~ dpath '//AAA/*/CCC/*[ 0 ]';
cmp_bag($resultlist, [ 'XXX', 'RR1', 'affe' ], "ANYWHERE + ANYSTEP + FILTER int 0 whitespace" );

$resultlist = $data ~~ dpath '//AAA/*/CCC/*[-3]';
cmp_bag($resultlist, [ 'XXX', 'RR1', ], "ANYWHERE + ANYSTEP + FILTER int -3" );
$resultlist = $data ~~ dpath '//AAA/*/CCC/*[ -3 ]';
cmp_bag($resultlist, [ 'XXX', 'RR1', ], "ANYWHERE + ANYSTEP + FILTER int -3 whitespace" );

$resultlist = $data ~~ dpath '//AAA/*/CCC/*[2]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYWHERE + ANYSTEP + FILTER int 2" );
$resultlist = $data ~~ dpath '//AAA/*/CCC/*[ 2 ]';
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYWHERE + ANYSTEP + FILTER int 2 whitespace" );

$resultlist = $data ~~ dpath '/AAA/*/CCC[2]';
cmp_bag($resultlist, [ ], "KEY + FILTER int" );

$resultlist = $data ~~ dpath '//AAA/*/CCC[2]';
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + FILTER int" );


$resultlist = $data ~~ dpath '/AAA/*/CCC[0]';
#diag Dumper($resultlist);
cmp_bag($resultlist, [ [ 'XXX', 'YYY', 'ZZZ' ], [ 'RR1', 'RR2', 'RR3' ] ], "KEY + FILTER int 0" );

$resultlist = $data ~~ dpath '/AAA/*/CCC[1]';
cmp_bag($resultlist, [ ], "KEY + FILTER int 1" );

$resultlist = $data ~~ dpath '//AAA/*/CCC[0]';
#diag Dumper($resultlist);
cmp_bag($resultlist, [ [ 'XXX', 'YYY', 'ZZZ' ], [ 'RR1', 'RR2', 'RR3' ], 'affe' ], "ANYWHERE + KEY + FILTER int 0" );

$resultlist = $data ~~ dpath '//AAA/*/CCC[1]';
#diag Dumper($resultlist);
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + FILTER int 1" );

# ----------------------------------------

my $data2 = [
             'UUU',
             'VVV',
             'WWW',
             {
              AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } },
            ];

$resultlist = $data2 ~~ dpath '/*'; # /*
cmp_bag($resultlist, [ 'UUU', 'VVV', 'WWW', { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } ], "ROOT + ANYSTEP" );

$resultlist = $data2 ~~ dpath '/';
cmp_bag($resultlist, [ $data2 ], "ROOT" );

$resultlist = $data2 ~~ dpath '//';
cmp_bag($resultlist, [
                      qw( UUU VVV WWW XXX YYY ZZZ ),
                      [ qw/ XXX YYY ZZZ / ],
                      { CCC => [ qw/ XXX YYY ZZZ / ] },
                      { BBB => { CCC => [ qw/ XXX YYY ZZZ / ] } },
                      { AAA => { BBB => { CCC => [ qw/ XXX YYY ZZZ / ] } } },
                      $data2,
                     ], "ANYWHERE" );

$resultlist = $data2 ~~ dpath '//*[ size == 3 ]';
cmp_bag($resultlist, [ [ qw/ XXX YYY ZZZ / ] ], "ANYWHERE + ANYSTEP + FILTER int" );

$resultlist = $data2 ~~ dpath '/*[2]';
cmp_bag($resultlist, [ 'WWW' ], "ROOT + ANYSTEP + FILTER int: plain value" );

$resultlist = $data2 ~~ dpath '/*[3]';
# ( { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } )
cmp_bag($resultlist, [ { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } ], "ROOT + ANYSTEP + FILTER int: ref value" );

$resultlist = $data2 ~~ dpath '//*[2]';
cmp_bag($resultlist, [ 'WWW', 'ZZZ' ], "ANYWHERE + ANYSTEP + FILTER int" );

# basic eval filters
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval prepare" );
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC[17 == 17]';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true" );
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC[0 == 0]';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true with false values" );
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC["foo" eq "foo"]';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true with strings" );
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC[1 == 2]';
cmp_bag($resultlist, [ ], "FILTER eval simple false" );
$resultlist = $data2 ~~ dpath '/*/AAA/BBB/CCC["foo" eq "bar"]';
cmp_bag($resultlist, [ ], "FILTER eval simple false with strings" );

# ----------------------------------------

my $data3  = {
              AAA  => bless( { BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] } }, "Foo::Bar"), # blessed BBB
              some => { where => { else => {
                                            AAA => { BBB => { CCC => 'affe' } }, # plain BBB
                                           } } },
              neighbourhoods => [
                                 { 'DDD' => { EEE => bless( { F1 => 'affe',
                                                       F2 => 'tiger',
                                                       F3 => 'fink',
                                                       F4 => 'star',
                                                     }, "Affe"),
                                              FFF => 'interesting value' }
                                 },
                                 { 'DDD' => { EEE => { F1 => 'bla',
                                                       F2 => 'bli',
                                                       F3 => 'blu',
                                                       F4 => 'blo',
                                                     },
                                              FFF => 'boring value' }
                                 },
                                 { 'DDD' => { EEE => { F1 => 'xbla',
                                                       F2 => 'xbli',
                                                       F3 => 'xblu',
                                                       F4 => 'xblo',
                                                     },
                                              FFF => 'third value' }
                                 },
                                 { 'DDD' => { EEE => { F1 => 'ybla',
                                                       F2 => 'ybli',
                                                       F3 => 'yblu',
                                                       F4 => 'yblo',
                                                     },
                                              FFF => 'fourth value' }
                                 },
                                ],
             };

# ------------------------------

$resultlist = $data3 ~~ dpath '//AAA/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + KEYs in blessed structs" );

$resultlist = $data3 ~~ dpath '//AAA//BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + ANYWHERE + KEYs in blessed structs" );

$resultlist = $data3 ~~ dpath '//AAA//BBB//CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + ANYWHERE + ANYWHERE + KEYs in blessed structs" );

SKIP: {
        skip "Filter functions with optional args are deprecated, use the is_XXX(args) form instead.", 1;
        $resultlist = $data3 ~~ dpath '//AAA[ reftype("HASH") ]/BBB/CCC';
        cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype funcall + KEYs" );
}

$resultlist = $data3 ~~ dpath '//AAA[ is_reftype("HASH") ]/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype funcall + KEYs" );

$resultlist = $data3 ~~ dpath '//AAA[ reftype eq "HASH" ]/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype eq + KEYs" );

$resultlist = $data3 ~~ dpath '//AAA[ reftype =~ /ASH/ ]/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype smartmatch + KEYs" );

$resultlist = $data3 ~~ dpath '//AAA[ isa("Foo::Bar") ]/BBB/CCC';
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "ANYWHERE + FILTER isa + KEYs" );

$resultlist = $data3 ~~ dpath '//DDD/EEE/F1[ value eq "affe" ]/../../FFF'; # the DDD/FFF where the neighbor DDD/EEE/F1 == "affe"
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER in blessed structs" );

# ------------------------------

$resultlist = $data3 ~~ dpath '/neighbourhoods/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + KEYs + FILTER int 0 + KEYs" );

$resultlist = $data3 ~~ dpath '/*[key =~ /neighbourhoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = $data3 ~~ dpath '/*/.[key =~ /neighbourhoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = $data3 ~~ dpath '/*/*/../.[key =~ /neighbourhoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + PARENT + NOSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = $data3 ~~ dpath '/neighbourhoods/*[1]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ROOT + KEYs + FILTER int 1 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER int 0 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[1]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ANYWHERE + KEYs + FILTER int 1 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[2]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'third value' ], "ANYWHERE + KEYs + FILTER int 2 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[3]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'fourth value' ], "ANYWHERE + KEYs + FILTER int 3 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[-1]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'fourth value' ], "ANYWHERE + KEYs + FILTER int -1 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[-2]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'third value' ], "ANYWHERE + KEYs + FILTER int -2 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[-3]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ANYWHERE + KEYs + FILTER int -3 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[-4]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER int -4 + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[-5]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ ], "ANYWHERE + KEYs + FILTER too negative int + KEYs" );

$resultlist = $data3 ~~ dpath '//neighbourhoods/*[20]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ ], "ANYWHERE + KEYs + FILTER too high int + KEYs" );

$resultlist = $data3 ~~ dpath '/*[key eq "neighbourhoods"]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key eq + FILTER int" );

$resultlist = $data3 ~~ dpath '/*/.[key eq "neighbourhoods"]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key eq + FILTER int" );

$resultlist = $data3 ~~ dpath '/*/*/../.[key eq "neighbourhoods"]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + PARENT + NOSTEP + FILTER eval key eq + FILTER int" );

$resultlist = $data3 ~~ dpath '/*[key =~ /neigh.*hoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key matches + FILTER int" );

$resultlist = $data3 ~~ dpath '/*/.[key =~ /neigh.*hoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key matches + FILTER int" );

$resultlist = $data3 ~~ dpath '/*/*/../.[key =~ /neigh.*hoods/]/*[0]/DDD/FFF';
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + PARENT + NOSTEP + FILTER eval key matches + FILTER int" );

# ----------------------------------------

my $data4  = {
              AAA  => { BBB => { CCC  => [ qw/
                                                     XXX
                                                     YYY
                                                     ZZZ
                                                     XXXX
                                                     YYYY
                                                     ZZZZ
                                             / ] } },
              some => { where => { else => {
                                            AAA => { BBB => { CCC => 'affe' } }, # plain BBB
                                           } } },
              neighbourhoods => [
                                 { 'DDD' => { EEE => { F1 => 'affe',
                                                       F2 => 'tiger',
                                                       F3 => 'fink',
                                                       F4 => 'star',
                                                     },
                                              FFF => 'interesting value' }
                                 },
                                 { 'DDD' => { EEE => { F1 => 'bla',
                                                       F2 => 'bli',
                                                       F3 => 'blu',
                                                       F4 => 'blo',
                                                     },
                                              FFF => 'boring value' }
                                 },
                                ],
             };

$resultlist = $data4 ~~ dpath '//AAA/BBB/CCC/*[ affe ]';
cmp_bag($resultlist, [ 'affe' ], "FILTER: affe" );

$resultlist = $data4 ~~ dpath '/AAA/BBB/CCC/*[ idx == 1 ]';
cmp_bag($resultlist, [ 'YYY' ], "FILTER: index" );

$resultlist = $data4 ~~ dpath '/AAA/BBB/CCC/*[ 1 ]';
cmp_bag($resultlist, [ 'YYY' ], "FILTER: index" );

$resultlist = $data4 ~~ dpath '//AAA/BBB/CCC/*[ /..../ ]';
cmp_bag($resultlist, [ 'XXXX', 'YYYY', 'ZZZZ', 'affe' ], "FILTER eval regex five chars" );

$resultlist = $data4 ~~ dpath '//AAA/BBB/CCC/*[ /[A-Z]+/ ]';
cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'XXXX', 'YYYY', 'ZZZZ', ], "FILTER eval regex just capitalizes" );

SKIP:
{
        skip "quote semantics changed", 1;
        $resultlist = $data4 ~~ dpath '//AAA/BBB/CCC/"*"[ m/[A-Z]+/ ]';
        cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'XXXX', 'YYYY', 'ZZZZ', ], "FILTER eval regex with quotes and slashes" );
}

$resultlist = $data ~~ dpath '//AAA/BBB/*[key eq "CCC"]';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + FILTER eval key eq string" );

$resultlist = $data ~~ dpath '//AAA/BBB/.[key eq "CCC"]';
cmp_bag($resultlist, [ ], "ANYWHERE + STEP + NOSTEP + FILTER eval key eq string" );

$resultlist = $data ~~ dpath '//AAA/*[ key eq "CCC" ]';
cmp_bag($resultlist, [
                     ], "ANYWHERE + ANYSTEP + FILTER eval key eq string" );

$resultlist = $data ~~ dpath '//AAA/*/*[ key eq "CCC" ]';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + ANYSTEP + ANYSTEP + FILTER eval key eq string" );

$resultlist = $data ~~ dpath '//AAA/*/CCC';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP" );

$resultlist = $data ~~ dpath '//AAA/*/CCC/.[ key eq "CCC" ]';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP + FILTER eval key eq last STEP" );

$resultlist = $data ~~ dpath '//.[ key eq "DD DD" ]';
cmp_bag($resultlist, [
                      { 'EE/E' => { CCC => 'zomtec' } }
                     ], "ANYWHERE + NOSTEP + FILTER eval key" );

$resultlist = $data ~~ dpath '//.[ key eq "EE/E" ]';
cmp_bag($resultlist, [
                      { CCC => 'zomtec' }
                     ], "ANYWHERE + NOSTEP + FILTER eval key + slash in eval" );

$resultlist = $data ~~ dpath '//AAA/*/CCC/.[ key eq "CCC" ]';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP + FILTER eval key eq last STEP" );

$resultlist = $data ~~ dpath '//AAA/*[ key =~ /.../ ]';
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + STEP + ANYSTEP + FILTER eval key matches" );

$resultlist = $data ~~ dpath '//AAA/*[ key =~ qr(...) ]';
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC  => 'affe' },
                     ], "ROOT + ANYSTEP + FILTER eval key matches qr()" );

$resultlist = $data ~~ dpath '//AAA/*[ key =~ m(...) ]';
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC  => 'affe' },
                     ], "ROOT + ANYSTEP + FILTER eval with key matches m(...)" );

$resultlist = $data ~~ dpath '//AAA/*[ key =~ /CC/ ]';
cmp_bag($resultlist, [ ], "ROOT + ANYSTEP + FILTER eval with key matches /CC/" );

$resultlist = $data ~~ dpath '//AAA/*/*[ key =~ /CC/ ]';
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ROOT + ANYSTEP + ANYSTEP + FILTER eval with key matches /CC/" );

$resultlist = $data ~~ dpath('//CCC/*[value eq "RR2"]');
#print STDERR "resultlist = ", Dumper($resultlist);
cmp_bag($resultlist, [ 'RR2' ], "ANYWHERE + ANYSTEP + FILTER eval value" );

# print STDERR "**************************************************\n";
# print STDERR "resultlist = ", Dumper($data ~~ dpath('//CCC/*[value eq "RR2"]')); # /..
$resultlist = $data ~~ dpath('//CCC/*[value eq "RR2"]/..');
#print STDERR "resultlist = ", Dumper($resultlist);
cmp_bag($resultlist, [ [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + ANYSTEP + FILTER eval value + PARENT" );
# print STDERR "**************************************************\n";

$resultlist = $data ~~ dpath('//CCC/*[value eq "RR2"]/../..');
#print STDERR "resultlist = ", Dumper($resultlist);
cmp_bag($resultlist, [ { CCC  => [ 'RR1', 'RR2', 'RR3' ] } ], "ANYWHERE + ANYSTEP + FILTER eval value + 2xPARENT" );

# ----------------------------------------


my $data5 = {
             AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                       "*"   => { CCC  => [ qw/ ASTAR BSTAR CSTAR / ] },
                       "//"  => { CCC  => [ qw/ ASLASH BSLASH CSLASH / ] },
                       ".."  => { CCC  => [ qw/ ADOTDOT BDOTDOT CDOTDOT / ] },
                       "."   => { CCC  => [ qw/ ADOT BDOT CDOT / ] },
                     },
            };

$resultlist = $data5 ~~ dpath('/AAA/*/CCC');
cmp_bag($resultlist, [ [ qw/ XXX YYY ZZZ / ],
                       [ qw/ RR1 RR2 RR3 / ],
                       [ qw/ ASTAR BSTAR CSTAR / ],
                       [ qw/ ASLASH BSLASH CSLASH / ],
                       [ qw/ ADOTDOT BDOTDOT CDOTDOT / ],
                       [ qw/ ADOT BDOT CDOT / ],
                     ], "KEYs + ANYSTEP again" );

$resultlist = $data5 ~~ dpath('/AAA/"*"/CCC');
cmp_bag($resultlist, [ [ qw/ ASTAR BSTAR CSTAR / ] ], "KEYs + (*)" );

$resultlist = $data5 ~~ dpath('/AAA/"//"/CCC');
cmp_bag($resultlist, [ [ qw/ ASLASH BSLASH CSLASH / ] ], "KEYs + (//)" );

$resultlist = $data5 ~~ dpath('/AAA/".."/CCC');
cmp_bag($resultlist, [ [ qw/ ADOTDOT BDOTDOT CDOTDOT / ] ], "KEYs + (..)" );

$resultlist = $data5 ~~ dpath('/AAA/"."/CCC');
cmp_bag($resultlist, [ [ qw/ ADOT BDOT CDOT / ] ], "KEYs + (.)" );

# ----------------------------------------


my $data6 = bless [
                   [ 2, 3, 5, 7, 11, 13, 17, 19, 23 ],
                   [ 1, 2, 3, 4 ],
                   [ qw( AAA BBB CCC DDD ) ],
                   [ 11, 22, 33 ],
                   {
                    hot => {
                            stuff => {
                                      ahead => [ qw( affe tiger fink star ) ],
                                      ""    => "some value on empty key",
                                     }
                           }
                   },
                  ], "Some::Funky::Stuff";

$resultlist = $data6 ~~ dpath '/.[ isa("Foo::Bar") ]';
cmp_bag($resultlist, [ ], "ROOT + NOSTEP + FILTER isa (with no match)" );

$resultlist = $data6 ~~ dpath '/.[ isa("Some::Funky::Stuff") ]';
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa" );

# chaining filters by using NOSTEP

$resultlist = $data6 ~~ dpath '/.[ isa("Some::Funky::Stuff") ]/.[ size == 5 ]';
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa + FILTER size" );

$resultlist = $data6 ~~ dpath '/.[ isa("Some::Funky::Stuff") ]/.[ size == 5 ]/.[ reftype eq "ARRAY" ]';
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa + FILTER size + FILTER reftype" );

$resultlist = $data6 ~~ dpath '//.[ size == 4 ]';
cmp_bag($resultlist, [
                      [ 1, 2, 3, 4 ],
                      [ qw( AAA BBB CCC DDD ) ],
                      [ qw( affe tiger fink star ) ],
                     ], "ANYWHERE + NOSTEP + FILTER int" );

$resultlist = $data6 ~~ dpath '//""/';
cmp_bag($resultlist, [ "some value on empty key" ], "empty key");

my $data7 =  [
              [ 2, 3, 5, 7, 11, 13, 17, 19, 23 ],
              [ 1, 2, 3, 4 ],
              [ qw( AAA BBB CCC DDD ) ],
              [ 11, 22, 33 ],
              {
               hot => {
                       stuff => {
                                 ahead => [ qw( affe tiger fink star ) ],
                                 ""    => "some value on empty key",
                                }
                      }
              },
             ];

$resultlist = $data7 ~~ dpathr '//.[ size == 4 ]';

cmp_bag($resultlist, [
                      \($data7->[1]),
                      \($data7->[2]),
                      \($data7->[4]{hot}{stuff}{ahead}),
                     ], "ANYWHERE + NOSTEP + FILTER int (REFERENCES)" );

${$resultlist->[0]} = [ qw(one two three four) ];
${$resultlist->[1]} = "there once was an array in LA";
${$resultlist->[2]} = { affe => "tiger",
                        fink => "star",
                      };

my $data7_expected_change = [
                             [ 2, 3, 5, 7, 11, 13, 17, 19, 23 ],
                             [ 'one', 'two', 'three', 'four' ],
                             "there once was an array in LA",
                             [ 11, 22, 33 ],
                             {
                              hot => {
                                      stuff => {
                                                ahead => { affe => "tiger",
                                                           fink => "star" },
                                                ""    => "some value on empty key",
                                               }
                                     }
                             },
                            ];

# diag Dumper($resultlist);
# diag Dumper($data7_expected_change);
# diag Dumper($data7);

cmp_bag($data7, $data7_expected_change, "ANYWHERE + NOSTEP + FILTER int (REFERENCES CHANGED)" );

my $data8 = {
             AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR   => { CCC  => bless([
                                                 [ qw/ RR1 RR2 RR3 /],
                                                 [ 11, 22, 33 ],
                                                ], "Zomtec") },
                       DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                     },
             some => { where => { else => {
                                           AAA => { BBB => { CCC => 'affe' } },
                                          } } },
             strange_keys => { 'DD DD' => { 'EE/E' => { CCC => 'zomtec' } } },
            };


TODO: {
        local $TODO = "REAL TODO FIX ME SOON!";

        $resultlist = $data8 ~~ dpath('//CCC//*[ value eq "RR3" ]/..'); # /../*[1]');
        # print STDERR "resultlist = ", Dumper($resultlist);
        cmp_bag($resultlist, [ [ 11, 22, 33 ] ], "ANYWHERE + ANYSTEP + FILTER eval value + PARENT + bless" );

}

TODO: {
        local $TODO = "REAL TODO FIX ME SOON! (but depends on test before)";

        $resultlist = $data8 ~~ dpath('//CCC//*[ value eq "RR3" ]/../../*[1]');
        # print STDERR "resultlist = ", Dumper($resultlist);
        cmp_bag($resultlist, [ [ 11, 22, 33 ] ], "ANYWHERE + ANYSTEP + FILTER eval value + 2xPARENT + FILTER int + bless" );
}

done_testing();
