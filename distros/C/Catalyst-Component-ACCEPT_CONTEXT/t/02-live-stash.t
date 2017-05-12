# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 3;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Catalyst::Test qw(TestApp);

is( get('/stash'), 'it worked', q{stashing works} );
is( get('/cycle'), '1', 'no cycles');
is( get('/weak_cycle'), '1', 'found weak cycle');
