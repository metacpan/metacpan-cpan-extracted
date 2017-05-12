#!/usr/bin/perl

package Test;

use Attribute::Method::Tags;

sub foo : Tags( quick fast ) {}

sub bar : Tags( quick ) {}

sub baz : Tags( loose ) {}

sub wibble {};

package Test2;

use Attribute::Method::Tags;

sub foo : Tags( loose ) {};

package main;

use strict;
use warnings;

use Test::More tests => 18;
use Attribute::Method::Tags::Registry;

isa_ok( $_, 'Attribute::Method::Tags' ) foreach qw( Test );

my @tags = Attribute::Method::Tags::Registry->tags;
is_deeply( \@tags, [ qw( fast loose quick ) ], "expected list of defined tags" );

# classes_with_tag test
{
    my %expected = (
        quick   => [ qw( Test ) ],
        fast    => [ qw( Test ) ],
        loose   => [ qw( Test Test2 ) ],
        fee     => [ qw( ) ],
    );

    my %actual;
    foreach my $tag ( @tags, 'fee' ) {
        my @classes = Attribute::Method::Tags::Registry->classes_with_tag( $tag );

        $actual{ $tag } = \@classes;
    }

    is_deeply( \%actual, \%expected, "expected list of classes for 'classes_with_tag' calls" );
}

# error tests for classes_with_tag
{
    eval {
        Attribute::Method::Tags::Registry->classes_with_tag( undef );
    };
    like(
        $@,
        qr/^no tag specified/,
        "expected error with undef passed to classes_with_tag"
    );
}

# methods_with_tag tests
{
    my %expected = (
        Test    => {
            quick   => [ qw( bar foo ) ],
            fast    => [ qw( foo ) ],
            loose   => [ qw( baz ) ],
            fee     => [ qw( ) ],
        },
        Test2   => {
            quick   => [ qw( ) ],
            fast    => [ qw( ) ],
            loose   => [ qw( foo ) ],
            fee     => [ qw( ) ],
        },
    );

    my $actual;
    foreach my $class ( qw( Test Test2 ) ) {
        foreach my $tag ( @tags, 'fee' ) {
            my @methods = Attribute::Method::Tags::Registry->methods_with_tag( $class, $tag );

            $actual->{ $class }{ $tag } = \@methods;
        }
    }
    is_deeply( $actual, \%expected, "expected list of methods for 'methods_with_tag' calls" );
}

# error tests for classes_with_tag
{
    my @tests = (
        {
            name        => 'empty param list',
            params      => [],
            expected    => qr/^no class specified/,
        },
        {
            name        => 'undef class',
            params      => [ undef, 'quick' ],
            expected    => qr/^no class specified/,
        },
        {
            name        => 'no tag',
            params      => [ 'Test' ],
            expected    => qr/^no tag specified/,
        },
        {
            name        => 'undef tag',
            params      => [ 'Test', undef ],
            expected    => qr/^no tag specified/
        },
    );

    foreach my $test ( @tests ) {
        my ( $name, $params, $expected ) =
          @{ $test }{ qw( name params expected ) };

        eval {
            Attribute::Method::Tags::Registry->methods_with_tag( @$params );
        };
        like(
            $@,
            $expected,
            "expected error for methods_with_tag when $name"
        );
    }
}

# tests against Test class for method_has_tag
{
    my @tests = (
        {
            name        => 'method has tag',
            method      => 'foo',
            tag         => 'quick',
            expected    => 1,
        },
        {
            name        => "method doesn't have tag",
            method      => 'foo',
            tag         => 'loose',
            expected    => 0,
        },
        {
            name        => 'method has no tags',
            method      => 'wibble',
            tag         => 'quick',
            expected    => 0,
        },
    );

    foreach my $test ( @tests ) {
        my ( $name, $tag, $method, $expected )
          = @{ $test }{ qw( name tag method expected ) };

        my $actual = Attribute::Method::Tags::Registry->method_has_tag(
            'Test',
            $method,
            $tag,
        );

        is(
            $actual,
            $expected,
            "expected result for method_has_tag when $name"
        );
    }
}

# error tests for method_has_tag
{
    my @tests = (
        {
            name        => 'empty param list',
            params      => [],
            expected    => qr/^no class specified/,
        },
        {
            name        => 'undef class',
            params      => [ undef, 'foo', 'quick' ],
            expected    => qr/^no class specified/,
        },
        {
            name        => 'no method',
            params      => [ 'Test' ],
            expected    => qr/^no method specified/,
        },
        {
            name        => 'undef method',
            params      => [ 'Test', undef, 'quick' ],
            expected    => qr/^no method specified/
        },
        {
            name        => 'no tag',
            params      => [ 'Test', 'foo' ],
            expected    => qr/^no tag specified/,
        },
        {
            name        => 'undef tag',
            params      => [ 'Test', 'foo', undef ],
            expected    => qr/^no tag specified/,
        },
    );

    foreach my $test ( @tests ) {
        my ( $name, $params, $expected ) =
          @{ $test }{ qw( name params expected ) };

        eval {
            Attribute::Method::Tags::Registry->method_has_tag( @$params );
        };
        like(
            $@,
            $expected,
            "expected error for methods_with_tag when $name"
        );
    }
}
