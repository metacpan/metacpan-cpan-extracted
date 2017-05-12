package Brick::General;
use strict;

use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

use Carp qw(croak confess);

=encoding utf8

=head1 NAME

Brick::General - constraints for domain-nonspecific stuff

=head1 SYNOPSIS

	use Brick;

=head1 DESCRIPTION

=head2 Single fields

=over 4

=item _is_blank( HASHREF )


=cut

sub _is_blank
	{
	my( $bucket, $setup ) = @_;

	$setup->{fields} = [ $setup->{field} ];

	$bucket->_fields_are_blank( $setup );
	}

=item _is_true( HASHREF )


=cut

sub _is_true
	{
	my( $bucket, $setup ) = @_;

	$setup->{fields} = [ $setup->{field} ];

	$bucket->_fields_are_true( $setup );
	}


=item _is_defined( HASHREF )


=cut

sub _is_defined
	{
	my( $bucket, $setup ) = @_;

	$setup->{fields} = [ $setup->{field} ];

	$bucket->_fields_are_defined( $setup );
	}

=back

=head2 Multiple field conditions

=over 4

=item defined_fields( HASHREF )

A wrapper around __fields_are_something to supply the code reference
to verify that each field for definedness. It takes the same input.

=cut


sub defined_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_are_defined( $setup );
	$bucket->__make_constraint( $sub, $setup );
	}

=item true_fields( HASHREF )

A wrapper around __fields_are_something to supply the code reference
to verify that each field for true values. It takes the same input.

=cut

sub true_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_are_true( $setup );
	$bucket->__make_constraint( $sub, $setup );
	}

=item false_fields( HASHREF )

A wrapper around __fields_are_something to supply the code reference
to verify that each field for false values. It takes the same input.

=cut

sub false_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_are_false( $setup );
	$bucket->__make_constraint( $sub, $setup );
	}

=item blank_fields( HASHREF )

A wrapper around __fields_are_something to supply the code reference
to verify that each field has blank values. It takes the same input.

=cut

sub blank_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_are_blank( $setup );
	$bucket->__make_constraint( $sub, $setup );
	}

=item exist_fields( HASHREF )

A wrapper around __fields_are_something to supply the code reference
to verify that each field has blank values. It takes the same input.

=cut

sub exist_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_exist( $setup );
	$bucket->__make_constraint( $sub, $setup );
	}

=item allowed_fields( HASHREF )

A wrapper around _remove_extra_fields to remove anything not in the
list of the key 'allowed_fields' in HASHREF.

This constraint only cares about fields that do not belong in the
input. It does not, for instance, ensure that all the fields that
should be there are. Use required fields for that.

=cut

sub allowed_fields
	{
	my( $bucket, $setup ) = @_;

	my $filter_sub = $bucket->_remove_extra_fields(
		{
		%$setup,
		filter_fields => $setup->{allowed_fields}
		}
		);

	$bucket->__make_constraint( $filter_sub, $setup );
	}

=item required_fields( HASHREF )

A wrapper around _fields_are_defined_and_not_null_string to check for
the presence of the required fields. A required field must exist in
the input hash and have a defined value that is not the null string.

=cut

sub required_fields
	{
	my( $bucket, $setup ) = @_;

	my $sub = $bucket->_fields_are_defined_and_not_null_string(
		{
		%$setup,
		fields => $setup->{required_fields},
		}
		);

	$bucket->__make_constraint( $sub, $setup );
	}

=item _fields_exist( HASHREF )

	fields  - an anonymous array of fields that must exist in input

If all of the fields satisfy the condition, it does not die. If some of the
fields do not satisfy the condition, it dies with a hash reference whose keys
are:

	message - message about the error
	errors  - anonymous array of fields that failed the condition
	handler - anonymous array of fields that satisfy the condition

If a code error occurs, it dies with a simple scalar.

=cut

sub _fields_exist
	{
	my( $bucket, $setup, $sub ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	#print STDERR Data::Dumper->Dump( [\@caller], [qw(caller)] );

	unless( eval { $setup->{fields}->isa( ref [] ) } or
		UNIVERSAL::isa( $setup->{fields}, ref [] ) )
		{
		croak( "Argument to $caller[0]{'sub'} must be an anonymous array of field names!" );
		}

	my $composed = $bucket->add_to_bucket ( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => ( $setup->{description} || "Fields exist" ),
		fields      => [ $setup->{fields} ],
		code        => sub {
			my @errors;
			my @missing;
			foreach my $f ( @{ $setup->{fields} } )
				{
				next if exists $_[0]->{ $f };

				push @errors, {
					handler => $caller[1]{'sub'} || $caller[0]{'sub'},
					message => "Field [$f] was not in input",
					};

				push @missing, $f;
				}

			die {
				message  => "These fields were missing in the input: [@missing]",
				errors   => \@errors,
				handler  => $caller[1]{'sub'} || $caller[0]{'sub'},
				} if @missing;
			},
		} );

	$bucket->comprise( $composed, $sub );

	$composed;
	}

