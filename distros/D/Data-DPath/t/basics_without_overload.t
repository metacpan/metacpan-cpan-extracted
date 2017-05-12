#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;
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

@resultlist = dpath('/')->match($data);
cmp_bag(\@resultlist, [ $data ], "ROOT" );

@resultlist = dpath('/AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "KEYs + ANYSTEP" );

cmp_bag([dpath('/AAA/BBB/CCC')->match($data)],    [ ['XXX', 'YYY', 'ZZZ'] ], "KEYs" );
cmp_bag([dpath('/AAA/BBB/CCC/..')->match($data)], [ { CCC => ['XXX', 'YYY', 'ZZZ'] } ], "KEYs + PARENT" );
cmp_bag([dpath('/AAA/BBB/CCC/../..')->match($data)], [
                                                      {
                                                       BBB => { CCC => ['XXX', 'YYY', 'ZZZ'] },
                                                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                                                       DDD => { EEE => [ qw/ uuu vvv www / ] },
                                                      }
                                                     ], "KEYs + PARENT + PARENT" );
cmp_bag([dpath('/AAA/BBB/CCC/../../DDD')->match($data)], [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + PARENT + KEY" );
cmp_bag([dpath('/AAA/*/CCC/../../DDD')->match($data)], [ { EEE => [ qw/ uuu vvv www / ] } ], "KEYs + ANYSTEP + PARENT + KEY no double results" );
cmp_bag([dpath('/')->match($data)], [ $data ], "ROOT" );
cmp_bag([dpath('/AAA/*/CCC')->match($data)], [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "KEYs + ANYSTEP" );


@resultlist = dpath('//AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], ['RR1', 'RR2', 'RR3'] ], "ANYWHERE + KEYs + ANYSTEP" );
@resultlist = dpath('///AAA/*/CCC')->match($data);
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], ['RR1', 'RR2', 'RR3'] ], "2xANYWHERE + KEYs + ANYSTEP" );


@resultlist = Data::DPath->match($data, '//AAA/*/CCC');
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP as function" );
@resultlist = Data::DPath->match($data, '///AAA/*/CCC');
cmp_bag(\@resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP as function" );

# --------------------

$resultlist = [dpath('/some//CCC')->match($data)];
cmp_bag($resultlist, [ 'affe' ], "ROOT + ANYWHERE + KEY + KEY" );

$resultlist = [dpath('//some//CCC')->match($data)];
cmp_bag($resultlist, [ 'affe' ], "ANYWHERE + KEY + ANYWHERE + KEY" );

$resultlist = [dpath('/some//else//CCC')->match($data)];
cmp_bag($resultlist, [ 'affe' ], "ROOT + KEY + ANYWHEREs + KEY" );

$resultlist = [dpath('//some//else//CCC')->match($data)];
cmp_bag($resultlist, [ 'affe' ], "ANYWHERE + KEYs + ANYWHEREs" );

$resultlist = [dpathr('//some//else//CCC')->match($data)];
cmp_bag($resultlist, [ \($data->{some}{where}{else}{AAA}{BBB}{CCC}) ], "ANYWHERE + KEYs + ANYWHEREs (REFERENCES)" );

# --------------------

my $dpath = dpath('//AAA/*/CCC');
$resultlist = [$dpath->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and variable" );
$dpath = dpath('///AAA/*/CCC');
$resultlist = [$dpath->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and variable" );

$resultlist = [dpath('//AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath()" );
$resultlist = [dpath('///AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath()" );

$resultlist = [ dpathr('///AAA/*/CCC')->match($data) ];
cmp_bag($resultlist, [ \($data->{some}{where}{else}{AAA}{BBB}{CCC}),
                       \($data->{AAA}{BBB}{CCC}),
                       \($data->{AAA}{RRR}{CCC}),
                     ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath() (REFERENCES)" );

$resultlist = [dpath('//AAA')->match($data)];
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                      { BBB => { CCC => 'affe' } },
                     ], "ANYWHERE + KEY" );

$resultlist = [dpath('//AAA/*')->match($data)];
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + KEY + ANYSTEP" );

$resultlist = [dpath('//AAA/*[size == 3]')->match($data)];
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = [dpath('//AAA[size == 3]')->match($data)];
cmp_bag($resultlist, [
                      { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                        RRR   => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                        DDD   => { EEE  => [ qw/ uuu vvv www / ] },
                      }
                     ], "ANYWHERE + KEY + FILTER size == 3" );

$resultlist = [dpath('//AAA[size != 3]')->match($data)];
cmp_bag($resultlist, [
                      { BBB => { CCC => 'affe' } }
                     ], "ANYWHERE + KEY + FILTER size != 3" );

$resultlist = [dpath('//AAA/*/*[size == 3]')->match($data)];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      [ qw/ uuu vvv www / ],
                     ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = [dpath('//.[size == 3]')->match($data)];
cmp_bag($resultlist, [
                      $data,
                      $data->{AAA},
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      [ qw/ uuu vvv www / ],
                     ], "ANYWHERE + FILTER size" );

$resultlist = [dpath('//AAA/*[size == 1]')->match($data)];
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + KEY + ANYSTEP + FILTER size" );

$resultlist = [dpath('//AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );
$resultlist = [dpath('///AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens" );

$resultlist = [dpath('//AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );
$resultlist = [dpath('///AAA/*/CCC')->match($data)];
cmp_bag($resultlist, [ 'affe', ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], "2xANYWHERE + KEYs + ANYSTEP with smartmatch and dpath without parens commutative" );

$resultlist = [dpath('/AAA/*/CCC/*')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3' ], "trailing .../* unpacks" );

$resultlist = [dpath('/strange_keys/DD DD/"EE/E"/CCC')->match($data)];
$resultlist = [dpath('/strange_keys/"DD DD"/"EE/E"/CCC')->match($data)];
cmp_bag($resultlist, [ 'zomtec' ], "quoted KEY containg slash" );

$resultlist = [dpath('//AAA/*/CCC[size == 3]')->match($data)]; # array with 3 elements
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ] ], 'FILTER size == 3' );

$resultlist = [dpath('//AAA/*/CCC[size == 1]')->match($data)]; # array with 1 elements
cmp_bag($resultlist, [ 'affe' ], 'FILTER size == 1' );

$resultlist = [dpath('//AAA/*/CCC[size >= 1]')->match($data)]; # array with >= elements
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], [ 'RR1', 'RR2', 'RR3' ], 'affe' ], 'FILTER size >= 1' );

$resultlist = [dpath('/AAA[size == 3]')->match($data)]; # hash with >= elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      }
                     ], 'FILTER hash size == 3' );

$resultlist = [dpath('/AAA[size != 3]')->match($data)]; # hash with keys
cmp_bag($resultlist, [ ], 'FILTER hash size != 3' );

$resultlist = [dpath('//AAA[size >= 1]')->match($data)]; # hash with >= elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                      { BBB => { CCC => 'affe' } },
                     ], 'FILTER hash size >= 1' );

$resultlist = [dpath('//AAA[ size >= 3 ]')->match($data)]; # hash with >= 3 elements
cmp_bag($resultlist, [
                      {
                       BBB => { CCC  => [ qw/ XXX YYY ZZZ / ] },
                       RRR => { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                       DDD => { EEE  => [ qw/ uuu vvv www / ] },
                      },
                     ], 'FILTER hash size >= 3' );

$resultlist = [dpath('//AAA[size == 1]')->match($data)]; # hash with >= elements
cmp_bag($resultlist, [
                      { BBB => { CCC => 'affe' } },
                     ], 'ANYWHERE + FILTER hash size == 1' );

$resultlist = [dpath('//AAA/*/CCC/*')->match($data)];
cmp_bag($resultlist, [ 'affe', 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3' ] );

TODO: {

        local $TODO = 'far away future spec';

        $resultlist = [dpath('/AAA/*/CCC/* | /some/where/else/AAA/BBB/CCC')->match($data)];
        # ( 'XXX', 'YYY', 'ZZZ', 'affe' )
        cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'RR1', 'RR2', 'RR3', 'affe' ] );

}

$resultlist = [dpath('/AAA/*/CCC/*[0]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1' ], "ANYSTEP + FILTER int 0" );
$resultlist = [dpath('/AAA/*/CCC/*[ 0 ]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1' ], "ANYSTEP + FILTER int 0 whitespace" );

$resultlist = [dpath('/AAA/*/CCC/*[2]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int 2" );
$resultlist = [dpath('/AAA/*/CCC/*[ 2 ]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int 2 whitespace" );

$resultlist = [dpath('/AAA/*/CCC/*[-1]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int -1" );
$resultlist = [dpath('/AAA/*/CCC/*[ -1 ]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYSTEP + FILTER int -1 whitespace" );

$resultlist = [dpath('//AAA/*/CCC/*[0]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1', 'affe' ], "ANYWHERE + ANYSTEP + FILTER int 0" );
$resultlist = [dpath('//AAA/*/CCC/*[ 0 ]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1', 'affe' ], "ANYWHERE + ANYSTEP + FILTER int 0 whitespace" );

$resultlist = [dpath('//AAA/*/CCC/*[-3]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1', ], "ANYWHERE + ANYSTEP + FILTER int -3" );
$resultlist = [dpath('//AAA/*/CCC/*[ -3 ]')->match($data)];
cmp_bag($resultlist, [ 'XXX', 'RR1', ], "ANYWHERE + ANYSTEP + FILTER int -3 whitespace" );

$resultlist = [dpath('//AAA/*/CCC/*[2]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYWHERE + ANYSTEP + FILTER int 2" );
$resultlist = [dpath('//AAA/*/CCC/*[ 2 ]')->match($data)];
cmp_bag($resultlist, [ 'ZZZ', 'RR3' ], "ANYWHERE + ANYSTEP + FILTER int 2 whitespace" );

$resultlist = [dpath('/AAA/*/CCC[2]')->match($data)];
cmp_bag($resultlist, [ ], "KEY + FILTER int" );

$resultlist = [dpath('//AAA/*/CCC[2]')->match($data)];
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + FILTER int" );


$resultlist = [dpath('/AAA/*/CCC[0]')->match($data)];
#diag Dumper($resultlist);
cmp_bag($resultlist, [ [ 'XXX', 'YYY', 'ZZZ' ], [ 'RR1', 'RR2', 'RR3' ] ], "KEY + FILTER int 0" );

$resultlist = [dpath('/AAA/*/CCC[1]')->match($data)];
cmp_bag($resultlist, [ ], "KEY + FILTER int 1" );

$resultlist = [dpath('//AAA/*/CCC[0]')->match($data)];
#diag Dumper($resultlist);
cmp_bag($resultlist, [ [ 'XXX', 'YYY', 'ZZZ' ], [ 'RR1', 'RR2', 'RR3' ], 'affe' ], "ANYWHERE + KEY + FILTER int 0" );

$resultlist = [dpath('//AAA/*/CCC[1]')->match($data)];
#diag Dumper($resultlist);
cmp_bag($resultlist, [ ], "ANYWHERE + KEY + FILTER int 1" );

# ==================================================

my $data2 = [
             'UUU',
             'VVV',
             'WWW',
             {
              AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } },
            ];

$resultlist = dpath('/*'); # /*
cmp_bag([ $resultlist->match($data2)] , [ 'UUU', 'VVV', 'WWW', { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } ], "ROOT + ANYSTEP" );

$resultlist = [ dpath('/')->match($data2) ];
cmp_bag($resultlist, [ $data2 ], "ROOT" );

$resultlist = [ dpath('//')->match($data2) ];
cmp_bag($resultlist, [
                      qw( UUU VVV WWW XXX YYY ZZZ ),
                      [ qw/ XXX YYY ZZZ / ],
                      { CCC => [ qw/ XXX YYY ZZZ / ] },
                      { BBB => { CCC => [ qw/ XXX YYY ZZZ / ] } },
                      { AAA => { BBB => { CCC => [ qw/ XXX YYY ZZZ / ] } } },
                      $data2,
                     ], "ANYWHERE" );

$resultlist = [ dpath('//*[ size == 3 ]')->match($data2) ];
cmp_bag($resultlist, [ [ qw/ XXX YYY ZZZ / ] ], "ANYWHERE + ANYSTEP + FILTER int" );

$resultlist = [ dpath('/*[2]')->match($data2) ];
cmp_bag($resultlist, [ 'WWW' ], "ROOT + ANYSTEP + FILTER int: plain value" );

$resultlist = [ dpath('/*[3]')->match($data2) ];
# ( { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } )
cmp_bag($resultlist, [ { AAA  => { BBB   => { CCC  => [ qw/ XXX YYY ZZZ / ] } } } ], "ROOT + ANYSTEP + FILTER int: ref value" );

$resultlist = [ dpath('//*[2]')->match($data2) ];
cmp_bag($resultlist, [ 'WWW', 'ZZZ' ], "ANYWHERE + ANYSTEP + FILTER int" );

# basic eval filters
$resultlist = [ dpath('/*/AAA/BBB/CCC')->match($data2) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval prepare" );
$resultlist = [ dpath('/*/AAA/BBB/CCC[17 == 17]')->match($data2) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true" );
$resultlist = [ dpath('/*/AAA/BBB/CCC[0 == 0]')->match($data2) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true with false values" );
$resultlist = [ dpath('/*/AAA/BBB/CCC["foo" eq "foo"]')->match($data2) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "FILTER eval simple true with strings" );
$resultlist = [ dpath('/*/AAA/BBB/CCC[1 == 2]')->match($data2) ];
cmp_bag($resultlist, [ ], "FILTER eval simple false" );
$resultlist = [ dpath('/*/AAA/BBB/CCC["foo" eq "bar"]')->match($data2) ];
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

$resultlist = [ dpath('//AAA/BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + KEYs in blessed structs" );

$resultlist = [ dpath('//AAA//BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + ANYWHERE + KEYs in blessed structs" );

$resultlist = [ dpath('//AAA//BBB//CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + ANYWHERE + ANYWHERE + KEYs in blessed structs" );

$resultlist = [ dpath('//AAA[ is_reftype("HASH") ]/BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype funcall + KEYs" );

$resultlist = [ dpath('//AAA[ reftype eq "HASH" ]/BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype eq + KEYs" );

$resultlist = [ dpath('//AAA[ reftype =~ /ASH/ ]/BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'], 'affe' ], "ANYWHERE + FILTER reftype match + KEYs" );

$resultlist = [ dpath('//AAA[ isa("Foo::Bar") ]/BBB/CCC')->match($data3) ];
cmp_bag($resultlist, [ ['XXX', 'YYY', 'ZZZ'] ], "ANYWHERE + FILTER isa + KEYs" );

$resultlist = [ dpath('//DDD/EEE/F1[ value eq "affe" ]/../../FFF')->match($data3) ]; # the DDD/FFF where the neighbor DDD/EEE/F1 == "affe"
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER in blessed structs" );

$resultlist = [ dpath('/neighbourhoods/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + KEYs + FILTER int 0 + KEYs" );

$resultlist = [ dpath('/*[key =~ /neighbourhoods/]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = [ dpath('/*/.[key =~ /neighbourhoods/]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = [ dpath('/*/*/../.[key =~ /neighbourhoods/]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + PARENT + NOSTEP + FILTER eval key matches + FILTER int 0 + KEYs" );

$resultlist = [ dpath('/neighbourhoods/*[1]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ROOT + KEYs + FILTER int 1 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER int 0 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[1]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ANYWHERE + KEYs + FILTER int 1 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[2]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'third value' ], "ANYWHERE + KEYs + FILTER int 2 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[3]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'fourth value' ], "ANYWHERE + KEYs + FILTER int 3 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[-1]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'fourth value' ], "ANYWHERE + KEYs + FILTER int -1 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[-2]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'third value' ], "ANYWHERE + KEYs + FILTER int -2 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[-3]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'boring value' ], "ANYWHERE + KEYs + FILTER int -3 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[-4]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ANYWHERE + KEYs + FILTER int -4 + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[-5]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ ], "ANYWHERE + KEYs + FILTER too negative int + KEYs" );

$resultlist = [ dpath('//neighbourhoods/*[20]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ ], "ANYWHERE + KEYs + FILTER too high int + KEYs" );

$resultlist = [ dpath('/*[key eq "neighbourhoods"]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key eq + FILTER int" );

$resultlist = [ dpath('/*/.[key eq "neighbourhoods"]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key eq + FILTER int" );

$resultlist = [ dpath('/*/*/../.[key eq "neighbourhoods"]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + PARENT + NOSTEP + FILTER eval key eq + FILTER int" );

$resultlist = [ dpath('/*[key =~ /neigh.*hoods/]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + FILTER eval key matches + FILTER int" );

$resultlist = [ dpath('/*/.[key =~ /neigh.*hoods/]/*[0]/DDD/FFF')->match($data3) ];
# ( 'interesting value' )
cmp_bag($resultlist, [ 'interesting value' ], "ROOT + ANYSTEP + NOSTEP + FILTER eval key matches + FILTER int" );

$resultlist = [ dpath('/*/*/../.[key =~ /neigh.*hoods/]/*[0]/DDD/FFF')->match($data3) ];
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

$resultlist = [ dpath('//AAA/BBB/CCC/*[ affe ]')->match($data4) ];
cmp_bag($resultlist, [ 'affe' ], "FILTER: affe" );

$resultlist = [ dpath('/AAA/BBB/CCC/*[ idx == 1 ]')->match($data4) ];
cmp_bag($resultlist, [ 'YYY' ], "FILTER: index" );

$resultlist = [ dpath('/AAA/BBB/CCC/*[ 1 ]')->match($data4) ];
cmp_bag($resultlist, [ 'YYY' ], "FILTER: index" );

$resultlist = [ dpath('//AAA/BBB/CCC/*[ /..../ ]')->match($data4) ];
cmp_bag($resultlist, [ 'XXXX', 'YYYY', 'ZZZZ', 'affe' ], "FILTER eval regex five chars" );

$resultlist = [ dpath('//AAA/BBB/CCC/*[ /[A-Z]+/ ]')->match($data4) ];
cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'XXXX', 'YYYY', 'ZZZZ', ], "FILTER eval regex just capitalizes" );

SKIP:
{
        skip "quote semantics changed", 1;
        $resultlist = [ dpath('//AAA/BBB/CCC/"*"[ m/[A-Z]+/ ]')->match($data4) ];
        cmp_bag($resultlist, [ 'XXX', 'YYY', 'ZZZ', 'XXXX', 'YYYY', 'ZZZZ', ], "FILTER eval regex with quotes and slashes" );
}

$resultlist = [ dpath('//AAA/BBB/*[key eq "CCC"]')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + FILTER eval key eq string" );

$resultlist = [ dpath('//AAA/BBB/.[key eq "CCC"]')->match($data) ];
cmp_bag($resultlist, [ ], "ANYWHERE + STEP + NOSTEP + FILTER eval key eq string" );

$resultlist = [ dpath('//AAA/*[ key eq "CCC" ]')->match($data) ];
cmp_bag($resultlist, [
                     ], "ANYWHERE + ANYSTEP + FILTER eval key eq string" );

$resultlist = [ dpath('//AAA/*/*[ key eq "CCC" ]')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + ANYSTEP + ANYSTEP + FILTER eval key eq string" );

$resultlist = [ dpath('//AAA/*/CCC')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP" );

$resultlist = [ dpath('//AAA/*/CCC/.[ key eq "CCC" ]')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP + FILTER eval key eq last STEP" );

$resultlist = [ dpath('//.[ key eq "DD DD" ]')->match($data) ];
cmp_bag($resultlist, [
                      { 'EE/E' => { CCC => 'zomtec' } }
                     ], "ANYWHERE + NOSTEP + FILTER eval key" );

$resultlist = [ dpath('//.[ key eq "EE/E" ]')->match($data) ];
cmp_bag($resultlist, [
                      { CCC => 'zomtec' }
                     ], "ANYWHERE + NOSTEP + FILTER eval key + slash in eval" );

$resultlist = [ dpath('//AAA/*/CCC/.[ key eq "CCC" ]')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ANYWHERE + STEP + ANYSTEP + STEP + FILTER eval key eq last STEP" );

$resultlist = [ dpath('//AAA/*[ key =~ /.../ ]')->match($data) ];
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC => 'affe' },
                     ], "ANYWHERE + STEP + ANYSTEP + FILTER eval key matches" );

$resultlist = [ dpath('//AAA/*[ key =~ qr(...) ]')->match($data) ];
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC  => 'affe' },
                     ], "ROOT + ANYSTEP + FILTER eval key matches qr()" );

$resultlist = [ dpath('//AAA/*[ key =~ m(...) ]')->match($data) ];
cmp_bag($resultlist, [
                      { CCC  => [ qw/ XXX YYY ZZZ / ] },
                      { CCC  => [ qw/ RR1 RR2 RR3 / ] },
                      { EEE  => [ qw/ uuu vvv www / ] },
                      { CCC  => 'affe' },
                     ], "ROOT + ANYSTEP + FILTER eval with key matches m(...)" );

$resultlist = [ dpath('//AAA/*[ key =~ /CC/ ]')->match($data) ];
# diag Dumper($resultlist);
cmp_bag($resultlist, [ ], "ROOT + ANYSTEP + FILTER eval with key matches /CC/" );

$resultlist = [ dpath('//AAA/*/*[ key =~ /CC/ ]')->match($data) ];
cmp_bag($resultlist, [
                      [ qw/ XXX YYY ZZZ / ],
                      [ qw/ RR1 RR2 RR3 / ],
                      'affe',
                     ], "ROOT + ANYSTEP + ANYSTEP + FILTER eval with key matches /CC/" );

$resultlist = [ dpath('//CCC/*[value eq "RR2"]')->match($data) ];
#print STDERR "resultlist = ", Dumper($resultlist);
cmp_bag($resultlist, [ 'RR2' ], "ANYWHERE + ANYSTEP + FILTER eval value" );

# print STDERR "**************************************************\n";
# print STDERR "resultlist = ", Dumper(dpath('//CCC/*[value eq "RR2"]'))->match($data); # /..
$resultlist = [ dpath('//CCC/*[value eq "RR2"]/..')->match($data) ];
#print STDERR "resultlist = ", Dumper($resultlist);
cmp_bag($resultlist, [ [ 'RR1', 'RR2', 'RR3' ] ], "ANYWHERE + ANYSTEP + FILTER eval value + PARENT" );
# print STDERR "**************************************************\n";

$resultlist = [ dpath('//CCC/*[value eq "RR2"]/../..')->match($data) ];
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

$resultlist = [ dpath('/AAA/*/CCC')->match($data5) ];
cmp_bag($resultlist, [ [ qw/ XXX YYY ZZZ / ],
                       [ qw/ RR1 RR2 RR3 / ],
                       [ qw/ ASTAR BSTAR CSTAR / ],
                       [ qw/ ASLASH BSLASH CSLASH / ],
                       [ qw/ ADOTDOT BDOTDOT CDOTDOT / ],
                       [ qw/ ADOT BDOT CDOT / ],
                     ], "KEYs + ANYSTEP again" );

$resultlist = [ dpath('/AAA/"*"/CCC')->match($data5) ];
cmp_bag($resultlist, [ [ qw/ ASTAR BSTAR CSTAR / ] ], "KEYs + (*)" );

$resultlist = [ dpath('/AAA/"//"/CCC')->match($data5) ];
cmp_bag($resultlist, [ [ qw/ ASLASH BSLASH CSLASH / ] ], "KEYs + (//)" );

$resultlist = [ dpath('/AAA/".."/CCC')->match($data5) ];
cmp_bag($resultlist, [ [ qw/ ADOTDOT BDOTDOT CDOTDOT / ] ], "KEYs + (..)" );

$resultlist = [ dpath('/AAA/"."/CCC')->match($data5) ];
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

$resultlist = [ dpath('/.[ isa("Foo::Bar") ]')->match($data6) ];
cmp_bag($resultlist, [ ], "ROOT + NOSTEP + FILTER isa (with no match)" );

$resultlist = [ dpath('/.[ isa("Some::Funky::Stuff") ]')->match($data6) ];
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa" );

# chaining filters by using NOSTEP

$resultlist = [ dpath('/.[ isa("Some::Funky::Stuff") ]/.[ size == 5 ]')->match($data6) ];
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa + FILTER size" );

$resultlist = [ dpath('/.[ isa("Some::Funky::Stuff") ]/.[ size == 5 ]/.[ reftype eq "ARRAY" ]')->match($data6) ];
cmp_bag($resultlist, [ $data6 ], "ROOT + NOSTEP + FILTER isa + FILTER size + FILTER reftype" );

$resultlist = [ dpath('//.[ size == 4 ]')->match($data6) ];
cmp_bag($resultlist, [
                      [ 1, 2, 3, 4 ],
                      [ qw( AAA BBB CCC DDD ) ],
                      [ qw( affe tiger fink star ) ],
                     ], "ANYWHERE + NOSTEP + FILTER int" );

$resultlist = [ dpath('//""/')->match($data6) ];
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

$resultlist = [ dpathr('//.[ size == 4 ]')->match($data7) ];

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

        $resultlist = [ dpath('//CCC//*[ value eq "RR3" ]/..')->match($data8) ]; # /../*[1]');
        # print STDERR "resultlist = ", Dumper($resultlist);
        cmp_bag($resultlist, [ [ 11, 22, 33 ] ], "ANYWHERE + ANYSTEP + FILTER eval value + PARENT + bless" );

}

TODO: {
        local $TODO = "REAL TODO FIX ME SOON! (but depends on test before)";

        $resultlist = [ dpath('//CCC//*[ value eq "RR3" ]/../../*[1]')->match($data8) ];
        # print STDERR "resultlist = ", Dumper($resultlist);
        cmp_bag($resultlist, [ [ 11, 22, 33 ] ], "ANYWHERE + ANYSTEP + FILTER eval value + 2xPARENT + FILTER int + bless" );
}

done_testing();
