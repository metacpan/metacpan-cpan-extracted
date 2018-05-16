#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

my $class = 'Brick';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
my $message = "Foo bar";
eval { $class->error( $message ) };

like( $@, qr/\A\Q$message\E/, "Error message is in \$@" );
is( $class->error_str, $message, "Error message comes back right" );