=item __fields_are_something( HASHREF, CODEREF )

Applies CODEREF to all of the fields in HASHREF->{fields}.

	fields      - an anonymous array of fields to apply CODEREF to
	description - a textual description of the test (has default)
	test_name   - short (couple word) description of test (e.g. "defined")

If all of the fields satisfy the condition, it does not die. If some of the
fields do not satisfy the condition, it dies with a hash reference whose keys
are:

	message - message about the error
	errors  - anonymous array of fields that failed the condition
	handler - anonymous array of fields that satisfy the condition

If a code error occurs, it dies with a simple scalar.

=cut

sub __fields_are_something
	{
	my( $bucket, $setup, $sub ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	unless( eval { $setup->{fields}->isa( ref [] ) } or
		UNIVERSAL::isa( $setup->{fields}, ref [] ) )
		{
		croak( "Argument to $caller[0]{'sub'} must be an anonymous array of field names!" );
		}

	my $composed = $bucket->add_to_bucket ( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => ( $setup->{description} || "Fields exist" ),
		fields      => [ $setup->{fields} ],
		code        => sub {

			#print STDERR Data::Dumper->Dump( [$_[0]], [qw(input)] );
			my @errors;
			my @bad;
			foreach my $f ( @{ $setup->{fields} } )
				{
				no warnings 'uninitialized';
				#print STDERR "Checking field $f ... ";
				my $result = $sub->( $_[0]->{$f} );
				#print STDERR "$result\n";
				my $at = $@;

				push @errors, {
					handler => $caller[1]{'sub'},
					message => "Field [$f] was not $setup->{test_name}. It was [$_[0]->{$f}]",
					} unless $result;

				push @bad, $f unless $result;
				}

			die {
				message  => "Not all fields were $setup->{test_name}: [@bad]",
				errors   => \@errors,
				handler  => $caller[0]{'sub'},
				} if @bad;

			return 1;
			},
		} );

	$bucket->comprise( $composed, $sub );

	$composed;
	}

=item _fields_are_defined_and_not_null_string( HASHREF )

Check that all fields in HASHREF->{fields) are defined and
have a true value. See __fields_are_something for details.

=cut

sub _fields_are_defined_and_not_null_string
	{
	my( $bucket, $setup ) = @_;

	#print STDERR "_fields_are_defined_and_not_null_string: ", Data::Dumper->Dump( [$setup], [qw(setup)] );

	$setup->{test_name} = 'defined but not null';

	$bucket->__fields_are_something( $setup, sub { defined $_[0] and $_[0] ne '' } );
	}


=item _fields_are_defined( HASHREF )

Check that all fields in HASHREF->{fields) are defined. See
__fields_are_something for details.

=cut

sub _fields_are_defined
	{
	my( $bucket, $setup ) = @_;

	$setup->{test_name} = 'defined';

	$bucket->__fields_are_something( $setup, sub { defined $_[0] } );
	}

=item _fields_are_blank( HASHREF )

Check that all fields in HASHREF->{fields) are blank (either
undefined or the empty string). See __fields_are_something for details.

=cut

sub _fields_are_blank
	{
	my( $bucket, $setup ) = @_;

	$setup->{test_name} = 'blank';

	$bucket->__fields_are_something( $setup, sub { ! defined $_[0] or $_[0] eq ''  } );
	}

=item _fields_are_false( HASHREF )

Check that all fields in HASHREF->{fields) are false (in the Perl
sense). See __fields_are_something for details.

=cut

sub _fields_are_false
	{
	my( $bucket, $setup ) = @_;

	$setup->{test_name} = 'false';

	$bucket->__fields_are_something( $setup, sub { ! $_[0]  } );
	}

=item _fields_are_true( HASHREF )

Check that all fields in HASHREF->{fields) are true (in the Perl
sense). See __fields_are_something for details.

=cut

sub _fields_are_true
	{
	my( $bucket, $setup ) = @_;

	$setup->{test_name} = 'true';

	$bucket->__fields_are_something( $setup, sub { $_[0] } );
	}

=back

=head1 TO DO

TBA

=head1 SEE ALSO

TBA

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
