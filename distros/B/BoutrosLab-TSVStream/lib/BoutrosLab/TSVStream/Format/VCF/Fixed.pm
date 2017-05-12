# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::Format::VCF::Fixed

=cut

package BoutrosLab::TSVStream::Format::VCF::Fixed;

use Moose;
use namespace::autoclean;

use BoutrosLab::TSVStream::Format::VCF::Role;

with qw(
	BoutrosLab::TSVStream::Format::VCF::Role
	BoutrosLab::TSVStream::IO::Role::Fixed
	);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format::AnnovarInput::Role

for a description of the VCF role. This module reads in data from
VCF files and dynamically manages stringified data in the filter
and info columns.

=item BoutrosLab::TSVStream::IO

for a description of converting to/from a TSVStream using a reader
or a writer.  This module only allows for the fixed attributes.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

