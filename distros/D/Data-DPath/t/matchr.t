#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::DPath 'dpath', 'dpathr';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

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

# We use the same $data and paths here as in t/data_dpath.t. There,
# the match() function is already tested so here we only compare
# match() with matchr() results.

@resultlist = dpath('/AAA/BBB/CCC')->match($data);
$resultlist = dpath('/AAA/BBB/CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs" );

@resultlist = dpathr('/AAA/BBB/CCC')->match($data);
$resultlist = dpathr('/AAA/BBB/CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs (REFERENCES)" );

@resultlist = dpath('/AAA/./BBB/./CCC')->match($data);
$resultlist = dpath('/AAA/./BBB/./CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + NOSTEPs" );

@resultlist = dpathr('/AAA/./BBB/./CCC')->match($data);
$resultlist = dpathr('/AAA/./BBB/./CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + NOSTEPs (REFERENCES)" );

@resultlist = dpath('/AAA/BBB/CCC/..')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/..')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT" );

@resultlist = dpathr('/AAA/BBB/CCC/..')->match($data);
$resultlist = dpathr('/AAA/BBB/CCC/..')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT (REFERENCES)" );

@resultlist = dpath('/AAA/BBB/CCC/../.')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/../.')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + NOSTEP" );

@resultlist = dpath('//../CCC')->match($data);
$resultlist = dpath('//../CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + ANYWHERE" );

# here only CCC that is 2 levels above leafs are expected, affe/zomtec do not match for a valid reason
@resultlist = dpath('//../../CCC')->match($data);
$resultlist = dpath('//../../CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + TOO MANY PARENT + ANYWHERE" );

@resultlist = dpath('//./.././CCC/.')->match($data);
$resultlist = dpath('//./.././CCC/.')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + ANYWHERE + NOSTEP" );

@resultlist = dpath('/AAA/BBB/CCC/../..')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/../..')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + PARENT" );

@resultlist = dpathr('/AAA/BBB/CCC/../..')->match($data);
$resultlist = dpathr('/AAA/BBB/CCC/../..')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + PARENT (REFERENCES)" );

@resultlist = dpath('/AAA/././././BBB/./CCC/../././../././.')->match($data);
$resultlist = dpath('/AAA/././././BBB/./CCC/../././../././.')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + PARENT + NOSTEPs" );

@resultlist = dpath('/AAA/BBB/CCC/../../DDD')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/../../DDD')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + PARENT + KEY" );

@resultlist = dpath('/AAA/*/CCC/../../DDD')->match($data);
$resultlist = dpath('/AAA/*/CCC/../../DDD')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + ANYSTEP + PARENT + KEY no double results" );

# -------------------- ::ancestor --------------------

@resultlist = dpath('/AAA/BBB/CCC/::ancestor')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[0]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor[0]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR + FILTER int 0" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[1]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor[1]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR + FILTER int 1" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[2]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor[2]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR + FILTER int 2" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor[3]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor[3]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR + FILTER int outofbound" );

# -------------------- ::ancestor-or-self --------------------

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[0]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[0]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF + FILTER int 0" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[1]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[1]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF + FILTER int 1" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[2]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[2]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF + FILTER int 2" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[3]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[3]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF + FILTER int 3" );

@resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[4]')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/::ancestor-or-self[4]')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + ANCESTOR_OR_SELF + FILTER int outofbound" );

@resultlist = dpath('/AAA/BBB/CCC/"::ancestor-or-self"')->match($data);
$resultlist = dpath('/AAA/BBB/CCC/"::ancestor-or-self"')->matchr($data);
cmp_deeply(\@resultlist, $resultlist, "matchr: KEYs + quoted ANCESTOR_OR_SELF" );

# -------------------- misc --------------------

@resultlist = dpath('/')->match($data);
$resultlist = dpath('/')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: ROOT" );

@resultlist = dpath('/AAA/*/CCC')->match($data);
$resultlist = dpath('/AAA/*/CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: KEYs + ANYSTEP" );

# --- ---

@resultlist = dpath('//AAA/*/CCC')->match($data);
$resultlist = dpath('//AAA/*/CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: ANYWHERE + KEYs + ANYSTEP" );

@resultlist = dpath('///AAA/*/CCC')->match($data);
$resultlist = dpath('///AAA/*/CCC')->matchr($data);
cmp_bag(\@resultlist, $resultlist, "matchr: 2xANYWHERE + KEYs + ANYSTEP" );


@resultlist = Data::DPath->match($data, '//AAA/*/CCC');
$resultlist = Data::DPath->matchr($data, '//AAA/*/CCC');
cmp_bag(\@resultlist, $resultlist, "matchr: ANYWHERE + KEYs + ANYSTEP as function" );

@resultlist = Data::DPath->match($data, '///AAA/*/CCC');
$resultlist = Data::DPath->matchr($data, '///AAA/*/CCC');
cmp_bag(\@resultlist, $resultlist, "matchr: 2xANYWHERE + KEYs + ANYSTEP as function" );

done_testing();
