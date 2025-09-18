#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;
use App::FargateStack::Builder::Utils;
use_ok 'App::FargateStack::Builder::Utils';

my @result = ToCamelCase( [ 'foo_bar', 'baz_qux' ] );
my $result = ToCamelCase( [ 'foo_bar', 'baz_qux' ] );

is_deeply(\@result, [ qw(FooBar BazQux) ], 'WantArray');
is_deeply($result, { foo_bar => 'FooBar', baz_qux => 'BazQux'}, 'not WantArray');

@result = toCamelCase( [ 'foo_bar', 'baz_qux' ] );
$result = toCamelCase( [ 'foo_bar', 'baz_qux' ] );

is_deeply(\@result, [ qw(fooBar bazQux) ], 'wantArray')
  or dmp result => \@result;

is_deeply($result, { foo_bar => 'fooBar', baz_qux => 'bazQux'}, 'not wantArray')
  or dmp result => [ $result ];

@result = ToCamelCase( [ 'foo_bar', 'baz_qux' ], 0 );
$result = ToCamelCase( [ 'foo_bar', 'baz_qux' ], 1 );

is_deeply(\@result, [ qw(FooBar BazQux) ], 'WantArray');
is_deeply($result, { foo_bar => 'FooBar', baz_qux => 'BazQux'}, 'not WantArray');

done_testing;

1;
