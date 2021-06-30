package Astro::FITS::CFITSIO::FileName;

# ABSTRACT: parse and generate CFITSIO extended file names.

## no critic (ProhibitSubroutinePrototypes)

use strict;
use warnings;

use v5.26;

our $VERSION = '0.05';

use Types::Standard qw[ Str ArrayRef StrMatch Enum Bool Optional Dict ];
use Types::Common::Numeric qw[ PositiveOrZeroInt PositiveInt ];
use Ref::Util qw[ is_arrayref ];

use Astro::FITS::CFITSIO::FileName::Regexp -all;

sub _croak {
    require Carp;
    goto \&Carp::croak;
}

use Moo;

use experimental 'signatures', 'postderef', 'declared_refs', 'refaliasing';

use namespace::clean;

use overload '""', "_stringify", fallback => 1;




















































































































































has base_filename => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);















has file_type => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);















has output_name => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);















has extname => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);















has extver => (
    is        => 'ro',
    isa       => PositiveInt,
    predicate => 1,
);

















has xtension => (
    is => 'ro',
    isa =>
      StrMatch [qr{\A A | ASCII | I | IMAGE | T| TABLE | B | BINTABLE \z}xi],
    predicate => 1,
);















has image_cell_spec => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);















has hdunum => (
    is        => 'ro',
    isa       => PositiveOrZeroInt,
    predicate => 1,
);















has compress_spec => (
    is        => 'ro',
    isa       => Str,
    predicate => 1,
);















has image_section => (
    is        => 'ro',
    isa       => ArrayRef [ StrMatch [$PixelRange] ],
    predicate => 1,
);

































has pix_filter => (
    is  => 'ro',
    isa => Dict [
        datatype     => Optional [ Enum [qw( b i j r d )] ],
        discard_hdus => Optional [Bool],
        expr         => Str
    ],
    predicate => 1,
);















has col_filter => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    predicate => 1,
);















has row_filter => (
    is        => 'ro',
    isa       => ArrayRef [Str],
    predicate => 1,
);





























has bin_spec => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            datatype => Optional [ Enum [qw( b i j r d )] ],
            expr => Optional[Str]
        ]
    ],
    predicate => 1,
);







has filename => (
    is       => 'lazy',
    init_arg => undef,
    builder  => 1
);







sub _stringify ( $self, @ ) {
    $self->filename;
}

around BUILDARGS => sub ( $orig, $class, @args ) {

    return $class->parse_filename( $args[0] )
      if @args == 1 && !ref $args[0];

    my \%args = $class->$orig( @args );

    $args{$_} = [ $args{$_} ]
      for grep { $args{$_} && !is_arrayref( $args{$_} ) }
      qw( col_filter row_filter bin_spec );

    return \%args;
};

sub BUILD ( $self, $ ) {

    my $is_image = $self->has_image_section || $self->has_pix_filter;

    _croak(
        "can't specify column, row, or bin/histogram specs if it's an image" )
      if $is_image
      && ( $self->has_col_filter
        || $self->has_row_filter
        || $self->has_bin_spec );

    _croak( "must specify extname if extver is specified" )
      if $self->has_extver && !$self->has_extname;

    _croak( "don't specify both extname and hdunum" )
      if $self->has_extname && $self->has_hdunum;

    # compress spec can only be used if nothing else is specified.
    _croak( "specify compress spec by itself" )
      if $self->has_compress_spec
      && ( $self->has_extname
        || $self->has_extver
        || $self->has_image_section
        || $self->has_pix_filter
        || $self->has_col_filter
        || $self->has_row_filter
        || $self->has_bin_spec );
}













