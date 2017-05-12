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
# $Id: Tabfile.pm 351 2010-09-03 10:58:15Z tfrayner $

package Bio::MAGETAB::Util::Writer::Tabfile;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Text::CSV_XS;
use List::Util qw( first );

use MooseX::Types::Moose qw( Int FileHandle Str );

has 'filehandle'         => ( is         => 'rw',
                              isa        => FileHandle,
                              required   => 1 );

has 'num_columns'        => ( is         => 'rw',
                              isa        => Int,
                              required   => 0 );

has 'csv_writer'         => ( is         => 'rw',
                              isa        => 'Text::CSV_XS',
                              required   => 0 );

has 'export_version'     => ( is         => 'ro',
                              isa        => Str,
                              required   => 1,
                              default    => '1.1' );

sub BUILD {

    # Note that this is also checked in B::M::U::Writer
    my ( $self, $params ) = @_;

    my $version = $params->{'export_version'};
    if ( defined $version ) {
        unless ( first { $_ eq $version } qw( 1.0 1.1 ) ) {
            croak("Error: Export of MAGE-TAB version $version is not yet supported.");
        }
    }

    return;
}

sub _get_type_termsource_name {
    my ( $self, $type ) = @_;
    my $ts = $type ? $type->get_termSource() : undef;
    return $ts ? $ts->get_name() : q{};
}

sub _get_thing_accession {
    my ( $self, $thing ) = @_;

    # Return undef if we're exporting MAGE-TAB v1.0.
    return if ( $self->get_export_version() eq '1.0' );

    return $thing->get_accession();    
}

sub _write_line {

    my ( $self, $field, @values ) = @_;

    my $fh = $self->get_filehandle();

    my $num_cols = $self->get_num_columns()
        or confess("Error: Number of columns has not yet been calculated.");

    my $csv_writer = $self->_construct_csv_writer();

    # Replace any undefined values with empty string.
    @values = map { defined $_ ? $_ : q{} } @values;

    # Check we're not out of bounds.
    my @to_write = ( $field, @values );
    if ( scalar @to_write > $num_cols ) {
        confess("Error: Attempted to write more columns than were originally calculated.");
    }

    # Pad the line with empty strings.
    my $diff = $num_cols - scalar @to_write;
    push @to_write, (q{}) x $diff;

    # Write the line.
    $csv_writer->print( $fh, \@to_write );

    return;
}

sub _construct_csv_writer {

    my ( $self ) = @_;

    # We cache this in a private attribute so each file only gets one
    # writer (better for error trackage).
    unless ( $self->get_csv_writer() ) {
        my $csv_writer = Text::CSV_XS->new(
            {   sep_char    => qq{\t},
                quote_char  => qq{"},                   # default
                escape_char => qq{"},                   # default
                binary      => 1,
                eol         => qq{\n},
            }
        );
        $self->set_csv_writer( $csv_writer );
    }

    return $self->get_csv_writer();
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Writer::Tabfile - Abstract MAGE-TAB exporter class.

=head1 SYNOPSIS

 use base qw( Bio::MAGETAB::Util::Writer::Tabfile );

=head1 DESCRIPTION

This abstract class provides some basic functions for export of
MAGE-TAB objects in tab-delimited format. It is not designed to be
used directly.

=head1 ATTRIBUTES

=over 2

=item filehandle

The filehandle to use for output (required).

=item num_columns

The number of columns to use for output. This must be set before
anything is exported. Typically calculated and set from the subclass.

=item csv_writer

The Text::CSV_XS object to use for output. This attribute is typically
set in the subclass.

=item export_version

A string indicating which version of the MAGE-TAB format to export;
currently restricted to "1.0" or "1.1". The default is "1.1".

=back

=head1 METHODS

No public methods.

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Writer::ADF>
L<Bio::MAGETAB::Util::Writer::IDF>
L<Bio::MAGETAB::Util::Writer::SDRF>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
