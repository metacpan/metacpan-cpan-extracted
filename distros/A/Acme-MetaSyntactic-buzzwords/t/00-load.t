#!perl
#
# This file is part of Acme::MetaSyntactic::buzzwords.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Test::More tests => 1;

BEGIN { use_ok( 'Acme::MetaSyntactic::buzzwords' ); }
my $version = $Acme::MetaSyntactic::buzzwords::VERSION;
diag( "Testing Acme::MetaSyntactic::buzzwords $version, Perl $], $^X" );

exit;
