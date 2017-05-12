#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    plan skip_all => 'this test needs Test::WWW::Mechanize::Catalyst'
      unless eval "require Test::WWW::Mechanize::Catalyst";
    plan skip_all => 'this test needs Moose'
      unless eval "require Moose";

    plan tests => 49;
}

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

# adaptor
{
    $mech->get_ok('http://localhost/adaptor/isa', 'get the class name');
    $mech->content_like(qr/^TestApp::Backend::SomeClass$/,
                        'adapted class is itself');
}

{
    $mech->get_ok('http://localhost/adaptor/id_twice', 'get id_twice');
    my ($a, $b) = split /\|/, $mech->content;
    is $a, $b, 'same instance both times';

    $mech->get_ok('http://localhost/adaptor/id', 'get id');
    is $mech->content, $a, 'same instance for different request';
}

{
    $mech->get_ok('http://localhost/adaptor/foo', 'get foo');
    $mech->content_like(qr/^bar$/, 'got foo = bar');
}

{
    $mech->get_ok('http://localhost/adaptor/count', 'get count');
    my $a = $mech->content;
    $mech->get_ok('http://localhost/adaptor/count', 'get count (+1)');
    my $b = $mech->content;

    is $b, $a+1, 'same instance across requests';
}
{
    $mech->get_ok('http://localhost/adaptor/count_twice', 'get count_twice');
    my ($a, $b) = split/\|/, $mech->content;
    is $a, 3, '3 count for a';
    is $b, 4, '4 count for b';
}

# factory
{
    $mech->get_ok('http://localhost/factory/isa', 'get the class name');
    $mech->content_like(qr/^TestApp::Backend::SomeClass$/,
                        'adapted class is itself');
}

{
    $mech->get_ok('http://localhost/factory/id_twice', 'get id_twice');
    my ($a, $b) = split /\|/, $mech->content;
    is $b, $a+1, 'different instance both times';

    $mech->get_ok('http://localhost/factory/id', 'get id');
    is $mech->content, $b+1, 'same instance for different request too';

}

{
    $mech->get_ok('http://localhost/factory/foo', 'get foo');
    $mech->content_like(qr/^factory$/, 'got foo = factory');
}
{
    $mech->get_ok('http://localhost/factory/count', 'get count');
    my $a = $mech->content;
    $mech->get_ok('http://localhost/factory/count', 'get count (+1)');
    my $b = $mech->content;

    is $a, 1, '1st request for a';
    is $b, 1, '1st request for b too';
}
{
    $mech->get_ok('http://localhost/factory/count_twice', 'get count_twice');
    my ($a, $b) = split/\|/, $mech->content;
    is $a, 1, '1 count for a';
    is $b, 1, '1 count for b too';
}

# per_request
{
    $mech->get_ok('http://localhost/perrequest/isa', 'get the class name');
    $mech->content_like(qr/^TestApp::Backend::SomeClass$/,
                        'adapted class is itself');
}

{
    $mech->get_ok('http://localhost/perrequest/id_twice', 'get id_twice');
    my ($a, $b) = split /\|/, $mech->content;
    is $a, $b, 'same instance both times';

    $mech->get_ok('http://localhost/perrequest/id', 'get id');
    is $mech->content, $a+1, 'different instance for different request';
}

{
    $mech->get_ok('http://localhost/perrequest/foo', 'get foo');
    $mech->content_like(qr/^perrequest$/, 'got foo = perrequest');
}
{
    $mech->get_ok('http://localhost/perrequest/count', 'get count');
    my $a = $mech->content;
    $mech->get_ok('http://localhost/perrequest/count', 'get count (+1)');
    my $b = $mech->content;

    is $a, 1, '1st request for a';
    is $b, 1, '1st request for b too';
}
{
    $mech->get_ok('http://localhost/perrequest/count_twice', 'get count_twice');
    my ($a, $b) = split/\|/, $mech->content;
    is $a, 1, '1 count for a';
    is $b, 2, '2 count for b';
}

# inner package
{
    $mech->get_ok('http://localhost/innerpackage/isa', 'get the class name');
    $mech->content_like(qr/^TestApp::Backend::InnerPackage::Inner$/,
                        'got the right package for inner class');
}
