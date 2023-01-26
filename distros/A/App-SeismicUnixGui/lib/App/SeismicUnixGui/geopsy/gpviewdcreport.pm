package App::SeismicUnixGui::geopsy::gpviewdcreport;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Gpviewdcreport
  AUTHOR:  Derek Goff
  DATE:  May 5 2015
  DESCRIPTION:  A package to use geopsy's Gpviewdcreport function
		to calculate view dispersion curves from inversion
		reports
  VERSION: 0.1

=head2 Use

=head2 Notes

	This Program derives from dinver in Geopsy
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Gpviewdcreport Notes

Usage: gpviewdcreport [OPTIONS] [FILE]...

  Display ground profiles, dispersion curves, ellipticity curves, autocorrelation curves or refraction
  curves read from .report files. It is strictly equivalent to the 'view' options in dinver graphical
  interface. If options '-m', '-n' or other related options are specified the initial dialog box is
  skipped.

gpviewdcreport options:
  -profile                  Plot ground profiles (default)
  -dispersion               Plot dispersion curves
  -ellipticity              Plot ellipticity curves
  -autocorr                 Plot autocorrelation curves
  -refraVp                  Plot refraction curves for Vp
  -refraVs                  Plot refraction curves for Vs
  -m <MISFIT>               Maximum misfit to display
  -target <TARGET>          Set target shown above models read from .report files.
  -e, -export <FILE>        Export sheet contents to FILE. See 'figue -h' for more details.
  -f, -format <FORMAT>      Specify format for option '-export'. See 'figue -h' for more details.
  -dpi <DPI>                Forces resolution to DPI(dot per inch) in export file. See 'figue -h' for
                            more details.

Profile options:
  -n <N>                    Number of profiles

Dispersion options:
  -n <N>                    Number of modes
  -s <SLOWNESS>             Slowness type: Group or Phase
  -p <POLARISATION>         Polarisation: Rayleigh or Love

Ellipticity options:
  -n <N>                    Number of modes

Autocorr options:
  -n <N>                    Number of rigns
  -p <POLARISATION>         Polarisation: Vertical, Transverse or Radial

Refra options:
  -n <N>                    Number of sources

Qt options:
  -nograb                   Tells Qt that it must never grab the mouse or the keyboard
  -dograb                   Running under a debugger can cause an implicit -nograb, use -dograb to
                            override
  -sync                     Switches to synchronous mode for debugging
  -style <style>            Sets the application GUI style. Possible values are
                              motif
                              windows
                              platinum
                            If you compiled Qt with additional styles or have additional styles as
                            plugins these will be available to the -style command line option
  -session <session>        Restore the application from an earlier session
  -reverse                  Sets the application's layout direction to right to left
  -display <display>        Sets the X display (default is $DISPLAY)
  -geometry <geometry>      Sets the client geometry of the first window that is shown
  -fn, -font <font>         Defines the application font. The font should be specified using an X logical
                            font description
  -bg, -background <color>  Sets the default background color and an application palette (light and dark
                            shades are calculated)
  -fg, -foreground <color>  Sets the default foreground color
  -btn, -button <color>     Sets the default button color
  -name <name>              Sets the application name
  -title <title>            Sets the application title
  -visual TrueColor         Forces the application to use a TrueColor visual on an 8-bit display
  -ncols <count>            Limits the number of colors allocated in the color cube on an 8-bit display,
                            if the application is using the QApplication::ManyColor color specification.
                            If count is 216 then a 6x6x6 color cube is used (i.e. 6 levels of red, 6 of
                            green, and 6 of blue); for other values, a cube approximately proportional to
                            a 2x3x1 cube is used
  -cmap <count>             Causes the application to install a private color map on an 8-bit display
  -im <XIM server>          Sets the input method server (equivalent to setting the XMODIFIERS
                            environment variable)
  -noxim                    Disables the input method framework ("no X input method")
  -inputstyle <inputstyle>  Defines how the input is inserted into the given widget. Possible values are:
                              onTheSpot makes the input appear directly in the widget
                              offTheSpot
                              overTheSpot makes the input appear in a box floating over the widget

See also:
  More information at http://www.geopsy.org

Authors:
  Marc Wathelet
  Marc Wathelet (LGIT, Grenoble, France)

=cut

my $Gpviewdcreport = {
    _Step         => '',
    _note         => '',
    _profile      => '',
    _dispersion   => '',
    _maxmis       => '',
    _export       => '',
    _format       => '',
    _nprofile     => '',
    _nmodes       => '',
    _slowness     => '',
    _polarisation => '',
    _target       => '',
    _dpi          => '',
    _file         => '',
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $Gpviewdcreport->{_Step}         = '';
    $Gpviewdcreport->{_note}         = '';
    $Gpviewdcreport->{_profile}      = '';
    $Gpviewdcreport->{_dispersion}   = '';
    $Gpviewdcreport->{_maxmis}       = '';
    $Gpviewdcreport->{_export}       = '';
    $Gpviewdcreport->{_format}       = '';
    $Gpviewdcreport->{_nprofile}     = '';
    $Gpviewdcreport->{_nmodes}       = '';
    $Gpviewdcreport->{_slowness}     = '';
    $Gpviewdcreport->{_polarisation} = '';
    $Gpviewdcreport->{_target}       = '';
    $Gpviewdcreport->{_dpi}          = '';
    $Gpviewdcreport->{_file}         = '';
}

