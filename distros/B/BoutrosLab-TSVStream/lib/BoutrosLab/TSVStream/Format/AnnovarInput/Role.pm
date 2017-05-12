# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::AnnovarInput::Role

=head1 SYNOPSIS

Collection of roles that implement AnnovarInput format capable objects.
This role provides the common attributes for AnnovarInput format, but there
are sub-roles to specify the various restrictions for the B<chr>
attribute.

=head1 DESCRIPTION

To create a new sub-role (<XXX>), extend the type categories in the
BoutrosLab::TSVStream::Format::AnnovarInput::Types module to provide a type
that restricts the chr field appropriately, and define a role module
that applies that type to the B<chr> attribute.

Look at the definition of the Human type in this role.

To use one of these roles to define an object B<XXX>:

	package BoutrosLab::TSVStream::Format::AnnovarInput::<XXX>::Fixed;
	use Moose;

	with qw(
		BoutrosLab::TSVStream::Format::AnnovarInput::Role
		BoutrosLab::TSVStream::Format::AnnovarInput::Role::<XXX>
		BoutrosLab::TSVStream::IO::Role::Fixed
		);

(Replace 'Fixed' with 'Dyn' in the package name and in the 'with ...
BoutrosLab::TSVStream::IO::Role::Fixed' if you want the object to have
a group of dynamic fields in addition to the standard AnnovarInput attributes.)

See BoutrosLab::TSVStream::Format::Human::Fixed for an example.

=cut

package BoutrosLab::TSVStream::Format::AnnovarInput::Role;

use Moose::Role;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw( AI_Ref );
use BoutrosLab::TSVStream::Format::VCF::Types qw( VCF_Alt );
use MooseX::Types::Moose qw( ArrayRef Int );
use MooseX::ClassAttribute;
use namespace::autoclean;

=head1 Class Attributes

=head2 _fields

The B<_fields> attribute is required by the IO roles to determine
which fields are to be read or written.  In this case, the fields
are C<chr>, C<start>, C<end>, C<ref>, and C<alt>, which are described
as attributes below.

=cut

class_has '_fields' => (
	is => 'ro',
	isa => ArrayRef,
	default => sub { [qw(chr start end ref alt)] }
	);

=head1 Attributes

=head2 chr

The B<chr> attribute provides the name of the chromosome that is
being specified.  There are different names used for different
species of organism; and for different ways of processing the same
organism; so this attribute is provided in a separate role.

=head2 start

=head2 end

The B<start> and B<end> attributes are integers that provide the start
and end position within the chromosome that is being described.

=cut

has 'start' => ( is => 'rw', isa => Int );
has 'end'   => ( is => 'rw', isa => Int );

=head2 ref

=head2 alt

The B<ref> and B<alt> attributes describe amino acid sequences.
They can either contain the string I<'-'>, or a sequence of acids
(C<'A'>, C<'C'>, C<'G'>, and C<'T'> of at most 500 acids.  (E.G.:
CGATCGAT)

=cut

has 'ref' => ( is => 'rw', isa => AI_Ref );
has 'alt' => ( is => 'rw', isa => VCF_Alt );

=head1 SUBROLES

=head2 BoutrosLab::TSVStream::Format::AnnovarInput::Role::Human

=head2 BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanNoChr

These two subroles provide a chr field that has no tag.  It will
accept valid chr values regardless of whether the provided value
has a leading 'chr' or not; the value will get the 'chr' prefix
inserted if missing (Human) or removed if present (HumanNoChr).
So, you choose the type that you want to end with.

For a B<reader>, this happens when reading an input stream - the
leading 'chr' will get forced to exist or not based on the type
you choose.  So, within your program, the values will all appear
in a consistant form regardless of what the input file provided.

For a B<writer>, this happens upon write - the B<write>
method will accept either an object of the configured form
(which it writes out directly), or an object of some other type
(which it converts into the specified type before writing).  So,
you can have your program write into the format that is needed
by whatever program is going to use the output, regardless of
which format is used for internal computation by your program.

=head2 BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTag

=head2 BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTagNoChr

These two subroles provide a chr field that may have a tag.
That allows a standard chr value to have an appended "_NAME"
(anything following an underscore).  It also allows the tag-only
chr value "Un_NAME" (any NAME following 'Un_'.

Like the two subroles above, the addition or absense of 'NoChr'
in the role name controls whether the value is coerced to have,
or not have, a leading 'chr' string.  (See the previous section.)

=cut

package BoutrosLab::TSVStream::Format::AnnovarInput::Role::Human;

use Moose::Role;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw(AI_ChrHumanWithChr);
use namespace::autoclean;

has 'chr' => (
	is       => 'ro',
	isa      => AI_ChrHumanWithChr,
	coerce   => 1,
	required => 1
	);


package BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanNoChr;

use Moose::Role;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw(AI_ChrHumanNoChr);
use namespace::autoclean;

has 'chr' => (
	is       => 'ro',
	isa      => AI_ChrHumanNoChr,
	coerce   => 1,
	required => 1
	);


package BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTag;

use Moose::Role;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw(AI_ChrHumanTagWithChr);
use namespace::autoclean;

has 'chr' => (
	is       => 'ro',
	isa      => AI_ChrHumanTagWithChr,
	coerce   => 1,
	required => 1
	);


package BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTagNoChr;

use Moose::Role;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw(AI_ChrHumanTagNoChr);
use namespace::autoclean;

has 'chr' => (
	is       => 'ro',
	isa      => AI_ChrHumanTagNoChr,
	coerce   => 1,
	required => 1
	);


=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format

This describes how IO-capable objects (such as ones created using
a subrole of this role) are defined.

=item BoutrosLab::TSVStream::IO

This describes of how readers and writers convert objects to or
from a text stream.

=item - BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed

=item - BoutrosLab::TSVStream::Format::AnnovarInput::Human::Dyn

=item - BoutrosLab::TSVStream::Format::AnnovarInput::HumanNoChr::Fixed

=item - BoutrosLab::TSVStream::Format::AnnovarInput::HumanNoChr::Dyn

These are the four variants for the object specification for Human
objects.  Those are the modules that you will typically B<use>
in your program.

Human/HumanNoChr specifies whether objects will be converted if
needed to (no) leading 'chr' prefix in the B<chr> attribute.

Fixed/Dyn specifies whether only the standard fields are expected,
or if a dynamic list of additional fields may occur.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

