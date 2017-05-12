package Astro::WCS::LibWCS;

$VERSION = '0.94';

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

my @_constants = qw(
		    PI
		    TNX_CHEBYSHEV
		    TNX_LEGENDRE
		    TNX_POLYNOMIAL
		    TNX_XFULL
		    TNX_XHALF
		    TNX_XNONE
		    WCS_AIR
		    WCS_AIT
		    WCS_ALTAZ
		    WCS_ARC
		    WCS_AZP
		    WCS_B1950
		    WCS_BON
		    WCS_CAR
		    WCS_CEA
		    WCS_COD
		    WCS_COE
		    WCS_COO
		    WCS_CPS
		    WCS_CSC
		    WCS_CYP
		    WCS_DSS
		    WCS_ECLIPTIC
		    WCS_GALACTIC
		    WCS_GLS
		    WCS_J2000
		    WCS_LIN
		    WCS_LINEAR
		    WCS_MER
		    WCS_MOL
		    WCS_NCP
		    WCS_NPOLE
		    WCS_PAR
		    WCS_PCO
		    WCS_PIX
		    WCS_PLANET
		    WCS_PLT
		    WCS_QSC
		    WCS_SIN
		    WCS_SPA
		    WCS_STG
		    WCS_TAN
		    WCS_TNX
		    WCS_TSC
		    WCS_ZEA
		    WCS_ZPN
		    );

