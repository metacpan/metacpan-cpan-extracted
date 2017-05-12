#!/usr/bin/perl
# vim:set sw=4 ts=4 ft=perl expandtab:
use warnings;
use strict;

use Test::More tests => 6;
use_ok( 'Etherpad' );
use_ok( 'Term::ReadLine' );
use_ok( 'Config::YAML' );
use_ok( 'URI::Escape' );
use_ok( 'DateTime' );
use_ok( 'Browser::Open' );
