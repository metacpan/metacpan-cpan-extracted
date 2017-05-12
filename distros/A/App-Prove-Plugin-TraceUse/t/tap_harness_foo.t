#!/usr/bin/perl

use strict;
use warnings;
use Test::Most tests => 5;

use App::Prove::Plugin::TraceUse;

my $thf = TAP::Harness::FOO->new;

isa_ok( $thf, "TAP::Harness::FOO" );


## test 0
$thf->{collected_dependencies} =
  [
   [qw/Foo::Bar .997/],
   [qw/Foo::Bar .997/],
  ];

$thf->_uniquify_dependencies;

cmp_bag(
        $thf->{collected_dependencies},
        [
         [qw/Foo::Bar .997/],
        ],
        "uniquify dependencies 1"
       );


## test 1
$thf->{collected_dependencies} =
  [
   [qw/Foo::Bar .997/],
   [qw/Foo::Baz .999/],
   [qw/Foo::Bar .997/],
  ];

$thf->_uniquify_dependencies;

cmp_bag(
        $thf->{collected_dependencies},
        [
         [qw/Foo::Bar .997/],
         [qw/Foo::Baz .999/],
        ],
        "uniquify dependencies 2"
       );


## test 2
$thf->{collected_dependencies} =
  [
   [qw/Foo::Bar .997/],
   [qw/Foo::Baz .999/],
   [qw/Foo::Bar .997/],
   [qw/Foo::Bar .999/],
  ];

$thf->_uniquify_dependencies;

cmp_bag(
        $thf->{collected_dependencies},
        [
         [qw/Foo::Bar .999/],
         [qw/Foo::Baz .999/],
        ],
        "uniquify dependencies 3"
       );




## test 3
$thf->{collected_dependencies} =
  [
  ];

$thf->_uniquify_dependencies;

cmp_bag(
        $thf->{collected_dependencies},
        [
        ],
        "uniquify dependencies 4"
       );




done_testing();
