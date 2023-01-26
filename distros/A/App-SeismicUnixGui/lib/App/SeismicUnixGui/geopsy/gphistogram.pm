package App::SeismicUnixGui::geopsy::gphistogram;
use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Gphistogram
  AUTHOR:  Derek Goff
  DATE:  May 5 2015
  DESCRIPTION:  A package to use geopsy's gphistogram function
		to calculate average Vs curve and standard
		deviation.
  VERSION: 0.1

=head2 Use

=head2 Notes

	This Program derives from dinver in Geopsy
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Gphistogram Notes

Usage: gphistogram [OPTIONS]

  From two columns (x, y) provided through stdin, it produces a grid and count the number of hits in each
  cell. A median or mean curve can be directly computed or the histogram is plotted. Editing and
  filtering is then possible.

gphistogram options:
  -mean                     Output mean curve and exit.
  -median                   Output median curve and exit.
  -grid                     Output grid values and exit.
  -x-sampling <SAMPLING>    Defines the X sampling type:
                              linear     regular sampling (default)
                              log        regular sampling on a log scale
                              inversed   regular sampling on an inversed
  -x-min <MIN>              Minimum of range for X axis (default=deduced from data)
  -x-max <MAX>              Maximum of range for X axis (default=deduced from data)
  -x-count <COUNT>          Number of samples along X (default=100)
  -y-sampling <SAMPLING>    Defines the Y sampling type:
                              linear     regular sampling (default)
                              log        regular sampling on a log scale
                              inversed   regular sampling on an inversed
  -y-min <MIN>              Minimum of range for Y axis (default=deduced from data)
  -y-max <MAX>              Maximum of range for Y axis (default=deduced from data)
  -y-count <COUNT>          Number of samples along Y (default=100)

=cut

my $Gphistogram = {
    _Step    => '',
    _note    => '',
    _mean    => '',
    _median  => '',
    _grid    => '',
    _xsample => '',
    _xmin    => '',
    _xmax    => '',
    _xcount  => '',
    _ysample => '',
    _ymin    => '',
    _ymax    => '',
    _ycount  => '',
    _file    => '',
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $Gphistogram->{_Step}    = '';
    $Gphistogram->{_note}    = '';
    $Gphistogram->{_mean}    = '';
    $Gphistogram->{_median}  = '';
    $Gphistogram->{_grid}    = '';
    $Gphistogram->{_xsample} = '';
    $Gphistogram->{_xmin}    = '';
    $Gphistogram->{_xmax}    = '';
    $Gphistogram->{_xcount}  = '';
    $Gphistogram->{_ysample} = '';
    $Gphistogram->{_ymin}    = '';
    $Gphistogram->{_ymax}    = '';
    $Gphistogram->{_ycount}  = '';
    $Gphistogram->{_file}    = '';
}

####

=pod

=head2 Subroutine mean

	Output mean curve and exit

=cut

sub mean {
    my ( $sub, $mean ) = @_;
    $Gphistogram->{_mean} = $mean if defined($mean);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -mean ' . $Gphistogram->{_mean};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -mean ' . $Gphistogram->{_mean};
}

####

=pod

=head2 Subroutine median

	Output median curve and exit

=cut

sub median {
    my ( $sub, $median ) = @_;
    $Gphistogram->{_median} = $median if defined($median);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -median ' . $Gphistogram->{_median};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -median ' . $Gphistogram->{_median};
}

####

=pod

=head2 Subroutine grid

	Output grid values and exit

=cut

sub grid {
    my ( $sub, $grid ) = @_;
    $Gphistogram->{_grid} = $grid if defined($grid);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -grid ' . $Gphistogram->{_grid};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -grid ' . $Gphistogram->{_grid};
}

####

=pod

=head2 Subroutine xsample

	Define X sampling type:
	linear (default), log, or inversed

=cut

sub xsample {
    my ( $sub, $xsample ) = @_;
    $Gphistogram->{_xsample} = $xsample if defined($xsample);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -x-sampling ' . $Gphistogram->{_xsample};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -x-sampling ' . $Gphistogram->{_xsample};
}

####

=pod

=head2 Subroutine xmin

	Minimum range for X axis (default from data)

=cut

sub xmin {
    my ( $sub, $xmin ) = @_;
    $Gphistogram->{_xmin} = $xmin if defined($xmin);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -x-min ' . $Gphistogram->{_xmin};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -x-min ' . $Gphistogram->{_xmin};
}

####

=pod

=head2 Subroutine xmax

	Maximum range for X axis (default from data)

=cut

sub xmax {
    my ( $sub, $xmax ) = @_;
    $Gphistogram->{_xmax} = $xmax if defined($xmax);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -x-max ' . $Gphistogram->{_xmax};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -x-max ' . $Gphistogram->{_xmax};
}

####

=pod

=head2 Subroutine xcount

	Number of samples along X (default=100)

=cut

sub xcount {
    my ( $sub, $xcount ) = @_;
    $Gphistogram->{_xcount} = $xcount if defined($xcount);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -x-count ' . $Gphistogram->{_xcount};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -x-count ' . $Gphistogram->{_xcount};
}

####

=pod

=head2 Subroutine ysample

	Define Y sampling type:
	linear (default), log, or inversed


=cut

sub ysample {
    my ( $sub, $ysample ) = @_;
    $Gphistogram->{_ysample} = $ysample if defined($ysample);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -y-sampling ' . $Gphistogram->{_ysample};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -y-sampling ' . $Gphistogram->{_ysample};
}

####

=pod

=head2 Subroutine ymin

	Minimum range for Y axis (default from data)

=cut

sub ymin {
    my ( $sub, $ymin ) = @_;
    $Gphistogram->{_ymin} = $ymin if defined($ymin);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -y-min ' . $Gphistogram->{_ymin};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -y-min ' . $Gphistogram->{_ymin};
}

####

=pod

=head2 Subroutine ymax

	Maximum range for Y axis (default from data)

=cut

sub ymax {
    my ( $sub, $ymax ) = @_;
    $Gphistogram->{_ymax} = $ymax if defined($ymax);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -y-max ' . $Gphistogram->{_ymax};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -y-max ' . $Gphistogram->{_ymax};
}

####

=pod

=head2 Subroutine ycount

	Number of samples along Y (default=100)

=cut

sub ycount {
    my ( $sub, $ycount ) = @_;
    $Gphistogram->{_ycount} = $ycount if defined($ycount);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' -y-count ' . $Gphistogram->{_ycount};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' -y-count ' . $Gphistogram->{_ycount};
}

####

=pod

=head2 Subroutine file

	Define Input file

=cut

sub file {
    my ( $sub, $file ) = @_;
    $Gphistogram->{_file} = $file if defined($file);
    $Gphistogram->{_note} =
      $Gphistogram->{_note} . ' ' . $Gphistogram->{_file};
    $Gphistogram->{_Step} =
      $Gphistogram->{_Step} . ' ' . $Gphistogram->{_file};
}

####

=pod

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $Gphistogram->{_Step} = 'gphistogram' . $Gphistogram->{_Step};
    return $Gphistogram->{_Step};
}

####

=pod

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $Gphistogram->{_note} = $Gphistogram->{_note};
    return $Gphistogram->{_note};
}

=pod

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
