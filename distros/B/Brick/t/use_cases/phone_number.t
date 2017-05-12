#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';

=head1 NAME

Brick Local US Phone Number Use Case

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

sub Brick::Bucket::is_US_local_phone_number
	{
	my( $bucket, $setup ) = @_;
	
	$setup->{exact_length} = 7; # without separator

	$setup->{filter_fields}        = [ $setup->{field} ];
	
	$setup->{regex}         = qr/
		\A 
		(?:\d\d\d)   # prefix
		(?:\d\d\d\d) # number
		\z
		/x;

	my $composed = $bucket->__compose_satisfy_all(
		$bucket->_remove_non_digits( $setup ),
		$bucket->_value_length_is_exactly( $setup ),		
		$bucket->_matches_regex( $setup ),
		);
	
	$bucket->__make_constraint( $composed, $setup );
	}
	
=head2 Create the profile


=cut 

my $Profile = [
	[ phone        => is_US_local_phone_number => { field => 'phone',       } ],
	[ space_phone  => is_US_local_phone_number => { field => 'space_phone', } ],
	[ dot_phone    => is_US_local_phone_number => { field => 'dot_phone',   } ],
	[ short_phone  => is_US_local_phone_number => { field => 'short_phone'  } ],
	[ long_phone   => is_US_local_phone_number => { field => 'long_phone'   } ],
	[ letter_phone => is_US_local_phone_number => { field => 'letter_phone' } ],
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
	phone        => 5551234,
	space_phone  => "555 1234",
	dot_phone    => "555.1234",
	short_phone  => 555123,
	long_phone   => 8005551212,
	letter_phone => '1234567',
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

print STDERR "\n"  if $ENV{DEBUG};

foreach my $index ( 0 .. $#$result )
	{
	my $entry = $result->[$index];
	
	print STDERR "----- $entry->[0] ----------------------------\n" if $ENV{DEBUG};
	
	do { print STDERR "\tpassed\n\n" if $ENV{DEBUG}; next } if $entry->[2];
	
	my @data = ( $entry->[3] );
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
	
	next unless ref $entry->[3] and @{ $entry->[3]{errors} } > 0;
	
	foreach my $error ( @errors )
		{
		print STDERR "$error->{handler}: $error->{message}\n" if $ENV{DEBUG};
		}
	
	print STDERR "\n" if $ENV{DEBUG};
	}

foreach my $row ( splice @$result, 0, 3 )
	{
	is( $row->[2], 1, "$row->[0] passes" );
	}

exit;

foreach my $row ( @$result )
	{
	is( $row->[2], 0, "$row->[0] fails (as expected)" );
	}
