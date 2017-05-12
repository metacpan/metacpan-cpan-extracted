#!/usr/bin/env perl
#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'MyApp' }

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
