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
# $Id: Reader.pm 380 2013-04-30 09:08:39Z tfrayner $

package Bio::MAGETAB::Util::Reader;

use 5.008001;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str Bool Int );
use Bio::MAGETAB::Types qw( Uri );

use Carp;
use URI;
use URI::file;
use File::Spec;

use Bio::MAGETAB::Util::Reader::ADF;
use Bio::MAGETAB::Util::Reader::IDF;
use Bio::MAGETAB::Util::Reader::SDRF;
use Bio::MAGETAB::Util::Reader::DataMatrix;
use Bio::MAGETAB::Util::Builder;

has 'idf'                 => ( is         => 'rw',
                               isa        => Uri,
                               required   => 1,
                               coerce     => 1 );

has 'authority'           => ( is         => 'rw',
                               isa        => Str,
                               default    => q{},
                               required   => 1 );

has 'namespace'           => ( is         => 'rw',
                               isa        => Str,
                               default    => q{},
                               required   => 1 );

has 'relaxed_parser'      => ( is         => 'rw',
                               isa        => Bool,
                               default    => 0,
                               required   => 1 );

has 'ignore_datafiles'    => ( is         => 'rw',
                               isa        => Bool,
                               default    => 0,
                               required   => 1 );

has 'builder'             => ( is         => 'rw',
                               isa        => 'Bio::MAGETAB::Util::Builder',
                               default    => sub { Bio::MAGETAB::Util::Builder->new() },
                               required   => 1 );

has 'common_directory'    => ( is         => 'rw',
                               isa        => Int,
                               default    => 1,
                               required   => 1 );

has 'document_version'    => ( is         => 'rw',
                               isa        => 'Str' );

# Make this visible to users of the module.
our $VERSION = 1.0;

sub parse {

    my ( $self ) = @_;

    # We use this object to track MAGETAB object creation.
    my $builder = $self->get_builder();
    $builder->set_namespace(      $self->get_namespace()      );
    $builder->set_authority(      $self->get_authority()      );
    $builder->set_relaxed_parser( $self->get_relaxed_parser() );

    my $idf_parser = Bio::MAGETAB::Util::Reader::IDF->new({
	uri     => $self->get_idf(),
        builder => $builder,
    });

    my ( $investigation, $magetab_container ) = $idf_parser->parse();
    $self->set_document_version( $idf_parser->get_document_version() );

    # FIXME parse the SDRFS etc. here. N.B. some extra stitching may be needed.
    foreach my $sdrf ( @{ $investigation->get_sdrfs() } ) {
	my $sdrf_parser = Bio::MAGETAB::Util::Reader::SDRF->new({
	    uri                        => $self->_rewrite_uri($sdrf->get_uri()),
            builder                    => $builder,
            magetab_object             => $sdrf,
	});
        my $sdrf = $sdrf_parser->parse();
    }

    # Parse through all the ADFs.
    foreach my $array ( $magetab_container->get_arrayDesigns() ) {
        if ( $array->get_uri() ) {
            my $parser = Bio::MAGETAB::Util::Reader::ADF->new({
                uri            => $self->_rewrite_uri($array->get_uri()),
                builder        => $builder,           
                magetab_object => $array,
            });
            $parser->parse();
        }
    }

    # Parse through all the DataMatrix objects.
    unless ( $self->get_ignore_datafiles() ) {
        foreach my $matrix ( $magetab_container->get_dataMatrices() ) {
            my $parser = Bio::MAGETAB::Util::Reader::DataMatrix->new({
                uri            => $self->_rewrite_uri($matrix->get_uri()),
                builder        => $builder,           
                magetab_object => $matrix,
            });

            $parser->parse();
        }
    }

    return wantarray
	   ? ( $investigation, $magetab_container )
	   : $magetab_container;
}

# Cribbed from the List::Util POD and modified to allow map-like usage.
sub _all (&@) { my $f = shift; $f->($_) || return 0 for @_; 1 }

sub _rewrite_uri {

    my ( $self, $uri ) = @_;

    my $idf_uri = $self->get_idf();

    # Assume file as default URI scheme unless specified otherwise.
    if ( _all { ! $_->scheme() || $_->scheme() eq 'file' } $uri, $idf_uri ) {

        my $uri_path = $uri->file();
        my $path;
	if ( $self->get_common_directory() ) {
            my $idf_path      = File::Spec->rel2abs( $idf_uri->file() );
            my @idf_dir_parts = File::Spec->splitpath( $idf_path );
            my $dir = File::Spec->catdir( @idf_dir_parts[ 0, 1 ] );

	    $path = File::Spec->file_name_is_absolute( $uri_path )
		  ? $uri_path
		  : File::Spec->catfile( $dir, $uri_path );
	}
	else {
	    $path = File::Spec->rel2abs( $uri_path );
	}

        $uri = to_Uri($path)
            or croak(qq{Cannot coerce file path "$path" to URI object.});
    }

    return $uri;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader - A parser/validator for MAGE-TAB documents.

=head1 SYNOPSIS

 use Bio::MAGETAB::Util::Reader;
 my $reader = Bio::MAGETAB::Util::Reader->new({
    idf            => $idf,
    relaxed_parser => $is_relaxed,
 });

 my $magetab = $reader->parse();

=head1 DESCRIPTION

This is the main parsing and validation class which can be used to
read a MAGE-TAB document into a set of Bio::MAGETAB classes for
further manipulation.

=head1 ATTRIBUTES

=over 2

=item idf

A filesystem or URI path to the top-level IDF file describing the
investigation. This attribute is *required*.

=item relaxed_parser

A boolean value (default FALSE) indicating whether or not the parse
should take place in "relaxed mode" or not. The regular parsing mode
will throw an exception in cases where an object is referenced before
it has been declared (e.g., Protocol REF pointing to a non-existent
Protocol Name). Relaxed parsing mode will silently autogenerate the
non-existent objects instead.

=item namespace

An optional namespace string to be used in object creation.

=item authority

An optional authority string to be used in object creation.

=item builder

An optional Builder object. These Builder objects are used to track
the creation of Bio::MAGETAB objects by caching the objects in an
internal store, keyed by a set of identifying information (see the
L<Builder|Bio::MAGETAB::Util::Builder> class). This object can be used in
multiple Reader objects to help link common objects from multiple
MAGE-TAB documents together. In its simplest form this internal store
is a simple hash; however in principle this could be extended by
subclassing Builder to create e.g. persistent database storage
mechanisms.

=item ignore_datafiles

A boolean value (default FALSE) indicating whether to skip parsing of
Data Matrix files.

=item common_directory

A boolean value (default TRUE) indicating whether the IDF, SDRF, ADF
and Data Matrices are located in the same directory. This influences
whether URIs found in IDF and SDRF files are interpreted relative to
the locations of those files, or relative to the current working
directory. Note that this will not affect local file URIs giving
absolute locations or URIs using other schemes (e.g. http).

=item document_version

A string representing the MAGE-TAB version used in the parsed
document. This is populated by the parse() method.

=back

=head1 METHODS

=over 2

=item parse

Attempts to parse the full MAGE-TAB document, starting with the
top-level IDF file, and returns the resulting Bio::MAGETAB container
object in scalar context, or the top-level Bio::MAGETAB::Investigation
object and container object in list context.

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
