# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::AnnovarInput::HumanTagNoChr::Dyn

=cut

package BoutrosLab::TSVStream::Format::AnnovarInput::HumanTagNoChr::Dyn;

use Moose;
use namespace::autoclean;

with qw(
	BoutrosLab::TSVStream::Format::AnnovarInput::Role
	BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTagNoChr
	BoutrosLab::TSVStream::IO::Role::Dyn
	);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format::AnnovarInput::Role

for a description of the AnnovarInput attributes; this module supports
the BoutrosLab::TSVStream::Format::AnnovarInput::Type::Chr::HumanTag::NoChr type
for the B<chr> attribute.

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

