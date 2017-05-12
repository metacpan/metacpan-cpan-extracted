# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: Writer.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Util::Writer;

use Moose;
use MooseX::FollowPBP;

use Carp;
use List::Util qw( first );

use MooseX::Types::Moose qw( Str );

use Bio::MAGETAB::Util::Writer::IDF;
use Bio::MAGETAB::Util::Writer::ADF;
use Bio::MAGETAB::Util::Writer::SDRF;

has 'magetab'            => ( is         => 'rw',
                              isa        => 'Bio::MAGETAB',
                              required   => 1 );

has 'export_version'     => ( is         => 'ro',
                              isa        => Str,
                              required   => 1,
                              default    => '1.1' );

sub BUILD {

    # Note that this is also checked in B::M::U::Writer::TabFile
    my ( $self, $params ) = @_;

    my $version = $params->{'export_version'};
    if ( defined $version ) {
        unless ( first { $_ eq $version } qw( 1.0 1.1 ) ) {
            croak("Error: Export of MAGE-TAB version $version is not yet supported.");
        }
    }

    return;
}

sub write {

    my ( $self ) = @_;

    my $magetab = $self->get_magetab();
    foreach my $investigation ( $magetab->get_investigations() ) {
        my $filename = $self->_sanitize_path( $investigation->get_title() );

        open( my $fh, '>', "$filename.idf" )
            or croak("Error: Unable to open IDF output file: $!");

        my $writer = Bio::MAGETAB::Util::Writer::IDF->new(
            magetab_object => $investigation,
            filehandle     => $fh,
            export_version => $self->get_export_version(),
        );

        $writer->write();
    }
    foreach my $array ( $magetab->get_arrayDesigns() ) {
        my $filename;
        if ( my $uri = $array->get_uri() ) {
            my $path = $uri->path();
            ( $filename ) = ( $path =~ m/([^\/]+) \z/xms );
        }
        unless ( $filename ) {
            $filename = $self->_sanitize_path( $array->get_name() ) . '.adf';
        }

        open( my $fh, '>', $filename )
            or croak("Error: Unable to open ADF output file: $!");
        my $writer = Bio::MAGETAB::Util::Writer::ADF->new(
            magetab_object => $array,
            filehandle     => $fh,
            export_version => $self->get_export_version(),
        );

        $writer->write();
    }
    foreach my $sdrf ( $magetab->get_sdrfs() ) {
        my $path = $sdrf->get_uri()->path();
        my ( $filename ) = ( $path =~ m/([^\/]+) \z/xms );
        
        open( my $fh, '>', $filename )
            or croak("Error: Unable to open SDRF output file: $!");
        my $writer = Bio::MAGETAB::Util::Writer::SDRF->new(
            magetab_object => $sdrf,
            filehandle     => $fh,
            export_version => $self->get_export_version(),
        );

        $writer->write();
    }

    return;
}

sub _sanitize_path {

    my ( $self, $path ) = @_;

    # Sanitize the file name.
    $path =~ s/[^A-Za-z0-9_-]+/_/g;

    return $path;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Writer - Export of MAGE-TAB objects.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Writer;
 my $writer = Bio::MAGETAB::Util::Writer->new({
    magetab => $magetab_container,
 });
 
 $writer->write();

=head1 DESCRIPTION

This class is designed to export all the MAGE-TAB objects from a given
Bio::MAGETAB container, creating as many IDFs, ADFs and SDRFs as are
necessary to do so.

Export of the individual MAGE-TAB components is delegated to separate
writer classes. See the L<ADF|Bio::MAGETAB::Util::Writer::ADF>,
L<IDF|Bio::MAGETAB::Util::Writer::IDF> and
L<SDRF|Bio::MAGETAB::Util::Writer::SDRF> classes if you want more control over the
export process.

=head1 ATTRIBUTES

=over 2

=item magetab

The Bio::MAGETAB container to export. This is a required
attribute. See the L<Bio::MAGETAB|Bio::MAGETAB> class for more information on this container
class.

=item export_version

A string indicating which version of the MAGE-TAB format to export;
currently restricted to "1.0" or "1.1". The default is "1.1".

=back

=head1 METHODS

=over 2

=item write

Exports all objects into their respective MAGE-TAB
components. Filenames are automatically generated from Investigation
title, ArrayDesign uri (or name) and SDRF uri attributes.

=back

=head1 SEE ALSO

L<Bio::MAGETAB>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
