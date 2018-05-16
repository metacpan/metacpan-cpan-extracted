#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::Filters' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_remove_extra_fields( { filter_fields => [ qw(cat dog bird) ] } );

isa_ok( $sub, ref sub {}, "_remove_extra_fields returns a code ref" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Removes no keys
{
my $input = {
	cat  => "Buster",
	dog  => "Missy",
	bird => "Poppy",
	};

my @keys = keys %$input;

foreach my $k ( @keys )
	{
	ok( exists $input->{$k}, "Key '$k' exists in input" );
	}

my $result = eval { $sub->( $input ) };

foreach my $k ( @keys )
	{
	ok( exists $input->{$k}, "Key '$k' still exists in input" );
	}

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Removes one key
{
my $input = {
	cat  => "Buster",
	dog  => "Missy",
	bird => "Poppy",
	};

my @keys = keys %$input;
my @extra = qw( camel );

@{ $input }{ @extra } = (1) x @extra;

foreach my $k ( @keys, @extra )
	{
	ok( exists $input->{$k}, "Key '$k' exists in input" );
	}

my $result = eval {
	$sub->( $input )
	};

#print Data::Dumper->Dump( [$input], [qw(input)] );

foreach my $k ( @keys )
	{
	ok( exists $input->{$k}, "Key '$k' still exists in input" );
	}

foreach my $k ( @extra )
	{
	ok( ! exists $input->{$k}, "Key '$k' removed from input" );
	}
}