sub parse_filename ( $, $filename ) {

    _croak( "can't parse filename: @{[ $filename // '<undef>' ]}" )
      unless defined $filename && $filename =~ $FileName;

    my %match = %+;

    if ( exists $match{col_bin_row} ) {
        # * didn't match [image_section][pix filter]
        # * found a bunch of things.
        for my $spec (
            $match{col_bin_row} =~ /( \[ $PossiblyQuotedStringInSpec \] )/xg )
        {

            if ( $spec =~ $binSpec ) {
                push(
                    ( $match{bin_spec} //= [] )->@*,
                    { (
                            exists $+{bin_spec_expression}
                            ? ( expr => $+{bin_spec_expression} )
                            : ()
                        ),
                        (
                            exists $+{bin_spec_datatype}
                            ? ( datatype => $+{bin_spec_datatype} )
                            : (),
                        )
                    },
                );
            }
            elsif ( $spec =~ $colFilter ) {

                push(
                    ( $match{col_filter} //= [] )->@*,
                    $+{col_filter} =~ m/$PossiblyQuotedStringInList/g
                );
            }
            elsif ( $spec =~ $rowFilter ) {
                push( ( $match{row_filter} //= [] )->@*, $+{row_filter} );
            }
            else {
                _croak(
                    "$spec is not a bin/histogram spec, column filter, or row filter"
                );
            }
        }
        delete $match{col_bin_row};
    }

    my $image_section
      = exists( $match{image_section_x} ) + exists( $match{image_section_y} );

    if ( $image_section ) {
        _croak(
            "internal error: missing either image_section_x or image_section_y"
        ) unless $image_section == 2;
        $match{image_section}
          = [ delete @match{ 'image_section_x', 'image_section_y' } ];
    }

    $match{output_name} = $match{template_name}
      if exists $match{template_name};

    if ( defined delete $match{pix_filter} ) {
        $match{pix_filter} = { (
                exists $match{pix_filter_discard_hdus} ? ( discard_hdus => 1 )
                : ()
            ),
            (
                exists $match{pix_filter_datatype}
                ? ( datatype => delete $match{pix_filter_datatype} )
                : ()
            ),
            expr => delete $match{pix_filter_expression},
        };
        delete $match{pix_filter_discard_hdus};
    }

    # remove undefined entries
    delete @match { grep ! defined $match{$_}, keys %match };

    \%match;
}

































sub render_base_filename ( $self ) {
    $self->base_filename;
}

sub render_file_type ( $self ) {
    $self->has_file_type ? $self->file_type : '';
}

sub render_output_name ( $self ) {
    $self->has_output_name
      ? sprintf( '(%s)', $self->output_name )
      : '';
}

sub render_compress_spec ( $self ) {
    return $self->has_compress_spec
      ? sprintf( '[compress %s]', $self->compress_spec )
      : '';
}

sub render_hdu ( $self ) {

    my @render;

    if ( $self->has_hdunum ) {
        push @render, '[', $self->hdunum;
        push @render, ';', $self->image_cell_spec
          if $self->has_image_cell_spec;
        push @render, ']';
    }

    elsif ( $self->has_extname ) {
        push @render, '[', $self->extname;
        push @render, ',', $self->extver if $self->has_extver;
        push @render, ',', $self->xtension if $self->has_xtension;
        push @render, ';', $self->image_cell_spec
          if $self->has_image_cell_spec;
        push @render, ']';
    }

    return join ('', @render );
}

sub render_image_section ( $self ) {

    $self->has_image_section
      ? sprintf( '[%s,%s]', $self->image_section->[0], $self->image_section->[1] )
      : '';
}

sub render_pix_filter ( $self ) {

    return '' unless $self->has_pix_filter;

    my @render;

    push @render, '[', 'pix';
    push @render, $self->pix_filter->{datatype}
      if exists $self->pix_filter->{datatype};
    push @render, '1'
      if exists $self->pix_filter->{discard_hdus}
      && $self->pix_filter->{discard_hdus};
    push @render, ' ';
    push @render, $self->pix_filter->{expr}, ']';

    return join( '', @render );

}

sub render_col_filter ( $self ) {
    return $self->has_col_filter
      ? '[col ' . join(';', $self->col_filter->@* ) . ']'
      : '';
}

sub render_row_filter ( $self ) {
    return $self->has_row_filter
      ? join('', map { "[$_]" } $self->row_filter->@* )
      : '';
}

sub render_bin_spec ( $self ) {

    return '' unless $self->has_bin_spec;

    my @render;

    for ( $self->bin_spec->@* ) {
        push @render, '[bin';
        push @render, $_->{datatype} if exists $_->{datatype};
        push @render, ' ', $_->{expr} if exists $_->{expr};
        push @render, ']';
    }

    return join( '', @render );
}

sub _build_filename ( $self ) {
    return join(
        '',
        $self->render_file_type,
        $self->render_base_filename,
        $self->render_output_name,
        $self->render_compress_spec,
        $self->render_hdu,
        $self->render_image_section,
        $self->render_pix_filter,
        $self->render_col_filter,
        $self->render_row_filter,
        $self->render_bin_spec,
    );
}










sub _maybe ( $self, $attr ) {

    my $mth = "has_$attr";
    return ( $self->$mth ? ( $attr => $self->$attr ) : () );
}

sub to_hash ( $self ) {

    return {
        base_filename => $self->base_filename,
        map { $self->_maybe( $_ ) }
          qw( file_type
          output_name
          extname
          extver
          xtension
          image_cell_spec
          hdunum
          compress_spec
          image_section
          pix_filter
          col_filter
          row_filter
          bin_spec
           )
           };
}


1;

#
# This file is part of Astro-FITS-CFITSIO-FileName
#
# This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory HDU PositiveInt Str expr
extname extver hdunum xtension histogramming

=head1 NAME

Astro::FITS::CFITSIO::FileName - parse and generate CFITSIO extended file names.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  $fobj = Astro::FITS::CFITSIO::FileName->new( $filename );

  $attr = Astro::FITS::CFITSIO::FileName->parse_filename( $filename );

=head1 DESCRIPTION

CFITSIO packs a lot of functionality into a filename; it can include
row and column filtering, binning and histogramming, image slicing,
etc.  It can be handy to manipulate the various parts that make up
a fully specified CFITSIO filename.

B<Astro::FITS::CFITSIO::FileName> slices and dices a CFITSIO
extended filename into its constituent pieces.  Or, given the constituent
pieces, it can craft an extended CFITSIO filename.

Documentation for the CFITSIO extended filename syntax is available in Chapter 10 of

  https://heasarc.gsfc.nasa.gov/docs/software/fitsio/c/c_user/cfitsio.html

=head2 Warning!

This module does not actually parse row filters, so it's possible that
it'll confuse an illegal component as one.  For example, in this
example, C<foo.fits[1:512]>, the illegal, partial image specification
C<[1:512]> will be identified as a row filter.  Oops.

=head2 So many object attributes!

There are many attributes that an object might have; most are optional.
Each optional attribute has a corresponding predicate method
(C<has_XXX>) which will return true if the attribute was set.  For
example, the C<pix_filter> attribute is optional; to check if it was
set, use the C<has_pix_filter> method.

=head2 Manipulating a filename

L<Astro::FITS::CFITSIO::FileName> objects are meant to be immutable, so
manipulating attributes has to be done outside of the object.

One way is to call the L</parse_filename> class method on the original
filename. It returns a hash of attributes. Another is to call the
L</to_hash> object method, which returns a hash of attributes for a
particular object.  Both of these hashes may be fed into the class
constructor.

=head1 CLASS METHODS

=head2 new

   $fileobj = Astro::FITS::CFITSIO::FileName->new( $filename );
   $fileobj = Astro::FITS::CFITSIO::FileName->new( \%args );

In the first example, parse a fully specified CFITSIO filename and populate
the attributes.

In the second example the following arguments are available.

=over

=item base_filename I<Str>

I<Required.>

=item file_type I<Enum>

I<Optional>

One of the CFITSIO supported file types, as a string.

=item output_name I<Str>

I<Optional>

=item extname I<Str>

I<Optional>

Don't use this with the L</hdunum> option.

=item extver I<PositiveInt>

I<Optional>

Don't use this with L</hdunum>. L</extname> must also be set.

=item xtension I<Enum>

I<Optional>

The type of the HDU.  It is case insensitive and may be one of

 A | ASCII |  I | IMAGE | T | TABLE | B | BINTABLE

=item image_cell_spec

I<Optional>

Images can be stored in vector cells; this specifies which cell to access.
Its value is not validated.

=item hdunum I<Positive Non Zero Integer>

I<Optional>

The HDU index. C<0> is the primary HDU.  Do not use this with L</extname>.

=item compress_spec

I<Optional>

The image tile compression specification.
Its value is not validated.

=item image_section

I<Optional>

An array of two elements containing (as strings) the pixel ranges for the image axes.

=item pix_filter

I<Optional>

A hashref containing the pixel filter.  The hash has the following entries:

=over

=item datatype

I<Optional>

=item discard_hdus

I<Optional>

=item expr

I<Required> The filter expression.

=back

=item col_filter

I<Optional>

An array of column filters, as strings. Not validated.

=item row_filter

I<Optional>

An array of row filters, as strings. Not validated.

=item bin_spec

I<Optional>

An arrayref of hashrefs containing binning/histogram specifications.

The hashes have the following entries:

=over

=item datatype

Optional.

=item expr

The binning expression.

=back

=back

=head2 parse_filename

  $attr = $class->parse_filename( $filename );

Parses an extended CFITSIO filename and returns a hash which may be fed
into the L<Astro::FITS::CFITSIO::FileName> constructor.   Typically
it's easier to just call the class constructor with the filename as a single argument,

If a subclass needs to amend the parsing, this is the method to override.

=head1 ATTRIBUTES

=head2 base_filename

The name of the file, without any trailing specifications
(e.g. anything in square brackets or parenthesis) or a leading URI.

This attribute is always present.

=head2 file_type

The type of file.  CFITSIO uses a URI style specification (e.g. C<mem://>, C<http://> ).

This is optional.  See L</has_file_type>

=head2 output_name

An output or template name, depending upon the context that it's used with CFITSIO.

This is optional.  See L</has_output_name>

=head2 extname

The name of the HDU provided by the C<EXTNAME> header keyword.

This is optional. See L</has_extname>

=head2 extver

The version of the HDU specified by the L</extname> attribute.  L</extname> must also be specified.

This is optional.  See L</has_extver>.

=head2 xtension

The type of the HDU.  It is case insensitive and may be one of

 A | ASCII |  I | IMAGE | T | TABLE | B | BINTABLE

This is optional.  See L</has_xtension>

=head2 image_cell_spec

Images can be stored in vector cells; this specifies which cell to access.

This is optional. See L</has_image_cell_spec>.

=head2 hdunum

The HDU index. C<0> is the primary HDU.  Do not use this with L</extname>.

This is optional. See L</has_hdunum>.

=head2 compress_spec

The image tile compression specification. The specification is not validated.

This is optional. See L</has_compress_spec>.

=head2 image_section

Returns an arrayref of two elements containing (as strings) the pixel ranges for the image axes.

This is optional. See L</has_image_section>.

=head2 pix_filter

A hashref containing the pixel filter.

The hash has the following entries:

=over

=item datatype

Optional.

=item discard_hdus

Optional.

=item expr

The filter expression.

=back

This is optional.  See L</has_pix_filter>.

=head2 col_filter

Returns an array of column filters, as strings.

This is optional.  See L</has_col_filter>.

=head2 row_filter

Returns an array of row filters, as strings.

This is optional. See L</has_row_filter>

=head2 bin_spec

Returns an arrayref of hashrefs containing binning/histogram specifications.

The hashes have the following entries:

=over

=item datatype

Optional.

=item expr

The binning expression.

=back

This is optional. See L</has_bin_spec>.

=head2 filename

This returns the full CFITSIO filename based on all of the attributes.

=head1 METHODS

=head2 has_bin_spec

returns true if the L</bin_spec> attribute is present.

=head2 has_file_type

returns true if the L</file_type> attribute is present.

=head2 has_output_name

returns true if the L</output_name> attribute is present.

=head2 has_extname

returns true if the L</extname> attribute is present.

=head2 has_extver

returns true if the L</extver> attribute is present.

=head2 has_xtension

returns true if the L</xtension> attribute is present.

=head2 has_image_cell_spec

returns true if the L</image_cell_spec> attribute is present.

=head2 has_hdunum

returns true if the L</hdunum> attribute is present.

=head2 has_compress_spec

returns true if the L</compress_spec> attribute is present.

=head2 has_image_section

returns true if the L</image_section> attribute is present.

=head2 has_pix_filter

returns true if the L</pix_filter> attribute is present.

=head2 has_col_filter

returns true if the L</col_filter> attribute is present.

=head2 has_row_filter

returns true if the L</row_filter> attribute is present.

=head2 has_bin_spec

returns true if the L</bin_spec> attribute is present.

=head2 render_base_filename

=head2 render_file_type

=head2 render_output_name

=head2 render_compress_spec

=head2 render_hdu

=head2 render_image_section

=head2 render_pix_filter

=head2 render_col_filter

=head2 render_row_filter

=head2 render_bin_spec

return a string version of the attribute which can be concatenated
to construct an extended syntax CFITSIO filename.  For example,

  $self->render_hdu

might return

  [extname, 2]

=head2 to_hash

  $hash = $self->to_hash;

returns a hashref containing the object's attributes.  This can be used to modify the attributes
and then pass them to the class constructor to create a modified object.

=head1 OVERLOAD

=head2 ""

Stringification is overloaded to return the filename as returned by the L</filename> attribute.

=for Pod::Coverage BUILD
BUILDARGS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-astro-fits-cfitsio-filename@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-FITS-CFITSIO-FileName

=head2 Source

Source is available at

  https://gitlab.com/djerius/astro-fits-cfitsio-filename

and may be cloned from

  https://gitlab.com/djerius/astro-fits-cfitsio-filename.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Astro::FITS::CFITSIO|Astro::FITS::CFITSIO>

=item *

L<Astro::FITS::CFITSIO::Simple|Astro::FITS::CFITSIO::Simple>

=item *

L<Astro::FITS::CFITSIO::Utils|Astro::FITS::CFITSIO::Utils>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
