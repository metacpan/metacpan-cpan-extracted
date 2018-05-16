#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

=head1 NAME

Brick use case to allow user defined names to make explain() output better

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

my $class = 'Brick';
use_ok( $class );

my $brick = Brick->new();
isa_ok( $brick, $class );

=head2 Create the constraint

=over 4

=item Input

=item Add to input hash

=item Get the pieces to test each condition

=item Compose the pieces

=item Turn the composition into a constraint

Most bricks that come with this module simply use their subroutine name
for the brick they add to the bucket.

To get around this, supply a C<name> parameter to the

=back

=cut

sub Brick::Bucket::odd_even_alternates
	{
	my( $bucket, $setup ) = @_;

	$setup->{exact_length} = 9;
	$setup->{filter_fields} = [ qw(number) ];

	my $filter = $bucket->_remove_non_digits( $setup );

	$setup->{regex} = qr/
		\A
		[13579]?          #maybe it starts with an odd
		([02468][13579])+ # even - odd pairs
		[02468]?          #maybe it ends with an even
		\z
		/x;

	my $sub = $bucket->_matches_regex(
		{ %$setup, name => 'Odd-Even regex test'}
		);

	$setup->{name} = "Odd-Even regex test";

	my $composed = $bucket->__compose_satisfy_all(
		$filter, $sub
		);


	$bucket->__make_constraint( $composed, $setup );
	}

=head2 Create the profile


=cut

my $Profile = Brick::Profile->new( $brick, [
	[ short       => odd_even_alternates => { field => 'short_number'  } ],
	[ long        => odd_even_alternates => { field => 'long_number'   } ],
	[ medium      => odd_even_alternates => { field => 'medium_number' } ],
	[ should_fail => odd_even_alternates => { field => 'bad_number'    } ],
	] );

=head2 Test the profile with lint()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

my $lint = $Profile->lint;
unless( is( !! $lint, !! 0, "Profile has no errors" ) )
	{
	my %lint = $Profile->lint;

 	diag( Data::Dumper->Dumper( \%lint ) );
 	}

=head2 Dump the profile with explain()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

print STDERR "\nExplaining odd-even alternation profile:\n",
	$Profile->explain if $ENV{DEBUG};

