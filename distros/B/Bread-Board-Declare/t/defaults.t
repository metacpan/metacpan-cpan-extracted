#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    ::like(::exception {
        has foo => (
            is      => 'ro',
            isa     => 'Str',
            default => 'OOF',
            value   => 'FOO',
        );
    }, qr/default is not valid when Bread::Board service options are set/,
       "can't set a default when creating a service");

    ::like(::exception {
        has bar => (
            is      => 'ro',
            isa     => 'Str',
            default => sub { 'OOF' },
            value   => 'FOO',
        );
    }, qr/default is not valid when Bread::Board service options are set/,
       "can't set a default when creating a service");

    ::like(::exception {
        has bar2 => (
            is      => 'ro',
            isa     => 'Str',
            builder => '_build_bar2',
            value   => 'FOO',
        );
    }, qr/builder is not valid when Bread::Board service options are set/,
       "can't set a builder when creating a service");

    ::like(::exception {
        has baz => (
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            default => 'OOF',
            value   => 'FOO',
        );
    }, qr/default is not valid when Bread::Board service options are set/,
       "can't set a default when creating a service");

    ::like(::exception {
        has quux => (
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            default => sub { 'OOF' },
            value   => 'FOO',
        );
    }, qr/default is not valid when Bread::Board service options are set/,
       "can't set a default when creating a service");

    ::like(::exception {
        has quux2 => (
            is      => 'ro',
            isa     => 'Str',
            lazy    => 1,
            builder => '_build_quux2',
            value   => 'FOO',
        );
    }, qr/builder is not valid when Bread::Board service options are set/,
       "can't set a builder when creating a service");

    ::like(::exception {
        has quux3 => (
            is         => 'ro',
            isa        => 'Str',
            lazy_build => 1,
            value      => 'FOO',
        );
    }, qr/builder is not valid when Bread::Board service options are set/,
       "can't set lazy_build when creating a service");
}

done_testing;
