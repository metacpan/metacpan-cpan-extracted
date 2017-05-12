package Brick::Result::Item;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.227';

=encoding utf8

=head1 NAME

Brick::Result::Item - The result from a single profile element

=head1 SYNOPSIS

	use Brick;

	my $result = $brick->apply( $Profile, $Input );

	$result->explain;

=head1 DESCRIPTION

This class provides methods to turn the data structure returned
by apply() into a useable form for particular situations.

=over

=cut

use constant LABEL    => 0;
use constant METHOD   => 1;
use constant RESULT   => 2;
use constant MESSAGES => 3;

=item new( HASH_REF )

Keys:

	label    - the label for the item

	method   - the responsible subroutine

	result   - 1 | 0 | undef (See set_result)

	messages - the error reference that comes back from the brick

=cut

use Data::Dumper;

sub new
	{
	my( $class, @args ) = @_;

	my $hash = { @args };

	my $self = bless [], $class;

	$self->set_label(    $hash->{label}    );
	$self->set_method(   $hash->{method}   );
	$self->set_result(   $hash->{result}   );
	$self->set_messages( $hash->{messages} );

	$self;
	}

=item get_label

=item set_label( STRING )

Get or set the label for the item. This is the label that the profile
object used to mark the item. This joins the items in the results to the
items in the profile.

=cut

sub get_label { $_[0]->[ LABEL ] }

sub set_label { $_[0]->[ LABEL ] = $_[1] }

=item get_method

=item set_method( STRING )

Get or set the method name responsible for the validation. When you need
to track down the subroutine causing the problems, this should be it's
name.

=cut

sub get_method { $_[0]->[ METHOD ] }

sub set_method { $_[0]->[ METHOD ] = $_[1] }

=item get_result

=item set_result( 1 | 0 | undef )

Get or set the result of the element. The result is one of three values
depending on what happened:

	1     - passed
	0     - failed by validation
	undef - failed by program error

=cut

sub get_result { $_[0]->[ RESULT ] }

sub set_result { $_[0]->[ RESULT ] = $_[1] }

=item get_messages

=item set_messages( HASH_REF )

Get or set the message hash for the errors.

=cut

sub get_messages { $_[0]->[ MESSAGES ] }

sub set_messages { $_[0]->[ MESSAGES ] = $_[1] }

=item passed

Returns true if the item passed validation.

=cut

sub passed { !! $_[0]->[ RESULT ] }

=item failed

Returns true if the item failed validation. This ight mean that the
validation fails or that there was a programming error. See
C<is_validation_error> and C<is_code_error>.

=cut

sub failed { ! $_[0]->[ RESULT ]  }

=item is_validation_error

Returns true if the failure was the result of a validation error (so not
a programming error).

=cut

sub is_validation_error { ! $_[0]->[ RESULT ] and defined $_[0]->[ RESULT ] }

=item is_code_error

Returns true if the failure was the result of a programming error (so
not a validation error). In hash from C<get_messages> will have a key
C<program_error> with the value of C<1>, and the C<message> key will
have the program error message.

=cut

sub is_code_error       { ! defined $_[0]->[ RESULT ] }

=back

=head1 TO DO

TBA

=head1 SEE ALSO

L<Brick::Profile>

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
