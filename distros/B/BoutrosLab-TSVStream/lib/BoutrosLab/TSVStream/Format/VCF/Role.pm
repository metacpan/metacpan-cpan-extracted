# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::VCF::Role

=head1 SYNOPSIS

Collection of roles that implement VCF format capable objects.
This role provides the common attributes for VCF format.
It also supplies methods that allow a VCF object act as a AnnovarInput
object.

=head1 DESCRIPTION

These roles are combined with an IO/Base role to provide one of the
two standard variants (Fixed and Dyn - depending upon whether you wish
to allow only the default set of fields or to allow additional trailing
fields following the default ones.)

See BoutrosLab::TSVStream::Format::Human::Fixed for an example.

=cut

package BoutrosLab::TSVStream::Format::VCF::Role::Base;

use Moose::Role;
use BoutrosLab::TSVStream::Format::VCF::Types qw( VCF_Chrom VCF_Ref Str_No_Whitespace VCF_KV_Str );
use MooseX::Types::Moose qw( ArrayRef HashRef Int );
use MooseX::ClassAttribute;
use namespace::autoclean;

=head1 Class Attributes

=head2 _fields

The B<_fields> attribute is required by the IO roles to determine
which fields are to be read or written.  In this case, the fields
are C<chrom>, C<start>, C<end>, C<ref>, and C<alt>, which are described
as attributes below.

=cut

class_has '_fields' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { [qw(chrom pos id ref alt qual filter info)] }
	);

=head1 Attributes

=head2 chrom

The B<chrom> attribute provides the name of the chromosome that is
being specified.  There are different names used for different
species of organism; and for different ways of processing the same
organism; so this attribute is provided in a separate role.

=cut

has 'chrom' => ( is => 'rw', isa => VCF_Chrom );

=head2 pos

The B<pos> attribute is an integer that provide the start
position within the chromosome that is being described.

=cut

has 'pos' => ( is => 'rw', isa => 'Int' );

=head2 id

The B<id> attribute is a string, not yet supported (in this module} for any specific use.

=cut

has 'id' => ( is => 'rw', isa => Str_No_Whitespace );

=head2 ref

=head2 alt

