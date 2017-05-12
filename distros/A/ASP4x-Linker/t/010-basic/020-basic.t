#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;
use JSON::XS;

my $api; BEGIN { $api = ASP4::API->new }

use_ok('ASP4x::Linker');

BLANK: {
  ok( my $res = $api->ua->get('/'), "GET /" );
  ok( my $info = decode_json($res->content), "JSON is good" );
  is_deeply $info, [
     {
        "widgetA" => {
           "page_size"    => undef,
           "sort_col"     => undef,
           "sort_dir"     => undef,
           "page_number"  => undef
        }
     },
     {
        "widgetB" => {
           "page_size"    => undef,
           "sort_col"     => undef,
           "sort_dir"     => undef,
           "page_number"  => undef
        }
     },
     {
        "widgetC" => {
           "color"  => undef,
           "type"   => undef,
           "size"   => undef
        }
     },
     {
        "widgetD" => {
           "color"  => undef,
           "type"   => undef,
           "size"   => undef
        }
     }
  ], "Data structure looks right";
};

T1: {
  ok( my $res = $api->ua->get('/?widgetA.page_size=1&widgetB.page_size=2&widgetC.color=red&widgetD.size=large'), "GET /" );
  ok( my $info = decode_json($res->content), "JSON is good" );
  is_deeply $info, [
     {
        "widgetA" => {
           "page_size" => 1,
           "sort_col" => undef,
           "sort_dir" => undef,
           "page_number" => undef
        }
     },
     {
        "widgetB" => {
           "page_size" => 2,
           "sort_col" => undef,
           "sort_dir" => undef,
           "page_number" => undef
        }
     },
     {
        "widgetC" => {
           "color" => 'red',
           "type" => undef,
           "size" => undef
        }
     },
     {
        "widgetD" => {
           "color" => undef,
           "type" => undef,
           "size" => 'large'
        }
     }
  ], "Data structure looks right";
};

T2: {
  ok( my $res = $api->ua->get('/?widgetA.page_size=20&widgetA.page_number=40&widgetA.sort_col=name&widgetA.sort_dir=DESC&widgetB.page_size=10&widgetB.page_number=100&widgetB.sort_col=date&widgetB.sort_dir=ASC&widgetC.color=red&widgetC.type=shirt&widgetC.size=small&widgetD.size=large&widgetD.type=hat&widgetD.color=black'), "GET /" );
  ok( my $info = decode_json($res->content), "JSON is good" );
  is_deeply $info, [
     {
        "widgetA" => {
           "page_size"    => 20,
           "sort_col"     => 'name',
           "sort_dir"     => 'DESC',
           "page_number"  => 40
        }
     },
     {
        "widgetB" => {
           "page_size"    => 10,
           "sort_col"     => 'date',
           "sort_dir"     => 'ASC',
           "page_number"  => 100
        }
     },
     {
        "widgetC" => {
           "color"  => 'red',
           "type"   => 'shirt',
           "size"   => 'small'
        }
     },
     {
        "widgetD" => {
           "color"  => 'black',
           "type"   => 'hat',
           "size"   => 'large'
        }
     }
  ], "Data structure looks right";
};