my @_functions = qw(
		    wcsninit
		    wcsinit
		    wcsninitn
		    wcsinitn
		    wcsninitc
		    wcsinitc
		    wcsfree
		    wcsxinit
		    wcskinit
		    wcstype
		    wcsreset
		    wcseqset
		    wcscdset
		    wcsdeltset
		    wcspcset
		    wcsrotset
		    iswcs
		    nowcs
		    wcsshift
		    wcscent
		    wcssize
		    wcsfull
		    wcsrange
		    wcsdist
		    wcscominit
		    wcscom
		    wcsoutinit
		    getwcsout
		    wcsininit
		    getwcsin
		    setwcsdeg
		    wcsndec
		    getradecsys
		    setwcslin
		    pix2wcst
		    pix2wcs
		    wcs2pix
		    wcsc2pix
		    wcspos
		    wcspix
		    wcszin
		    wcszout
		    setwcsfile
		    setwcserr
		    wcserr
		    setdefwcs
		    getdefwcs
		    savewcscoor
		    getwcscoor
		    savewcscom
		    setwcscom
		    getwcscom
		    freewcscom
		    wcscon
		    wcsconp
		    wcsconv
		    wcscsys
		    wcsceq
		    wcscstr
		    fk524
		    fk524e
		    fk524m
		    fk524pv
		    fk425
		    fk425e
		    fk425m
		    fk425pv
		    fk42gal
		    gal2fk4
		    fk52gal
		    gal2fk5
		    eqstrn
		    v2s3
		    s2v3
		    fk42ecl
		    fk52ecl
		    ecl2fk4
		    ecl2fk5
		    fk4prec
		    fk5prec
		    mprecfk4
		    mprecfk5
		    hlength
		    gethlength
		    hgeti4
		    hgeti2
		    hgetr4
		    hgetra
		    hgetdec
		    hgetr8c
		    hgetr8
		    hgetl
		    hgetdate
		    hgetm
		    hgetsc
		    hgets
		    hgetndec
		    hgetc
		    blsearch
		    ksearch
		    str2ra
		    str2dec
		    strsrch
		    strnsrch
		    strcsrch
		    strncsrch
		    notnum
		    isnum
		    dsspos
		    dsspix
		    platepos
		    platepix
		    SetPlate
		    GetPlate
		    SetFITSPlate
		    tnxinit
		    tnxpos
		    tnxpix
		    tnxclose
		    tnxpset
		    worldpos
		    worldpix
		    hputi4
		    hputr4
		    hputr8
		    hputnr8
		    hputra
		    hputdec
		    hputl
		    hputs
		    hputm
		    hputc
		    hputcom
		    hdel
		    hadd
		    hchange
		    ra2str
		    dec2str
		    deg2str
		    num2str
		    actopen
		    actclose
		    tabread
		    tabrnum
		    tabxyread
		    tabrkey
		    tabcatopen
		    tabcatclose
		    tabstar
		    tabopen
		    tabclose
		    gettabline
		    tabgetk
		    tabgetc
		    tabparse
		    tabcol
		    istab
		    RefCat
		    CatCode
		    CatID
		    CatNum
		    CatNumLen
		    CatNdec
		    CatMagName
		    CatMagNum
		    StrNdec
		    NumNdec
		    SearchLim
		    RefLim
		    RangeInit
		    isrange
		    rstart
		    rgetn
		    rgetr8
		    rgeti4

		    ang2hr
		    ang2deg
		    deg2ang
		    hr2ang
		    dt2fd
		    dt2jd
		    dt2mjd
		    hjd2jd
		    jd2hjd
		    mhjd2mjd
		    mjd2mhjd
		    jd2dt
		    jd2i
		    jd2mjd
		    jd2ep
		    jd2epb
		    jd2epj
		    lt2dt
		    lt2fd
		    lt2tsi
		    lt2tsu
		    lt2ts
		    mjd2dt
		    mjd2i
		    mjd2doy
		    mjd2jd
		    mjd2ep
		    mjd2epb
		    mjd2epj
		    mjd2fd
		    mjd2ts
		    ep2fd
		    epb2fd
		    epj2fd
		    ep2ts
		    epb2ts
		    epj2ts
		    epb2ep
		    ep2epb
		    epj2ep
		    ep2epj
		    ep2i
		    epb2i
		    epj2i
		    ep2jd
		    epb2jd
		    epj2jd
		    ep2mjd
		    epb2mjd
		    epj2mjd
		    epb2epj
		    epj2epb
		    jd2fd
		    jd2ts
		    jd2tsi
		    jd2tsu
		    dt2doy
		    doy2dt
		    doy2ep
		    doy2epb
		    doy2epj
		    doy2fd
		    doy2jd
		    doy2mjd
		    doy2tsu
		    doy2tsi
		    doy2ts
		    fd2doy
		    jd2doy
		    ts2jd
		    ts2mjd
		    ts2ep
		    ts2epb
		    ts2epj
		    dt2ep
		    dt2epb
		    dt2epj
		    ep2dt
		    epb2dt
		    epj2dt
		    fd2jd
		    fd2mjd
		    fd2tsu
		    fd2tsi
		    fd2ts
		    fd2fd
		    fd2of
		    et2fd
		    fd2et
		    dt2et
		    edt2dt
		    jd2jed
		    jed2jd
		    ts2ets
		    ets2ts
		    utdt
		    fd2ofd
		    fd2oft
		    fd2dt
		    fd2ep
		    fd2epb
		    fd2epj
		    dt2tsu
		    dt2tsi
		    dt2ts
		    ts2dt
		    tsi2dt
		    tsi2fd
		    tsi2ts
		    tsu2fd
		    tsu2dt
		    tsu2ts
		    tsu2tsi
		    ts2fd
		    dt2i
		    fd2i
		    ts2i
		    ut2doy
		    ut2dt
		    ut2ep
		    ut2epb
		    ut2epj
		    ut2fd
		    ut2jd
		    ut2mjd
		    ut2ts
		    ut2tsi
		    ut2tsu
		    fd2gst
		    dt2gst
		    ts2gst
		    fd2mst
		    dt2mst
		    ts2mst
		    jd2mst2
		    mjd2mst
		    compnut
		    isdate

		    FindStars
		    setparm
		    SetWCSFITS
		    settolerance
		    setirafout
		    setmatch

		    setreflim
		    setfitwcs
		    setfitplate
		    setminstars
		    setnofit
		    setfrac
		    setimfrac
		    setmaxcat
		    setiterate
		    setnfiterate
		    setiteratet
		    setrecenter
		    setsortmag
		    setmagfit
		    StarMatch
		    ParamFit
		    NParamFit
		    ReadMatch
		    WCSMatch
		    FitMatch
		    setresid_refine
		    getresid_refine
		    setnfit
		    getnfit
		    iscdfit
		    setminmatch
		    setminbin
		    setnitmax
		    FluxSortStars
		    MagSortStars
		    RASortStars
		    XSortStars
		    fitsrhead
		    fitsropen
		    fitsrtopen
		    fitsrthead
		    );

@EXPORT = ( );
@EXPORT_OK = (
	      @_constants,
	      @_functions,
	      );
