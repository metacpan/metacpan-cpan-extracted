#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use CatalystX::InjectComponent;

BEGIN {
package Model::Banana;

use parent qw/Catalyst::Model/;

package TestCatalyst; $INC{'TestCatalyst.pm'} = 1;

use Catalyst::Runtime '5.70';

use Moose;
BEGIN { extends qw/Catalyst/ }

use Catalyst;

after 'setup_components' => sub {
    my $self = shift;
    CatalystX::InjectComponent->inject( catalyst => __PACKAGE__, component => 'Model::Banana' );
    CatalystX::InjectComponent->inject( catalyst => __PACKAGE__, component => 't::Test::Apple' );
    CatalystX::InjectComponent->inject( catalyst => __PACKAGE__, component => 'Model::Banana', into => 'Cherry' );
    CatalystX::InjectComponent->inject( catalyst => __PACKAGE__, component => 't::Test::Apple', into => 'Apple' );
};

TestCatalyst->config( 'home' => '.' );

TestCatalyst->setup;

}

package main;

use Catalyst::Test qw/TestCatalyst/;

ok( TestCatalyst->controller( $_ ) ) for qw/ Apple t::Test::Apple /;
ok( TestCatalyst->model( $_ ) ) for qw/ Banana Cherry /;
