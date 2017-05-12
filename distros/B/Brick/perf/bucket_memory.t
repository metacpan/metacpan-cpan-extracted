#!/usr/bin/perl
use strict;

use Benchmark;

print STDERR "PID $$\n";

use Test::More 'no_plan';

use Devel::Peek qw(Dump);

my $brick_class = $ARGV[0] || 'Brick';

use_ok( $brick_class );

my $brick  = $brick_class->new;
isa_ok( $brick, $brick_class );

my $bucket = $brick->bucket_class->new;
isa_ok( $bucket, $brick->bucket_class );

<STDIN>;

print STDERR "Making bricks\n";

my $start = Benchmark->new();

foreach ( 1 .. 100000 )
	{
	$bucket->has_file_extension( { extensions => [ qw(txt ttxt text) ] } );
	}

my $end = Benchmark->new();

my $diff = timediff( $end, $start );

print STDERR "Done making bricks\n";

print STDERR "Brick creation took ", timestr( $diff ), "\n";

<STDIN>;
