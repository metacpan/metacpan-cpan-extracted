package Astro::FITS::CFITSIO::FileName::Regexp;

# ABSTRACT: Regular expressions to match parts of CFITSIO  file names.

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter::Shiny 1.00200 qw( $FileName $colFilter $rowFilter $binSpec $PixelRange );

# all thanks to PPR, Damian's masterpiece
our $ATOMS = qr{
(?(DEFINE)

   (?<FileType>
     (file|ftp|http|https|ftps|stream|gsiftp|root|shmem|mem)://
   )

   (?<BaseFileName>
     [^[(\]]+
   )

  (?<HDUNUM>
      (?&PositiveOrZeroInt)
  )

  (?<XTENSION>
    (?i)A | ASCII | I | IMAGE | T | TABLE | B | BINTABLE?
  )

  (?<EXTVER>
   (?&PositiveInt)
  )

  # According to the FITS standard, this is a "character string' (no
  # definition of what's in it), but exclude things that mess up the parse
  (?<EXTNAME>
    [^\s,:[\]\#;]+
    \#?
  )

 (?<PositiveOrZeroInt>
     [0-9]*
 )

 (?<PositiveInt>
     0*[1-9][0-9]*
 )

)
}x;

our $OutputName = qr {
     \( \s*
       (?<output_name>[^\)]+)
     \s* \)
}x;

our $TemplateName = qr {
     \( \s*
       (?<template_name>[^\)]+)
     \s* \)
}x;


our $PixelRange = qr{
    ( -?\*
      |
      -?(?&PositiveInt)\s*:(?&PositiveInt)
    )
    (:  (?&PositiveInt) )?

  $ATOMS
}x;

our $ImageSection = qr {
   \[
     (?<image_section_x> $PixelRange)\s*,\s*(?<image_section_y> $PixelRange)
   \]
   $ATOMS
}x;

our $pixFilter = qr {
   \[ \s*
      (?<pix_filter>
      pix(?<pix_filter_datatype>b|i|j|r|d)?
      (?<pix_filter_discard_hdus>1)?
      \s+
      (?<pix_filter_expression> [^[\]]+)
      )
    \s* \]
}x;

our $rowFilter = qr {
  \[ \s*
     (?<row_filter> [^\]]+)
   \s* \]
}x;

our $binSpec = qr{
  \[ \s*
    bin(?<bin_spec_datatype> b|i|j|r|d)?
    (?: \s+
       (?<bin_spec_expression>( [^\]]+) )
    )?
   \s* \]
}x;

our $colFilter = qr{
  \[ \s*
    col\s+ (?<col_filter>[^\]]+)
    \s* \]
}x;

our $CompressSpec = qr {
  \[ \s* compress  \s* (?<compress_spec>[^[\]]+)?  \s* \]
}xi;

our $HDUlocation = qr{
    \+(?<hdunum> (?&HDUNUM) )
    |
    # [ ... ]
    \[ \s*
        (?:
            (?<extname> P(?: RIMARY)? )
            |
            (?:
               (?<hdunum> (?&HDUNUM))
               |
               (?:
                   (?<extname> (?&EXTNAME))
                   \s*
                   (?:
                       ,\s*(?<extver> (?&EXTVER))
                       |
                       ,\s*(?<extver> (?&EXTVER))\s*,\s*(?<xtension> (?&XTENSION))
                       |
                       ,\s*(?<xtension> (?&XTENSION))
                   )?
               )
            )
            # image stored in cell
            (?:\s*;\s*(?<image_cell_spec>[^\]]+?))?
        )
    \s* \]

   $ATOMS
}xi;

our $FileName = qr{
       \A
       (?<file_type> (?&FileType))?
       (?<base_filename> (?&BaseFileName))
       (?:
           (?:
               (?: $TemplateName)?
               (?: $CompressSpec)?
           )
           |
           (?:
               (?: $OutputName)?
               (?: $HDUlocation)?
               (?:
                  (?: $ImageSection)?
                  (?: $pixFilter)?
               |
                   (?<col_bin_row> (?:\[ [^\]]* \])+ )
                   # this is split out later in parse_filename
                   # (?:
                   #    (?&colFilter)|($binSpec)|(?&rowFilter)
                   # )*
               )
           )
       )?
   \z
   $ATOMS
}x;


1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Astro::FITS::CFITSIO::FileName::Regexp - Regular expressions to match parts of CFITSIO  file names.

=head1 VERSION

version 0.03

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

L<Astro::FITS::CFITSIO::FileName|Astro::FITS::CFITSIO::FileName>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
