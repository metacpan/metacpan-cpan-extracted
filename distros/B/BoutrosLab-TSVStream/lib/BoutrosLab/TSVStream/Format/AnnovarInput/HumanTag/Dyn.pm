# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::AnnovarInput::HumanTag::Dyn

=cut

package BoutrosLab::TSVStream::Format::AnnovarInput::HumanTag::Dyn;

use Moose;
use namespace::autoclean;

with qw(
	BoutrosLab::TSVStream::Format::AnnovarInput::Role
	BoutrosLab::TSVStream::Format::AnnovarInput::Role::HumanTag
	BoutrosLab::TSVStream::IO::Role::Dyn
	);

__PACKAGE__->meta->make_immutable;

=over

=item BoutrosLab::TSVStream::Format::AnnovarInput::Role

for a description of the AnnovarInput attributes; this module supports
the BoutrosLab::TSVStream::Format::AnnovarInput::Type::Chr::HumanTag type
for the B<chr> attribute.

=item BoutrosLab::TSVStream::IO

for a description of converting to/from a TSVStream using a reader
or a writer.  This module expects the fixed attributes to be followed
by a set of dynamic attributes.

=back


=head1 SEE ALSO

    BoutrosLab::TSVStream

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

