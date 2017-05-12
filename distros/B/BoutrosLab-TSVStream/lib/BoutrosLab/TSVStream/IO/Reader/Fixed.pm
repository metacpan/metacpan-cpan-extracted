package BoutrosLab::TSVStream::IO::Reader::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream:IO::Reader::Fixed

=cut

use Moose;
use namespace::autoclean;

use BoutrosLab::TSVStream::IO::Role::Base::Fixed;
use BoutrosLab::TSVStream::IO::Role::Reader::Fixed;

with 'BoutrosLab::TSVStream::IO::Role::Base::Fixed',
	'BoutrosLab::TSVStream::IO::Role::Reader::Fixed';

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

A class to provide readers that read streams which only contain
the fixed attributes of the related class.

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO::Reader

for further details.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

