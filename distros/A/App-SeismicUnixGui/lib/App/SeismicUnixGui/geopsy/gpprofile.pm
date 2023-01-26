package App::SeismicUnixGui::geopsy::gpprofile;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Gpprofile
  AUTHOR:  Derek Goff
  DATE:  May 5 2015
  DESCRIPTION:  A package to use geopsy's gpprofile function
		to resample Vs profiles from dinver
  VERSION: 0.1

=head2 Use

=head2 Notes

	This Program derives from dinver in Geopsy
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Gpprofile Notes

Usage: gpprofile [OPTIONS] [FILE1 [FILE2 ...]]

  Print profile computed from a layered model given through stdin or FILE
  
  Format for layered models:
    Line 1    <number of layers including half-space for first model>
    Line 2    <thickness (m)> <Vp (m/s)> <Vs (m/s)> <Density (kg/m3)>[ <Qp> <Qs>]
    ....
    Line n    0 <Vp (m/s)> <Vs (m/s)> <Density (kg/m3)>[ <Qp> <Qs>]
    Line n+1  <number of layers including half-space for second model>
    ....
  
  Quality factors are not mandatory. Any number of models can be given as input.

Profile type options:
  -vp                       Export Vp profiles
  -vs                       Export Vs profiles (default)
  -rho                      Export density profiles
  -nu                       Export Poisson's ratio profiles
  -imp                      Export impedance profiles

Output type options:
  -original                 Export profiles with original sampling from input models (default)
  -resample                 Export profiles with a custom sampling (see -h sampling for details)
  -average-profiles         Export averaged profiles with a custom sampling (see -h sampling for
                            details). Various profiles are averaged into one single output.
  -average-depths           Export averaged profiles with a custom sampling (see -h sampling for
                            details). Average is performed over the depth axis.
  -average-at <DEPTH>       Returns the average profile over DEPTH meters.
  -minmax                   Export minimum and maximum profiles with a custom sampling (see -h sampling
                            for details)

Depth sampling options:
  -d, -max-depth <DEPTH>    Maximum depth for resampled output types (default=100m)
  -n <N>                    Number of samples for resampled output types (default=100)
See also:
  More information at http://www.geopsy.org

Authors:
  Marc Wathelet
  Marc Wathelet (LGIT, Grenoble, France)

=cut

my $Gpprofile = {
    _Step     => '',
    _note     => '',
    _vp       => '',
    _vs       => '',
    _rho      => '',
    _nu       => '',
    _imp      => '',
    _original => '',
    _resample => '',
    _depth    => '',
    _samples  => '',
    _avgAt    => '',
    _file     => '',
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $Gpprofile->{_Step}     = '';
    $Gpprofile->{_note}     = '';
    $Gpprofile->{_original} = '';
    $Gpprofile->{_vp}       = '';
    $Gpprofile->{_vs}       = '';
    $Gpprofile->{_rho}      = '';
    $Gpprofile->{_nu}       = '';
    $Gpprofile->{_imp}      = '';
    $Gpprofile->{_resample} = '';
    $Gpprofile->{_depth}    = '';    #-d
    $Gpprofile->{_samples}  = '';    #-n
    $Gpprofile->{_avgAt}    = '';
    $Gpprofile->{_file}     = '';
}

####

=pod

=head2 Subroutine vp

	Export Vp profiles

=cut

sub vp {
    my ( $sub, $vp ) = @_;
    $Gpprofile->{_vp}   = $vp if defined($vp);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' -vp ' . $Gpprofile->{_vp};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' -vp ' . $Gpprofile->{_vp};
}

####

=pod

=head2 Subroutine vs

	Export Vs profiles (default)

=cut

sub vs {
    my ( $sub, $vs ) = @_;
    $Gpprofile->{_vs}   = $vs if defined($vs);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' -vs ' . $Gpprofile->{_vs};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' -vs ' . $Gpprofile->{_vs};
}

=head2 Subroutine original

	do not resample throughput
	leave the original sampling

=cut

