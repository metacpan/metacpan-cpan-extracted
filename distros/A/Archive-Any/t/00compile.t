#!/usr/bin/perl -w

use Test::More 'no_plan';

use_ok( 'Archive::Any' );
use_ok( 'Archive::Any::Plugin' );
use_ok( 'Archive::Any::Plugin::Zip' );
use_ok( 'Archive::Any::Plugin::Tar' );