%EXPORT_TAGS = (
		'constants' => \@_constants,
		'functions' => \@_functions,
		);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Astro::WCS::LibWCS macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap Astro::WCS::LibWCS $VERSION;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Astro::WCS::LibWCS - Perl interface to WCSTools libwcs

=head1 SYNOPSIS

  use Astro::WCS::LibWCS;                  # export nothing by default
  use Astro::WCS::LibWCS qw( :functions ); # export function names
  use Astro::WCS::LibWCS qw( :constants ); # export constant names

=head1 DESCRIPTION

This module is a Perl interface to the routines in the WCSTools libwcs
C library, by Doug Mink.  WCSTools is a package of programs and a
library for using the World Coordinate System (WCS). See
http://tdc-www.harvard.edu/software/wcstools/ for more information on
WCSTools.

=head1 Name-space issues

By default nothing is exported into your name-space when you C<use>
this package.  Instead, C<Astro::WCS::LibWCS> uses the C<Exporter>
module's support for name-space tags. The available tags are
C<:functions> and C<:constants>.

=head1 Deviations from libwcs

C<pix2wcst()> does not require the final C<$lstr> argument.

C<hgetm()> and C<hgets()> limit the length of the returned string to
the C<$lstr> argument given. If C<$lstr> is less than or equal to
zero, a maximum length of 2880 characters is used.


=head1 Matrix Arguments

A few libwcs functions require an array of doubles representing
matrices. These functions should be handed a Perl array reference
(multi-dimensional arrays are fine) with enough elements, once
completely unpacked, to satisfy the input demands of the function in
question. If one is using a module such as PDL, then direct passing of
the machine-formatted data is possible by using a scalar reference
which points to the information (e.g., $piddle->get_dataref).

=head1 Quasi-Object-Oriented Interface

C<Astro::WCS::LibWCS> provides, in addition to the normal libwcs
functions, an OO interface. One obtains an "object" by calling one of
C<wcsinit()>, C<wcsninit()>, C<wcsinitn()>, C<wcsninitn()>,
C<wcsinitc()>, C<wcsninitc()>, C<wcsxinit()> or C<wcskinit()>. The
actual object class is C<WCSPtr>. Any libwcs routines which expect the
first argument to be of type C<struct WorldCoor *> are blessed into
this class. As an added bonus, any of these routines which begin with
the string "wcs" can be called shorthand without the prefix.

=head2 Library routines

The following routines are blessed into the C<WCSPtr> class (along
with their shorthand names):

=over 4

=item wcsfree( ), free( )

=item wcstype( ), type( )

=item wcsreset( ), reset( )

=item wcseqset( ), eqset( )

=item wcscdset( ), cdset( )

=item wcsdeltset( ), deltset( )

=item wcspcset( ), pcset( )

=item wcsrotset( ), rotset( )

=item iswcs( )

=item nowcs( )

=item wcsshift( ), shift( )

=item wcscent( ), cent( )

=item wcssize( ), size( )

=item wcsfull( ), full( )

=item wcsrange( ), range( )

=item wcscominit( ), cominit( )

=item wcscom( ), com( )

=item wcsoutinit( ), outinit( )

=item getwcsout( )

=item wcsininit( ), ininit( )

=item getwcsin( )

=item setwcsdeg( )

=item wcsndec( ), ndec( )

=item getradecsys( )

=item setwcslin( )

=item pix2wcst( )

=item pix2wcs( )

=item wcs2pix( )

=item wcsc2pix( )

=item wcszout( ), zout( )

=item setwcscom( )

=item freewcscom( )

=item SetPlate( )

=item GetPlate( )

=item tnxclose( )

=item tnxpset( )

=back

=head2 Additional utility routines

These are available to retrieve the members of the WCSPtr struct.

=over 4

=item xref( )

=item yref( )

=item xrefpix( )

=item yrefpix( )

=item xinc( )

=item yinc( )

=back

=head1 BUGS

Likely many! Very little of the module has been tested. If you find
something that looks like a bug, please send a report.

=head1 AUTHOR

Pete Ratzlaff <pratzlaff@cfa.harvard.edu>

Contributors include:

=over 4

=item Diab Jerius <dj@head-cfa.harvard.edu>

=back

=head1 SEE ALSO

perl(1).

=cut
