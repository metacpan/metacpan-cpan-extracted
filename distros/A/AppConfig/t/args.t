#!/usr/bin/perl -w
#========================================================================
#
# t/args.t 
#
# AppConfig::Args test file.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#------------------------------------------------------------------------
# TODO
# * test PEDANTIC option
#
#========================================================================

use lib qw( ../lib ./lib );
use strict;
use vars qw($loaded);
use AppConfig qw(:argcount);
use AppConfig::Args;
use Test::More tests => 17;

ok(1, 'loaded');


#------------------------------------------------------------------------
# create new AppConfig::State and AppConfig::Args objects
#------------------------------------------------------------------------

my $default = "<default>";
my $anon    = "<anon>";
my $user    = "Fred Smith";
my $age     = 42;
my $notarg  = "This is not an arg";

my $state = AppConfig::State->new({
        GLOBAL => { 
            DEFAULT  => $default,
            ARGCOUNT => ARGCOUNT_ONE,
        } 
    },
    'verbose' => {
        DEFAULT  => 0,
        ARGCOUNT => ARGCOUNT_NONE,
        ALIAS    => 'v',
    },
    'user' => {
        ALIAS    => 'u|name|uid',
        DEFAULT  => $anon,
    },
    'age' => {
        ALIAS    => 'a',
        VALIDATE => '\d+',
    });

my $cfgargs = AppConfig::Args->new($state);

ok( defined $state, 'defined state' );
ok( defined $cfgargs, 'defined cfgargs' );

my @args = ('-v', '-u', $user, '-age', $age, $notarg);

ok( $cfgargs->parse(\@args), 'parse' );

is( $state->verbose(), 1, 'verbose' );
is( $state->user(), $user, 'user' );
is( $state->age(), $age, 'age' );

is( $args[0], $notarg, 'next arg' );

@ARGV = ('--age', $age * 2, $notarg);
ok( $cfgargs->parse(), 'second parse' );
is( $state->age(), $age * 2, 'second age' );
is( $ARGV[0], $notarg, 'second next arg' );

@ARGV = ('--user=Andy_Wardley', '--age=30');
ok( $cfgargs->parse(), 'third parse' );
is( $state->age(), 30, 'third age' );
is( $state->user(), 'Andy_Wardley', 'third user' );

@ARGV = ('--user', 'Me Again', '--age', '34');
ok( $cfgargs->parse(), 'fourth parse' );
is( $state->age(), 34, 'fourth age' );
is( $state->user(), 'Me Again', 'fourth user' );
