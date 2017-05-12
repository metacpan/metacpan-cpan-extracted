#! /usr/bin/perl

use Test::More tests => 17;
use CracTools::BitVector;

my $bv = CracTools::BitVector->new(10);

# Length
is($bv->length(),10, "length");

# Nb_set
is($bv->nb_set(),0, "nbSet (1)");

$bv->set(2);
$bv->set(5);

is($bv->firstBitSet,2,"firstBitSet");

#0010010000
is($bv->to_string(''),"0010010000","to_string (1)");

# Nb_set
is($bv->nb_set(),2, "nbSet (2)");

is($bv->nb_set(),2);

# get/set
is($bv->get(2),1);
is($bv->get(1),0);

# unset
$bv->unset(5);
is($bv->get(5),0);

# prev
is($bv->prev(5),2);

# succ
$bv->set(7);
is($bv->succ(3),7);

#0010000100
is($bv->to_string(''),"0010000100","to_string (2)");

# copy
my $bv_copy = $bv->copy;
$bv_copy->set(1);
is($bv->to_string(''),"0010000100","copy (1)");
is($bv_copy->to_string(''),"0110000100","copy (2)");

# rank
is($bv->rank(5),1);
is($bv->rank(7),2);

# select
is($bv->select(2),7);
