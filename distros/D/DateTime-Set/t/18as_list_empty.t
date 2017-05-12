#!/usr/bin/perl

# this test was contributed by Stephen Gowing
# more tests - Flavio

use strict;

use Test::More tests => 8;

use DateTime;
use DateTime::Set;

my $d1 = DateTime->new( year => 2002, month => 3, day => 11 );
my $d2 = DateTime->new( year => 2002, month => 4, day => 11 );
my $d3 = DateTime->new( year => 2002, month => 5, day => 11 );
my( $set, $r, $n, @dt );

# infinite set



# "START"
$set = DateTime::Set->from_recurrence(
    recurrence => sub { $_[0]->truncate( to => 'month' )->add( months => 1 ) }
);

@dt = $set->as_list;
$r = scalar @dt;
is($r, 1, 
    'Infinite date set - as_list - returns a single, "undef" element, as documented');
is($dt[0], undef,  'Infinite date set - as_list - the element is undef');

$n = $set->count;
is($n, undef, 'Infinite date set - count is undef');

# set with 1 element

$set = DateTime::Set->from_datetimes( dates => [ $d1 ] );

@dt = $set->as_list;
$r = join(' ', @dt);
is($r, '2002-03-11T00:00:00', 'Single date set - as_list');

$n = $set->count;
is($n, 1, 'Single date set - count is 1');

# empty set

@dt = $set->as_list( start => $d2, end => $d3 );

$r = join(' ', @dt);
is( scalar @dt, 0, 'Out of range / empty set - as_list returns an empty list');
is($r, '', 'Out of range / empty set - as_list stringifies as an empty string');

$n = $set->count( start => $d2, end => $d3 );
is($n, 0, 'Out of range / empty set - count is zero');

