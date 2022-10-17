package Astro::FITS::CFITSIO::Simple::Image;

# ABSTRACT: Read FITS Images

use 5.008002;
use strict;
use warnings;

require Exporter;

use Params::Validate qw/ :all /;

use Carp;

use PDL;

use Astro::FITS::CFITSIO qw/ :constants /;
use Astro::FITS::CFITSIO::CheckStatus;
use Astro::FITS::CFITSIO::Simple::PDL qw/ :all /;
use Astro::FITS::Header;
use Astro::FITS::Header::CFITSIO;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Astro::FITS::CFITSIO::Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [ qw(
          _rdfitsImage
        ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.20';

# this must be called ONLY from rdfits.  it makes assumptions about
# the validity of arguments that have been verified by rdfits.

sub _rdfitsImage {

    my $opts = 'HASH' eq ref $_[-1] ? pop : {};

    # first arg is fitsfilePtr
    # second is cleanup object; must keep around until we're done,
    # so it'll cleanup at the correct time.
    my $fptr = shift;

    # we don't expect any more arguments; complain if we do...
    croak( "unexpected extra arguments in call to rdfitsImage\n" )
      if @_;

    my %opt = validate_with(
        params         => [$opts],
        normalize_keys => sub { lc $_[0] },
        spec           => {
            nullval => { type => SCALAR,      optional => 1 },
            dtype   => { isa  => 'PDL::Type', optional => 1 },
        },
    );

    tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';

    # get image type and size
    $fptr->get_img_equivtype( my $btype, $status );
    $fptr->get_img_size( \my @naxes, $status );

    # what's the PDL type that encompasses the CFITSIO type?
    my $ptype = $opt{dtype} ? $opt{dtype} : fits2pdl_imgtype( $btype );
    my $data  = PDL->new_from_specification( $ptype, @naxes );

    # grab header, delete scaling keywords, stuff it into piddle
    my $hdr = Astro::FITS::Header::CFITSIO->new( fitsID => $fptr );
    tie my %hdr, 'Astro::FITS::Header', $hdr;
    delete @hdr{qw/ BSCALE BZERO /};
    $data->sethdr( \%hdr );

    # what we tell CFITSIO that we're reading. some deception,
    # as all we care about is the size of the data type
    my $ctype = pdl2cfitsio( $ptype );

    # How to handle null pixels.  A nullval of zero signals CFITSIO to
    # ignore null pixels
    my $nullval
      = exists $opt{nullval} ? $opt{nullval}
      : $PDL::Bad::Status    ? my_badvalue( $ptype )
      :                        0;

    $fptr->read_pix(
        $ctype,       [ ( 1 ) x @naxes ],
        $data->nelem, $nullval, ${ $data->get_dataref },
        my $anynul,   $status
    );
    $data->upd_data;

    $data->badflag( $anynul ) if $PDL::Bad::Status;

    $data;
}

1;

#
# This file is part of Astro-FITS-CFITSIO-Simple
#
# This software is Copyright (c) 2008 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Pete Ratzlaff Smithsonian Astrophysical Observatory

=head1 NAME

Astro::FITS::CFITSIO::Simple::Image - Read FITS Images

=head1 VERSION

version 0.20

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-astro-fits-cfitsio-simple@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-FITS-CFITSIO-Simple

=head2 Source

Source is available at

  https://gitlab.com/djerius/astro-fits-cfitsio-simple

and may be cloned from

  https://gitlab.com/djerius/astro-fits-cfitsio-simple.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Astro::FITS::CFITSIO::Simple|Astro::FITS::CFITSIO::Simple>

=back

=head1 AUTHORS

=over 4

=item *

Diab Jerius <djerius@cpan.org>

=item *

Pete Ratzlaff

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