The B<ref> and B<alt> attributes describe amino acid sequences.
They can either contain the string I<'-'>, or a sequence of acids
(C<'A'>, C<'C'>, C<'G'>, and C<'T'> of at most 500 acids.  (E.G.:
CGATCGAT)

=cut

=head2 qual

=head2 filter

=head2 info

The B<qual>, B<filter>, and B<ifno> attributes are strings, not yet supported (in this module} for any specific use.

=cut

has [qw(qual filter)] => ( is => 'rw', isa => Str_No_Whitespace );

has 'info' => (
	is => 'rw',
	isa => VCF_KV_Str,
	coerce => 1
	);

=head2 _reader_args

=head2 _writer_args

=head2 info

The B<_reader_args> and B<_writer_args> attributes are internal settings.
They cause the reader and writer be given special args required for handling
VCF format files properly.

=cut

class_has '_reader_args' => (
	is       => 'ro',
	isa      => 'HashRef',
	init_arg => undef,
	default  => sub {
		return {
			pre_header         => 1,
			pre_comment        => 0,
			comment            => 0,
			pre_header_pattern => qr/^##/,
			header_fix         => sub {
				my $line = shift;
				my %newline;
				($newline{line} = $line->{line}) =~ s/^#\s*//;
				$newline{fields} = [ @{ $line->{fields} } ];
				$newline{fields}[0] =~ s/^#\s*//;
				return \%newline;
				},
			};
		}
	);

class_has '_writer_args' => (
	is       => 'ro',
	isa      => 'HashRef',
	init_arg => undef,
	default  => sub {
		return {
			pre_header  => 1,
			pre_comment => 0,
			comment     => 0,
			header_fix  => sub {
				my $headers = [ @{(shift)} ];
				$headers->[0] =~ s/^/#/;
				my @uc_headers = map { uc } @{$headers};
				return \@uc_headers;
				},
			};
		}
	);

#### Methods

=head1 WRAPPER ROLES

=head2 BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInputChr

=head2 BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInputNoChr

These wrapper roles provide a wrapper around the basic VCF role that
allows a vcf format record to be used as if it were an AnnovarInput
(or AnnovarInput...NoChr) format record.  This is done by providing
B<start>, B<end>, and B<chr> methods that match the attributes that
are normally present in an AnnovarInput record.

=head3 start

=head3 end

The B<start> and B<end> attributes are integers that provide the start
and end position within the chromosome that is being described.  The
B<start> value is just a synonym for the B<pos> attribute.  The B<end>
attribute is computed from the B<pos> value and the length of the
B<ref> attribute.

=head3 chr

The B<chr> attribute is the B<chrom> attribute with a leading 'chr'
string either forced or removed.

=cut

package BoutrosLab::TSVStream::Format::VCF::Role::Full;

use Moose::Role;
use namespace::autoclean;
use BoutrosLab::TSVStream::Format::VCF::Types qw( VCF_Ref_Full VCF_Alt_Full );

has 'ref' => ( is => 'rw', isa => VCF_Ref_Full );
has 'alt' => ( is => 'rw', isa => VCF_Alt_Full );

package BoutrosLab::TSVStream::Format::VCF::Role::RecSNV;

use Moose::Role;
use namespace::autoclean;
use BoutrosLab::TSVStream::Format::VCF::Types qw( VCF_Ref VCF_Alt );

has 'ref' => ( is => 'rw', isa => VCF_Ref );
has 'alt' => ( is => 'rw', isa => VCF_Alt );

package BoutrosLab::TSVStream::Format::VCF::Role::WithChr;

use Carp qw(croak);

use Moose::Role;
use namespace::autoclean;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw( AI_ChrHumanTagWithChr );

sub chr {
	my $self = shift;
	my $chrom = my $chr = $self->chrom;
	if ($chr =~ /^chr/i) {
		$chr =~ s/^chr/chr/i;
	}
	else {
		$chr = "chr$chr";
	}
	croak( "chrom ($chrom) failed to convert to AnnovarInput chr" )
		unless is_AI_ChrHumanTagWithChr($chr);
	return to_AI_ChrHumanTagWithChr($chr);
}

package BoutrosLab::TSVStream::Format::VCF::Role::WithNoChr;

use Carp qw(croak);

use Moose::Role;
use namespace::autoclean;
use BoutrosLab::TSVStream::Format::AnnovarInput::Types qw( AI_ChrHumanTagNoChr );

sub chr {
	my $self = shift;
	my $chrom = my $chr = $self->chrom;
	$chr =~ s/^chr//i;
	croak( "chrom ($chrom) failed to convert to AnnovarInput chr" )
		unless is_AI_ChrHumanTagNoChr($chr);
	return to_AI_ChrHumanTagNoChr($chr);
}

package BoutrosLab::TSVStream::Format::VCF::Role::FullChr;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role::Base',
	'BoutrosLab::TSVStream::Format::VCF::Role::Full',
	'BoutrosLab::TSVStream::Format::VCF::Role::WithChr';

package BoutrosLab::TSVStream::Format::VCF::Role::FullNoChr;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role::Base',
	'BoutrosLab::TSVStream::Format::VCF::Role::Full',
	'BoutrosLab::TSVStream::Format::VCF::Role::WithNoChr';

package BoutrosLab::TSVStream::Format::VCF::Role;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role::Base',
	'BoutrosLab::TSVStream::Format::VCF::Role::RecSNV';

package BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInput;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role';

sub start {
	my $self = shift;
	return $self->pos;
}

sub end {
	my $self = shift;
	return $self->pos + length($self->ref) - 1;
}

package BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInputChr;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInput',
	'BoutrosLab::TSVStream::Format::VCF::Role::WithChr';

package BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInputNoChr;

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInput',
	'BoutrosLab::TSVStream::Format::VCF::Role::WithNoChr';

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format

This describes how IO-capable objects (such as ones created using
a subrole of this role) are defined.

=item BoutrosLab::TSVStream::IO

This describes of how readers and writers convert objects to or
from a text stream.

=item - BoutrosLab::TSVStream::Format::VCF::Fixed

=item - BoutrosLab::TSVStream::Format::VCF::Dyn

These are the two variants for the object specification for VCF
objects.  Those are the modules that you will typically B<use>
and refer to in your program.

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