sub original {
    my ( $sub, $original ) = @_;
    $Gpprofile->{_original} = $original if defined($original);
    $Gpprofile->{_note} =
      $Gpprofile->{_note} . ' -original ' . $Gpprofile->{_original};
    $Gpprofile->{_Step} =
      $Gpprofile->{_Step} . ' -original ' . $Gpprofile->{_original};
}
####

=pod

=head2 Subroutine rho

	Export density profiles

=cut

sub rho {
    my ( $sub, $rho ) = @_;
    $Gpprofile->{_rho}  = $rho if defined($rho);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' -rho ' . $Gpprofile->{_rho};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' -rho ' . $Gpprofile->{_rho};
}

####

=pod

=head2 Subroutine nu

	Export Poisson's ratio profiles

=cut

sub nu {
    my ( $sub, $nu ) = @_;
    $Gpprofile->{_nu}   = $nu if defined($nu);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' -nu ' . $Gpprofile->{_nu};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' -nu ' . $Gpprofile->{_nu};
}

####

=pod

=head2 Subroutine imp

	Export impedance profiles

=cut

sub imp {
    my ( $sub, $imp ) = @_;
    $Gpprofile->{_imp}  = $imp if defined($imp);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' -imp ' . $Gpprofile->{_imp};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' -imp ' . $Gpprofile->{_imp};
}

####

=pod

=head2 Subroutine resample

	Export profiles with a custom sampling

=cut

sub resample {
    my ( $sub, $resample ) = @_;
    $Gpprofile->{_resample} = $resample if defined($resample);
    $Gpprofile->{_note} =
      $Gpprofile->{_note} . ' -resample ' . $Gpprofile->{_resample};
    $Gpprofile->{_Step} =
      $Gpprofile->{_Step} . ' -resample ' . $Gpprofile->{_resample};
}

####

=pod

=head2 Subroutine depth or -d

	Max depth for resampled output types
	(default=100)

=cut

sub depth {
    my ( $sub, $depth ) = @_;
    $Gpprofile->{_depth} = $depth if defined($depth);
    $Gpprofile->{_note}  = $Gpprofile->{_note} . ' -d ' . $Gpprofile->{_depth};
    $Gpprofile->{_Step}  = $Gpprofile->{_Step} . ' -d ' . $Gpprofile->{_depth};
}

####

=pod

=head2 Subroutine samples

	Number of samples for resampled output
	(default=100)
	n

=cut

sub samples {
    my ( $sub, $samples ) = @_;
    $Gpprofile->{_samples} = $samples if defined($samples);
    $Gpprofile->{_note} =
      $Gpprofile->{_note} . ' -n ' . $Gpprofile->{_samples};
    $Gpprofile->{_Step} =
      $Gpprofile->{_Step} . ' -n ' . $Gpprofile->{_samples};
}

####

=pod

=head2 Subroutine avgAt

	Returns average profile over DEPTH meters
	Good for Vs30

=cut

sub avgAt {
    my ( $sub, $avgAt ) = @_;
    $Gpprofile->{_avgAt} = $avgAt if defined($avgAt);
    $Gpprofile->{_note} =
      $Gpprofile->{_note} . ' -avg-at ' . $Gpprofile->{_avgAt};
    $Gpprofile->{_Step} =
      $Gpprofile->{_Step} . ' -avg-at ' . $Gpprofile->{_avgAt};
}

####

=pod

=head2 Subroutine file

	Define Input file

=cut

sub file {
    my ( $sub, $file ) = @_;
    $Gpprofile->{_file} = $file if defined($file);
    $Gpprofile->{_note} = $Gpprofile->{_note} . ' ' . $Gpprofile->{_file};
    $Gpprofile->{_Step} = $Gpprofile->{_Step} . ' ' . $Gpprofile->{_file};
}

####

=pod

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $Gpprofile->{_Step} = 'gpprofile' . $Gpprofile->{_Step};
    return $Gpprofile->{_Step};
}

####

=pod

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $Gpprofile->{_note} = $Gpprofile->{_note};
    return $Gpprofile->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
