package App::SeismicUnixGui::geopsy::gpdcreport;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Gpdcreport
  AUTHOR:  Derek Goff
  DATE:  May 2 2015
  DESCRIPTION:  A package to use geopsy's gpdcreport function
		to extract information from report files
  VERSION: 0.1

=head2 Use

=head2 Notes

	This Program derives from dinver in Geopsy
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Gpdcreport Notes

Usage: gpdcreport [OPTIONS] [FILE] ...

  Read .report file produced by inversion and extract to stdout ground models, dispersion curves, spac curves...
  (see options)

Gpdcreport options:
  -n <MAX>                  Maximum number of models to output (default = no maximum)
  -m <MAX>                  Maximum misfit to output (default = 1e99)
  -best <N>                 Output only the N models with the minimum misfit (supported only for current .report
                            format and without option '-index'.
  -index                    Select models by index in file. Indexes are passed through stdin.
  -pm                       Output parameters and misfit to stdout
  -checksum                 Output the parameterization checksum to stdout
  -count                    Output the number of models to stdout
  -gm                       Output ground models to stdout (default)
  -tgmVp                    Output Vp tilt ground models to stdout (used for refraction)
  -tgmVs                    Output Vs tilt ground models to stdout (used for refraction)
  -vp                       Output Vp profiles to stdout
  -vs                       Output Vs profiles to stdout
  -rho                      Output Density profiles to stdout
  -pitch                    Output Pitch profiles to stdout
  -pR <mode>                Output mode Rayleigh Phase dispersion curves to stdout
  -gR <mode>                Output mode Rayleigh Group dispersion curves to stdout
  -pL <mode>                Output mode Love Phase dispersion curves to stdout
  -gL <mode>                Output mode Love Group dispersion curves to stdout
  -e <mode>                 Output mode ellipticity curve to stdout
  -aV <mode>                Output mode vertical autocorrelation curve to stdout
  -aR <mode>                Output mode radial autocorrelation curve to stdout
  -aT <mode>                Output mode transverse autocorrelation curve to stdout
  -refraVp <source>         Output Vp travel time curve for source index to stdout
  -refraVs <source>         Output Vs travel time curve for source index to stdout
  -ring <index>             Add one ring to list of rings to output (default=nothing)
  -o <FILE>                 Export selected models to FILE with the current binary format for .report files. This
                            option may be usefull to convert old .report files produced by na_viewer or first dinver
                            releases.
  -compat <TYPE>            Compatibility with previous versions of .report format. TYPE may take the following
                            values:
                              na_viewer   old .report as output by the ancestor of dinver (before 2005).
                              beta        first release of the new .report format (not yet support for implicit mode
                                          guess specification). All releases from year 2006 and end of 2005.
                              current     .report produced by current releases of dinver. All releases since
                                          beginning of year 2007.Versioning implemented in this format should
                                          guarantee the future support for this format.

Generic options:
  -h, -help [<SECTION>]     Shows help. SECTION may be empty or: all, html, latex, generic, debug, examples,
                            gpdcreport
  -version                  Shows version information
  -app-version              Shows short version information
  -j, -jobs <N>             Allows a maximum of N simulteneous jobs for parallel computations (default=8).

Debug options:
  -nobugreport              Does not generate bug reports in case of error.
  -reportbug                Starts bug report dialog, information about bug is passed through stdin. This option is
                            used internally to report bugs if option -nobugreport is not specified.
  -reportint                Starts bug report dialog, information about interruption is passed through stdin. This
                            option is used internally to report interruptions if option -nobugreport is not
                            specified.

Examples:

         gpdcreport run_01.report

  Output first 1000 ground models with a misfit less than 1.

         gpdcreport run_01.report | gpell -c

  Re-compute ellipticity curves for the same set of models.

         gpdcreport run_01.report | gpell -p

  Re-compute peak ellipticity frequencies for the same set of models.

         gpdcreport run_01.report -e 0

  Output ellipticity curves for the same set of models (if any stored).

See also:
  More information at http://www.geopsy.org

Authors:
  Marc Wathelet
  Marc Wathelet (LGIT, Grenoble, France)
=cut

my $Gpdcreport = {
    _Step   => '',
    _note   => '',
    _maxmod => '',
    _maxmis => '',
    _best   => '',
    _index  => '',
    _pm     => '',
    _gm     => '',
    _vp     => '',
    _vs     => '',
    _pR     => '',
    _pL     => '',
    _file   => '',
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $Gpdcreport->{_Step}   = '';
    $Gpdcreport->{_note}   = '';
    $Gpdcreport->{_maxmod} = '';
    $Gpdcreport->{_maxmis} = '';
    $Gpdcreport->{_best}   = '';
    $Gpdcreport->{_index}  = '';
    $Gpdcreport->{_pm}     = '';
    $Gpdcreport->{_gm}     = '';
    $Gpdcreport->{_vp}     = '';
    $Gpdcreport->{_vs}     = '';
    $Gpdcreport->{_pR}     = '';
    $Gpdcreport->{_pL}     = '';
    $Gpdcreport->{_file}   = '';
}

####

=pod

=head2 Subroutine maxmod

	Maximum number of models to output
	default = no maximum

=cut

sub maxmod {
    my ( $sub, $maxmod ) = @_;
    $Gpdcreport->{_maxmod} = $maxmod if defined($maxmod);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -n ' . $Gpdcreport->{_maxmod};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -n ' . $Gpdcreport->{_maxmod};
}

####

=pod

=head2 Subroutine maxmis

	Maximum misfit to output
	default = 1e99

=cut

sub maxmis {
    my ( $sub, $maxmis ) = @_;
    $Gpdcreport->{_maxmis} = $maxmis if defined($maxmis);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -m ' . $Gpdcreport->{_maxmis};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -m ' . $Gpdcreport->{_maxmis};
}

####

=pod

=head2 Subroutine best

	Output only N models with minimum misfit

=cut

sub best {
    my ( $sub, $best ) = @_;
    $Gpdcreport->{_best} = $best if defined($best);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -best ' . $Gpdcreport->{_best};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -best ' . $Gpdcreport->{_best};
}

####

=pod

=head2 Subroutine index

	Select models by index in file
	Indexes are passed through stdin

=cut

sub index {
    my ( $sub, $index ) = @_;
    $Gpdcreport->{_index} = $index if defined($index);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -index ' . $Gpdcreport->{_index};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -index ' . $Gpdcreport->{_index};
}

####

=pod

=head2 Subroutine pm

	Output parameters and misfit to stdout

=cut

sub pm {
    my ( $sub, $pm ) = @_;
    $Gpdcreport->{_pm} = $pm if defined($pm);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -pm ' . $Gpdcreport->{_pm};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -pm ' . $Gpdcreport->{_pm};
}

####

=pod

=head2 Subroutine gm

	Output ground models to stdout (default)

=cut

sub gm {
    my ( $sub, $gm ) = @_;
    $Gpdcreport->{_best} = $gm if defined($gm);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -gm ' . $Gpdcreport->{_gm};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -gm ' . $Gpdcreport->{_gm};
}

####

=pod

=head2 Subroutine vp

	Output Vp profiles to stdout

=cut

sub vp {
    my ( $sub, $vp ) = @_;
    $Gpdcreport->{_vp} = $vp if defined($vp);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -vp ' . $Gpdcreport->{_vp};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -vp ' . $Gpdcreport->{_vp};
}

####

=pod

=head2 Subroutine vs

	Output Vs profiles to stdout

=cut

sub vs {
    my ( $sub, $vs ) = @_;
    $Gpdcreport->{_vs} = $vs if defined($vs);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -vs ' . $Gpdcreport->{_vs};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -vs ' . $Gpdcreport->{_vs};
}

####

=pod

=head2 Subroutine pR

	Output mode Rayleigh Phase dispersion curves to stdout

=cut

sub pR {
    my ( $sub, $pR ) = @_;
    $Gpdcreport->{_pR} = $pR if defined($pR);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -pR ' . $Gpdcreport->{_pR};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -pR ' . $Gpdcreport->{_pR};
}

####

=pod

=head2 Subroutine pL

	Output mode Love hase dispersion curves to stdout

=cut

sub pL {
    my ( $sub, $pL ) = @_;
    $Gpdcreport->{_pL} = $pL if defined($pL);
    $Gpdcreport->{_note} =
      $Gpdcreport->{_note} . ' -pL ' . $Gpdcreport->{_pL};
    $Gpdcreport->{_Step} =
      $Gpdcreport->{_Step} . ' -pL ' . $Gpdcreport->{_pL};
}

####

=pod

=head2 Subroutine file

	Define Input file

=cut

sub file {
    my ( $sub, $file ) = @_;
    $Gpdcreport->{_file} = $file if defined($file);
    $Gpdcreport->{_note} = $Gpdcreport->{_note} . ' ' . $Gpdcreport->{_file};
    $Gpdcreport->{_Step} = $Gpdcreport->{_Step} . ' ' . $Gpdcreport->{_file};
}

####

=pod

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $Gpdcreport->{_Step} = 'gpdcreport' . $Gpdcreport->{_Step};
    return $Gpdcreport->{_Step};
}

####

=pod

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $Gpdcreport->{_note} = $Gpdcreport->{_note};
    return $Gpdcreport->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
