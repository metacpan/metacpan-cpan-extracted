#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $false_sub = sub { 0 };
my $true_sub  = sub { 1 };
my $undef_sub = sub { return };
my $die_sub   = sub { die {
	handler => 'die_sub',
	message => 'I die for no good reason other than I like it',
	} };

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $sub = $bucket->__compose_satisfy_N_to_M( 0, 1, $true_sub );
isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a hash ref" );

my $result = eval { $sub->({}) };
is( $result, 1, "Satisfied zero or one true test" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $sub = $bucket->__compose_satisfy_N_to_M( 1, 1, $true_sub );
isa_ok( $sub, ref sub {}, "'code' key has a sub reference in it" );

my $result = eval { $sub->({}) };
is( $result, 1, "Satisfied exactly one true test" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $sub = $bucket->__compose_satisfy_N_to_M( 2, 2, $true_sub );
isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a code ref" );

my $result = eval { $sub->({}) };
my $at = $@;
#print STDERR Data::Dumper->Dump( [$at], [qw(at)] );

ok( ! defined $result, "Couldn't satisfy two true test with one sub" );
isa_ok( $at, ref {}, "death returns a hash ref in \$@" );
#diag( $at->{message} );
    ok( exists $at->{handler},  "hash ref has a 'handler' key" );
    ok( exists $at->{message},  "hash ref has a 'message' key" );
    ok( exists $at->{errors},   "hash ref has a 'errors' key" );
isa_ok( $at->{errors},  ref [], "'errors' key is an anonymous array" );
is( scalar @{$at->{errors}}, 0, "'errors' key is an anonymous array with no elements" );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $sub = $bucket->__compose_satisfy_N_to_M( 2, 2, $true_sub, $false_sub );
isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a code ref" );

my $result = eval { $sub->({}) };
my $at = $@;

is( $result, 1, "Satisfied exactly one true test" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @subs = ( $die_sub, $true_sub, $false_sub  );

foreach my $sub ( @subs ) { isa_ok( $sub, ref sub {} ) }

my $sub = $bucket->__compose_satisfy_N_to_M( 3, 3, @subs );
isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a code ref" );

my $result = eval { $sub->({}) };
my $at = $@;

#print STDERR Data::Dumper->Dump( [$at], [qw(at)] );

ok( ! defined $result, "Satisfied three true test (with one die)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
#diag( $at->{message} );
    ok( exists $at->{handler},  "hash ref has a 'handler' key" );
    ok( exists $at->{message},  "hash ref has a 'message' key" );
    ok( exists $at->{errors},   "hash ref has a 'errors' key" );
isa_ok( $at->{errors},  ref [], "'errors' key is an anonymous array" );
is( scalar @{$at->{errors}}, 1, "'errors' key is an anonymous array with one element" );
}
