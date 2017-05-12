#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

my $m;
BEGIN { use_ok($m = "Catalyst::Plugin::Authentication::Credential::PAM") }
can_ok( $m, 'login' );
