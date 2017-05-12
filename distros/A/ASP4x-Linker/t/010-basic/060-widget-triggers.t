#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

use ASP4x::Linker;

$api->ua->get('/?artists.page_size=10&artists.page_number=4');

my $linker = ASP4x::Linker->new();

my $widget = $linker->add_widget(
  name  => 'artists',
  attrs => [qw( page_number page_size )]
);

ok( $widget, "Got widget" );

# Reset the page number to '1' when the page size is updated:
$widget->on_change( page_size => sub {
  my $s = shift;
  $s->set( page_number => 1 );
});

is( $linker->uri => '/?artists.page_number=4&artists.page_size=10' );
$widget->set( page_size => 20 );
is( $linker->uri => '/?artists.page_number=1&artists.page_size=20' );

