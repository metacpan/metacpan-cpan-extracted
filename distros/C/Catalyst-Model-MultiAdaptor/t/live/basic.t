#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/../lib";

BEGIN {
    plan skip_all => 'this test needs Test::WWW::Mechanize::Catalyst'
      unless eval "require Test::WWW::Mechanize::Catalyst";
    plan tests => 10;
}

# make sure testapp works
use_ok 'TestApp::Web';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp::Web';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost:3000/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

# adaptor
{
    $mech->get_ok('http://localhost:3000/multiadaptor/isa', 'get the class name');
    $mech->content_like(qr/^TestApp::Service::SomeClass$/,
                        'adapted class is itself');
}

# logic and lifecycle
{
    $mech->get_ok('http://localhost/multiadaptor/counter', 'get count');
    my $a = $mech->content;
    $mech->get_ok('http://localhost/multiadaptor/counter', 'get count (+1)');
    my $b = $mech->content;

    is $b, $a+1, 'same instance across requests';
}

# config
{
    $mech->get_ok('http://localhost/multiadaptor/uid', 'get uid');
    is $mech->content, 1, 'got uid is expected one';
}

done_testing;
