# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::VCF::AsAnnovarInputChr::Dyn

=cut

package BoutrosLab::TSVStream::Format::VCF::AsAnnovarInputChr::Dyn;

use Moose;
use namespace::autoclean;

use BoutrosLab::TSVStream::Format::VCF::Role;

with qw(
	BoutrosLab::TSVStream::Format::VCF::Role::AsAnnovarInputChr
	BoutrosLab::TSVStream::IO::Role::Dyn
	);

__PACKAGE__->meta->make_immutable;


=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format::AnnovarInput::Role

for a description of the AnnovarInput attributes; this module supports
using a VCF stream source as if it were in AnnovarInput format, with the
B<chr> attribute, with the leading 'chr' inserted.

=item BoutrosLab::TSVStream::IO

for a description of converting to/from a TSVStream using a reader
or a writer.  This module expects the fixed attributes to be followed
by a set of dynamic attributes.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

