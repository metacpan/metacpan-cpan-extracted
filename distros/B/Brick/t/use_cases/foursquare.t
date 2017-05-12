#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;

use Carp qw(carp);

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

{
package Brick::Bucket;

sub value_format_by_field_name
	{
	my( $bucket, $setup ) = @_;
	
	my @subs = ();
	
	foreach my $field ( @{ $setup->{allowed_fields} } )
		{
		my $method = "_${field}_format";
		do { carp("Cannot [$method]"); next } unless $bucket->can( $method );
		
		my $blank = $bucket->_is_blank( { field => $field } );
		
		my $sub = $bucket->$method( { %$setup, field => $field } );
		
		my $either = $bucket->__compose_satisfy_any( $blank, $sub );
		
		push @subs, $either;
		}
		
	my $composed = $bucket->__compose_satisfy_all( @subs );
	
	$bucket->__make_constraint( $composed, $setup );
	}
	
sub _postal_code_format
	{
	my( $bucket, $setup ) = @_;
	
	$setup->{exact_length} = 5;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_value_length_is_exactly( $setup ),		
		$bucket->_is_only_decimal_digits( $setup ),
		);
	}
	
sub _whole_number_format
	{
	my( $bucket, $setup ) = @_;
	
	$setup->{exact_length} = 5;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_is_only_decimal_digits( $setup ),
		);
	}
	
sub _birthday_format
	{
	my( $bucket, $setup ) = @_;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_is_YYYYMMDD_date_format( $setup ),
		$bucket->_is_valid_date( $setup ),
		);
	}

sub _anniversary_format
	{
	my( $bucket, $setup ) = @_;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_is_YYYYMMDD_date_format( $setup ),
		$bucket->_is_valid_date( $setup ),
		);
	}

sub _city_format
	{
	my( $bucket, $setup ) = @_;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_is_true( $setup ),
		);
	}

sub _state_format
	{
	my( $bucket, $setup ) = @_;
	
	$setup->{exact_length} = 2;

	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_value_length_is_exactly( $setup ),
		$bucket->_is_valid_date( $setup ),
		);
	}

sub _country_format
	{
	my( $bucket, $setup ) = @_;
	
	my $composed = $bucket->__compose_satisfy_all( 
		$bucket->_is_true( $setup ),
		);
	}

}

=head2 Get some input data

The input is a hash reference. The field names are the keys and their
values are the hash values.

=cut

my $Input = {
	birthday        => 1970010,
	anniversary     => 20010101,
	whole_number    => 123456,
	postal_code     => '14227',
	country         => 'United States',
	state           => 'NY',
	city            => 'Buffalo',
	term            => 3,
	_extra          => 'foo',
	_super_bowl     => 'Da Bears!',
	};

	
=head2 Create the profile

=over 4

=item Get the allowable field names, maybe from a configuration file or a database.
Put the list of allowable fields in the 'allowed_fields'

=cut

my @allowed = grep { ! m/^_/ } keys %$Input;

=item Get the required field names, maybe from a configuration file or a database.
Put the list of required fields in the 'required_fields'. This only accounts for
fields you know are required ahead of time, not fields required based on input
conditions.

=cut

my @required = qw(birthday country state city postal_code);

=back

=cut 

my $setup = {
	allowed_fields  => \@allowed,
	required_fields => \@required,
	};
	
my $Profile = [
	[ allowed_fields   => allowed_fields             => $setup ],
	
	[ required_fields  => required_fields            => $setup ],
	
	[ format_of_values => value_format_by_field_name => $setup ],

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

{
my $string = $profile->explain;
#stderr_like { $string = $profile->explain } qr/Cannot/, 
#	"Error message for input lacking format brick";
ok( $string, "explain() returns something" );

print STDERR "\nExplaining $0 profile:\n", 
	$string if $ENV{DEBUG};
}

=head2 Validate the data with apply()

This isn't a necessary step, but it's nice to know that the profile
makes sense before you actually try to use it. Even if you don't do it
for production code, you might want this step in there so you can turn
it on for debugging.

=cut

my $result = $brick->apply( $profile, $Input );
#stderr_like { $result = $brick->apply( $profile, $Input ) } qr/Cannot/,
#	"Error message for input lacking format brick";

isa_ok( $result, ref [], "Results come back as array reference" );
isa_ok( $result, Brick->result_class, "Results come back as array reference" );
is( scalar @$result, scalar @$Profile, "Results has one element per Profile element" );

print STDERR Data::Dumper->Dump( [$result], [qw(result)] ) if $ENV{DEBUG};

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

exit;

{
my $row = shift @$result;
is( $row->[2], 1, "zip_code passes" );
}

foreach my $row ( @$result )
	{
	is( $row->[2], 0, "$row->[0] fails (as expected)" );
	}