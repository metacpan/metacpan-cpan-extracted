#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

use_ok('ASP4x::Linker');
use_ok('Router::Generic');



NO_VARS: {

  $api->ua->get('/');
  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );

  is_deeply
    $linker->vars(undef, 1), {
    'widgetB.page_number' => undef,
    'widgetC.type' => undef,
    'widgetD.size' => undef,
    'widgetA.page_size' => undef,
    'widgetB.sort_dir' => undef,
    'widgetC.size' => undef,
    'widgetD.color' => undef,
    'widgetD.type' => undef,
    'widgetA.page_number' => undef,
    'widgetA.sort_col' => undef,
    'widgetB.sort_col' => undef,
    'widgetC.color' => undef,
    'widgetA.sort_dir' => undef,
    'widgetB.page_size' => undef
  }, "Default";


  $linker->widget('widgetA')->set( page_size => 10 );
  is_deeply
    $linker->vars(undef, 1), {
    'widgetB.page_number' => undef,
    'widgetC.type' => undef,
    'widgetD.size' => undef,
    'widgetA.page_size' => 10,
    'widgetB.sort_dir' => undef,
    'widgetC.size' => undef,
    'widgetD.color' => undef,
    'widgetD.type' => undef,
    'widgetA.page_number' => undef,
    'widgetA.sort_col' => undef,
    'widgetB.sort_col' => undef,
    'widgetC.color' => undef,
    'widgetA.sort_dir' => undef,
    'widgetB.page_size' => undef
  }, "widgetA.page_size=10";
};


WITH_VARS: {
  $api->ua->get('/?widgetA.page_size=100');
  my $linker = ASP4x::Linker->new();

  $linker->add_widget(
    name  => "widgetA",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetB",
    attrs => [qw/ page_number page_size sort_dir sort_col /]
  );

  $linker->add_widget(
    name  => "widgetC",
    attrs => [qw/ size type color /]
  );

  $linker->add_widget(
    name  => "widgetD",
    attrs => [qw/ size type color /]
  );

  is_deeply
    $linker->vars(undef, 1), {
    'widgetB.page_number' => undef,
    'widgetC.type' => undef,
    'widgetD.size' => undef,
    'widgetA.page_size' => 100,
    'widgetB.sort_dir' => undef,
    'widgetC.size' => undef,
    'widgetD.color' => undef,
    'widgetD.type' => undef,
    'widgetA.page_number' => undef,
    'widgetA.sort_col' => undef,
    'widgetB.sort_col' => undef,
    'widgetC.color' => undef,
    'widgetA.sort_dir' => undef,
    'widgetB.page_size' => undef
  }, "Default";


  $linker->widget('widgetA')->set( page_size => 10 );
  is_deeply
    $linker->vars(undef, 1), {
    'widgetB.page_number' => undef,
    'widgetC.type' => undef,
    'widgetD.size' => undef,
    'widgetA.page_size' => 10,
    'widgetB.sort_dir' => undef,
    'widgetC.size' => undef,
    'widgetD.color' => undef,
    'widgetD.type' => undef,
    'widgetA.page_number' => undef,
    'widgetA.sort_col' => undef,
    'widgetB.sort_col' => undef,
    'widgetC.color' => undef,
    'widgetA.sort_dir' => undef,
    'widgetB.page_size' => undef
  }, "widgetA.page_size=10";
};


