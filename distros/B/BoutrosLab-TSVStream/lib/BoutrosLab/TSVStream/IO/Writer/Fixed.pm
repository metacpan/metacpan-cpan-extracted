package BoutrosLab::TSVStream::IO::Writer::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream:IO::Writer::Fixed

=cut

use Moose;
use namespace::autoclean;

use BoutrosLab::TSVStream::IO::Role::Base::Fixed;
use BoutrosLab::TSVStream::IO::Role::Writer::Fixed;

with 'BoutrosLab::TSVStream::IO::Role::Base::Fixed',
	'BoutrosLab::TSVStream::IO::Role::Writer::Fixed';


__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

A class to provide writers that write streams which only contain
the fixed attributes of the related class.

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO::Writer

for further details.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