####

=pod

=head2 Subroutine profile

	Plot ground profiles (default)

=cut

sub profile {
    my ( $sub, $profile ) = @_;
    $Gpviewdcreport->{_profile} = $profile if defined($profile);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -profile ' . $Gpviewdcreport->{_profile};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -profile ' . $Gpviewdcreport->{_profile};
}

####

=pod

=head2 Subroutine dispersion

	Plot Dispersion curves

=cut

sub dispersion {
    my ( $sub, $dispersion ) = @_;
    $Gpviewdcreport->{_dispersion} = $dispersion if defined($dispersion);
    $Gpviewdcreport->{_note} =
        $Gpviewdcreport->{_note}
      . ' -dispersion '
      . $Gpviewdcreport->{_dispersion};
    $Gpviewdcreport->{_Step} =
        $Gpviewdcreport->{_Step}
      . ' -dispersion '
      . $Gpviewdcreport->{_dispersion};
}

####

=pod

=head2 Subroutine maxmis

	Maximum misfit to display

=cut

sub maxmis {
    my ( $sub, $maxmis ) = @_;
    $Gpviewdcreport->{_maxmis} = $maxmis if defined($maxmis);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -m ' . $Gpviewdcreport->{_maxmis};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -m ' . $Gpviewdcreport->{_maxmis};
}

####

=pod

=head2 Subroutine export

	Export sheet contents to <file>

=cut

sub export {
    my ( $sub, $export ) = @_;
    $Gpviewdcreport->{_export} = $export if defined($export);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -export ' . $Gpviewdcreport->{_export};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -export ' . $Gpviewdcreport->{_export};
}

####

=pod

=head2 Subroutine format

	Specify format for export <file>
	Options: PAGE,LAYER,PDF,BMP,JPG,JPEG,PNG,SVG
	See figue -h for more options

=cut

sub format {
    my ( $sub, $format ) = @_;
    $Gpviewdcreport->{_format} = $format if defined($format);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -format ' . $Gpviewdcreport->{_format};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -format ' . $Gpviewdcreport->{_format};
}

####

=pod

=head2 Subroutine nprofile

	Number of profiles to show from ground profiles (-profile)

=cut

sub nprofile {
    my ( $sub, $nprofile ) = @_;
    $Gpviewdcreport->{_nprofile} = $nprofile if defined($nprofile);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -n ' . $Gpviewdcreport->{_nprofile};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -n ' . $Gpviewdcreport->{_nprofile};
}

####

=pod

=head2 Subroutine nmodes

	Number of Modes for dispersion and ellipticity

=cut

sub nmodes {
    my ( $sub, $nmodes ) = @_;
    $Gpviewdcreport->{_nmodes} = $nmodes if defined($nmodes);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -n ' . $Gpviewdcreport->{_nmodes};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -n ' . $Gpviewdcreport->{_nmodes};
}

####

=pod

=head2 Subroutine slowness

	Slowness type: Group or Phase

=cut

sub slowness {
    my ( $sub, $slowness ) = @_;
    $Gpviewdcreport->{_slowness} = $slowness if defined($slowness);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -s ' . $Gpviewdcreport->{_slowness};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -s ' . $Gpviewdcreport->{_slowness};
}

####

=pod

=head2 Subroutine polarisation

	Polarisation: Rayleigh or Love

=cut

sub polarisation {
    my ( $sub, $polarisation ) = @_;
    $Gpviewdcreport->{_polarisation} = $polarisation
      if defined($polarisation);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -p ' . $Gpviewdcreport->{_polarisation};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -p ' . $Gpviewdcreport->{_polarisation};
}

####

=pod

=head2 Subroutine target

	Set target shown above models read from .report file

=cut

sub target {
    my ( $sub, $target ) = @_;
    $Gpviewdcreport->{_target} = $target if defined($target);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -target ' . $Gpviewdcreport->{_target};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -target ' . $Gpviewdcreport->{_target};
}

####

=pod

=head2 Subroutine dpi

	Forces resolution of DPI (Dot per inch) in export file

=cut

sub dpi {
    my ( $sub, $dpi ) = @_;
    $Gpviewdcreport->{_dpi} = $dpi if defined($dpi);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' -dpi ' . $Gpviewdcreport->{_dpi};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' -dpi ' . $Gpviewdcreport->{_dpi};
}

####

=pod

=head2 Subroutine file

	Define Input file

=cut

sub file {
    my ( $sub, $file ) = @_;
    $Gpviewdcreport->{_file} = $file if defined($file);
    $Gpviewdcreport->{_note} =
      $Gpviewdcreport->{_note} . ' ' . $Gpviewdcreport->{_file};
    $Gpviewdcreport->{_Step} =
      $Gpviewdcreport->{_Step} . ' ' . $Gpviewdcreport->{_file};
}

####

=pod

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $Gpviewdcreport->{_Step} = 'gpviewdcreport' . $Gpviewdcreport->{_Step};
    return $Gpviewdcreport->{_Step};
}

####

=pod

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $Gpviewdcreport->{_note} = $Gpviewdcreport->{_note};
    return $Gpviewdcreport->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;

