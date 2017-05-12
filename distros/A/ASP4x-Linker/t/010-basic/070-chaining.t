#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;
use ASP4x::Linker;

my $api = ASP4::API->new();

$api->ua->get('/?artists.page_size=10&artists.page_number=4');

my $linker = ASP4x::Linker->new();

my $widget = $linker->add_widget(
  name  => 'artists',
  attrs => [qw( page_number page_size )]
);

my $uri = $widget->set(page_number => 1, page_size => 2)->uri();
is( $uri => '/?artists.page_number=1&artists.page_size=2' );


