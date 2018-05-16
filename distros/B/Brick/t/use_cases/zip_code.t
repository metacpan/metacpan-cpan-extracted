#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

=head1 NAME

Brick US Zip Code Use Case

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


=back

=cut

sub Brick::Bucket::is_US_zip_code
	{
	my( $bucket, $setup ) = @_;

	$setup->{exact_length} = 5;

	my $composed = $bucket->__compose_satisfy_all(
		$bucket->_value_length_is_exactly( $setup ),
		$bucket->_is_only_decimal_digits( $setup ),
		);

	$bucket->__make_constraint( $composed, $setup );
	}

=head2 Create the profile


=cut

my $Profile = [
	[ zip_code        => is_US_zip_code => { field => 'zip_code',       } ],
	[ short_zip_code  => is_US_zip_code => { field => 'short_zip_code'  } ],
	[ long_zip_code   => is_US_zip_code => { field => 'long_zip_code'   } ],
	[ letter_zip_code => is_US_zip_code => { field => 'letter_zip_code' } ],
	];

=head2 Test the profile with lint()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

my $lint = $brick->profile_class->lint( $Profile );
is( $lint, 0, "Profile has no errors" );

=head2 Make the profile object


=cut

my $profile = $brick->profile_class->new( $brick, $Profile );
isa_ok( $profile, $brick->profile_class );

=head2 Dump the profile with explain()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

print STDERR "\nExplaining zip code profile:\n",
	$profile->explain if $ENV{DEBUG};

=head2 Get some input data

The input is a hash reference. The field names are the keys and their
values are the hash values.

=cut

my $Input = {
	zip_code        => 14201,
	short_zip_code  => 4201,
	long_zip_code   => 123456,
	letter_zip_code => 'Grover',
	};

=head2 Validate the data with apply()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

my $result = $brick->apply( $profile, $Input );

=head2 Check the results

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

#print STDERR Data::Dumper->Dump( [$result], [qw(result)] ) ; #if $ENV{DEBUG};
use Data::Dumper;

print STDERR "\n" if $ENV{DEBUG};

foreach my $index ( 0 .. $#$result )
	{
	my $entry = $result->[$index];

	print STDERR "----- $entry->[0] ----------------------------\n" if $ENV{DEBUG};

	do { print STDERR "\tpassed\n\n" if $ENV{DEBUG}; next } if $entry->passed;

	my @data = ( $entry->get_messages );
	my @errors = ();
	my $iterations = 0;
	while( my $error = shift @data )
		{
		last if $iterations++ > 20; # debugging guard against infinity
#		print STDERR "Iteration $iterations\n";
		if( $error->{handler} =~ m/^__/ )
			{
			push @data, @{ $error->{errors} };
			next;
			}

		push @errors, $error;
		}

	#print STDERR Data::Dumper->Dump( [\@errors], [qw(errors)] ) ; #if $ENV{DEBUG};

	#print STDERR "$entry->[0] checked by $entry->[1] which returned:\n\t$message\n";

	next unless ref $entry->get_messages and @{ $entry->get_messages->{errors} } > 0;

	foreach my $error ( @errors )
		{
		print STDERR "$error->{handler}: $error->{message}\n" if $ENV{DEBUG};
		}

	print STDERR "\n" if $ENV{DEBUG};
	}

{
my $row = shift @$result;
is( $row->passed, 1, "zip_code passes" );
}

foreach my $row ( @$result )
	{
	is( $row->is_validation_error, 1, "$row->[0] fails (as expected)" );
	}
