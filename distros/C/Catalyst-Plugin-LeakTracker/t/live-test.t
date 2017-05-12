#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 'no_plan';

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

my @t = @{ TestApp->object_trackers };

is( scalar(@t), 1, "one tracker" );

my $live_objects = $t[0]->live_objects;

is( scalar( keys %$live_objects ), 0, "no leaked objects" );

TestApp->object_trackers([]);

$mech->get_ok('http://localhost/leak', 'get main page');
$mech->content_like(qr/it leaks/, 'see if it has our text');

@t = @{ TestApp->object_trackers };

is( scalar(@t), 1, "one tracker" );

$live_objects = $t[0]->live_objects;

is( scalar( keys %$live_objects ), 2, "no leaked objects" );

my $counts = $t[0]->class_counters;

is( $counts->{'class::a'}, 1, 'class::a count correct' );
is( $counts->{'class::b'}, 0, 'class::b count correct' );
is( $counts->{'class::c'}, 1, 'class::c count correct' );
