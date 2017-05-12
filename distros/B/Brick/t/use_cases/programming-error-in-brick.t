#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

=head1 NAME

Brick use case for a programming errors in Bricks

=head1 SYNOPSIS


=head1 DESCRIPTION


If there's a programming error in a brick, such as a dynamic regular
expression that doesn't compile, how should we handle that and what should
show up in the error hash?

=cut

my $class = 'Brick';
use_ok( $class );

my $brick = Brick->new();
isa_ok( $brick, $class );

=head2 Create the constraint

Let's make two constraints that I expect to work, and one that fails from
a programming error.

=cut 

sub Brick::Bucket::code_error {
	my( $bucket, $setup ) = @_;

	$setup->{name} ||= ( caller(0) )[3];
	
	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => 'code_error',
			description => 'Length is 5',
			code        => sub {
				my $regex = "abcd(";
				length $_[0]->{string} == m/$regex/
					or die { message => 'Matches bad regex' };
				}
			} ),
			
		$setup );
	}
	
sub Brick::Bucket::just_fine {
	my( $bucket, $setup ) = @_;

	$setup->{name} ||= ( caller(0) )[3];

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => 'just_fine',
			description => 'Length is 5',
			code        => sub {
				length $_[0]->{string} == 5
					or die { message => 'Length is not five' };
				}
			} ),
			
		$setup );
	}
	
sub Brick::Bucket::never_passes {
	my( $bucket, $setup ) = @_;

	$setup->{name} ||= ( caller(0) )[3];

	$bucket->__make_constraint(
		$bucket->add_to_bucket( {
			name        => 'never_passes',
			description => 'Has a vowel',
			code        => sub {
				die { 
					handler => 'never_passes',
					message => 'Length is not five' 
					};
				}
			} ),
			
		$setup );
		
	}
	
=head2 Create the profile


=cut 

my $Profile = [
	[ fine  => just_fine    => { name => 'foo' } ],
	[ good  => never_passes => {  } ],
	[ error => code_error   => {  } ],
	];

my $profile = Brick->profile_class->new( $brick, $Profile );

$profile->lint;

print $profile->explain;

my $results = $brick->apply( $profile, { string => 'hello' } );

use Data::Dumper;
print Dumper( $results );

print $results->explain;
