use strict;
use warnings;

use Test::More 'no_plan';


my $m; BEGIN { use_ok($m = "Catalyst::Plugin::Authentication") }

can_ok( $m, $_ ) for qw/user logout set_authenticated/;
