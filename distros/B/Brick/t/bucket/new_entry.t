use Test::More 'no_plan';
use strict;

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new;
isa_ok( $brick, $class );

my $bucket = $brick->bucket_class->new();
isa_ok( $bucket, $brick->bucket_class );


my $entry = $bucket->entry_class->new;

isa_ok( $entry, $bucket->entry_class );
