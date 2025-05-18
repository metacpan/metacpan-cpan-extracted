#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/lib";

use Test::More tests => 9;
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok(defined $mech);

$mech->get_ok('http://localhost/form/first');
my @inputs = $mech->grep_inputs( { type => 'text', name => 'first_text' } );
is( scalar @inputs, 1, "form not re-filled");

@inputs = $mech->grep_inputs( { type => 'text', name => 'first_text', value => 'foo' } );
is( scalar @inputs, 0, "form not re-filled");

$mech->get_ok('http://localhost/form/first?first_text=foo');
@inputs = $mech->grep_inputs( { type => 'text', name => 'first_text', value => 'foo' } );
is( scalar @inputs, 1, "form re-filled");

$mech->get_ok('http://localhost/form/first');
$mech->field('first_text', 'banana');
$mech->submit_form_ok(undef, q{submit filled form});
@inputs = $mech->grep_inputs( { type => 'text', name => 'first_text', value => 'banana' } );
is( scalar @inputs, 1, "form re-filled");