#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1 + 1;
use Test::Warnings;

my $module = 'App::Git::Workflow::Pom';
use_ok( $module );
done_testing;
