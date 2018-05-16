use Test::More 'no_plan';
use strict;

my $class = 'Brick::Bucket';

use_ok( $class );

my $bucket = $class->new;

isa_ok( $bucket, $class );
