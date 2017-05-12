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

my $sub = $bucket->_fields_are_defined_and_not_null_string( 
	{
	fields => [ qw(one two red blue false) ],
	}
	);
isa_ok( $sub, ref sub {}, "_fields_are_defined_and_not_null_string returns a code ref" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# All the fields have values. Zero field is okay.
{
my $sub = $bucket->_fields_are_defined_and_not_null_string( 
	{
	fields => [ qw(one two red blue false) ],
	}
	);
isa_ok( $sub, ref sub {}, "_fields_are_defined_and_not_null_string returns a code ref" );

my $input = { map { $_, 1 } qw(one two red blue) };
$input->{false} = 0;


my $result = eval {  $sub->( $input )  }; 
my $at = $@;
#print STDERR Data::Dumper->Dump( [$result], [qw(result)] );

ok( $result, "Result passes (as expected)" );
diag( "Eval error: $at" ) unless defined $result;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Extra fields are there
{
my $sub = $bucket->_fields_are_defined_and_not_null_string( 
	{
	fields => [ qw(one two red blue empty undefined) ],
	}
	);
isa_ok( $sub, ref sub {}, "_fields_are_defined_and_not_null_string returns a code ref" );

my $input = { map { $_, 1 } qw(one two red blue cat bird) };

$input->{empty}     = '';
$input->{undefined} = undef;
#print STDERR Data::Dumper->Dump( [$input], [qw(input)] );

my $result = eval { $sub->( $input ) }; 
my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in \$@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
#diag( "Eval error: " . Data::Dumper->Dump( [$@], [qw(@)] ) ) unless defined $result;
}