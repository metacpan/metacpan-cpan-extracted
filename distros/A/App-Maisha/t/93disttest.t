#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "require Test::Distribution";
plan skip_all => "Test::Distribution required for testing complete package" if $@;

use App::Maisha;

Test::Distribution->import( distversion => $App::Maisha::VERSION, not => 'pod' );
