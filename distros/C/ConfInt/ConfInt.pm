package ConfInt;

=head1 NAME
 
ConfInt - Perl extension for calculating the confidence interval of
          meassured values.
 
=head1 SYNOPSIS
 
        use ConfInt;
        ConfInt([ARGUMENT_1],[ARGUMENT_2]);
 
=head1 DESCRIPTION
 
This module calculates and returns the relative error of the turned
over values. ConfInt needs two things to be turned over: 1st is the
width of the confidence interval. 2nd is the reference to an array
including the values.
Supported confidence interval width:
 
        0.7             (+/- 0.35) ; probability of 0.65
        0.6             (+/- 0.30) ; probability of 0.70
        0.5             (+/- 0.25) ; probability of 0.75
        0.4             (+/- 0.20) ; probability of 0.80
        0.3             (+/- 0.15) ; probability of 0.85
        0.2             (+/- 0.10) ; probability of 0.90
        0.1             (+/- 0.05) ; probability of 0.95
        0.05            (+/- 0.025); probability of 0.975
        0.02            (+/- 0.01) ; probability of 0.99
        0.01            (+/- 0.005); probability of 0.995
 
EXAMPLE:
        use ConfInt;
        @ValueArray = (1,1,1,1,1,2,3,2,1,1,1,1,2,1);
        $ReturnValue = &ConfInt::ConfInt(0.05,\@ValueArray);
        print "$ReturnValue";
 
=head1 EXPORT
 
Returns the relative error of a summary of values.
 
 
=head1 AUTHOR
 
written by Christian Gernhardt <christian.gernhardt@web.de>
 
=head1 COPYRIGHT
 
Copyright (C) 2001 IBM Deutschland Entwicklung GmbH, IBM Corporation
 
=head1 SEE ALSO
 
perl(1).
 
=cut
 
require Exporter;
 
our @ISA = qw(Exporter);
 
our %EXPORT_TAGS = ( 'all' => [ qw(
 
) ] );
 
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
 
our @EXPORT = qw(
 
);
our $VERSION = '1.0.1';

# ###########################
# ## Begin of ConfInt Code ##
# ###########################

sub ConfInt {

  #
  # Measurement value-array
  #
  $MEAS_VALUES_REF = $_[1];
  @MEAS_VALUES = @$MEAS_VALUES_REF;

  #
  # number of measurement values
  #
  $NUM_MEAS_VALUES = 0;

  foreach(@MEAS_VALUES) {
    $NUM_MEAS_VALUES++;
  }

  #
  # selection of t-distribution array
  #
  if($_[0] == 0.7) {

    #
    # probability 0.65 (intervalsize: 0.7; +/- 0.35); degree of freedom 1...25
    #
    @TDISTRIB_07 = (0.510, 0.445, 0.424, 0.414, 0.408, 0.404, 0.402, 0.399, 0.398, 0.397, 0.396, 0.395, 0.394, 0.393, 0.393, 0.392, 0.392, 0.392, 0.391, 0.391, 0.391, 0.390, 0.390, 0.390, 0.390);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_07[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 0.389; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 0.388; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 0.388; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 0.387; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 0.387; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 0.387; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 0.387; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 0.386; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 0.386; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 0.386; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 0.386; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 0.385; }
        if($k >= 1000)            { $TDISTRIB[$k] = 0.384; }
      }
    }
  }

  elsif($_[0] == 0.6) {

    #
    # probability 0.7 (intervalsize: 0.6; +/- 0.3); degree of freedom 1...25
    #
    @TDISTRIB_06 = (0.727, 0.617, 0.584, 0.569, 0.559, 0.553, 0.549, 0.546, 0.543, 0.542, 0.540, 0.539, 0.538, 0.537, 0.536, 0.535, 0.534, 0.534, 0.533, 0.533, 0.532, 0.532, 0.532, 0.531, 0.531);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_06[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 0.530; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 0.529; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 0.528; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 0.527; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 0.527; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 0.526; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 0.526; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 0.526; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 0.526; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 0.525; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 0.525; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 0.525; }
        if($k >= 1000)            { $TDISTRIB[$k] = 0.524; }
      }
    }
  }

  elsif($_[0] == 0.5) {

    #
    # probability 0.75 (intervalsize: 0.5; +/- 0.25); degree of freedom 1...25
    #
    @TDISTRIB_05 = (1.000, 0.816, 0.765, 0.741, 0.727, 0.718, 0.711, 0.706, 0.703, 0.700, 0.697, 0.695, 0.694, 0.692, 0.691, 0.690, 0.689, 0.688, 0.688, 0.687, 0.686, 0.686, 0.685, 0.685, 0.684);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_05[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 0.683; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 0.681; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 0.679; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 0.679; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 0.678; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 0.678; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 0.677; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 0.677; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 0.676; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 0.676; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 0.675; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 0.675; }
        if($k >= 1000)            { $TDISTRIB[$k] = 0.674; }
      }
    }
  }

  elsif($_[0] == 0.4) {

    #
    # probability 0.8 (intervalsize: 0.4; +/- 0.2); degree of freedom 1...25
    #
    @TDISTRIB_04 = (1.376, 1.061, 0.978, 0.941, 0.920, 0.906, 0.896, 0.889, 0.883, 0.879, 0.876, 0.873, 0.870, 0.868, 0.866, 0.865, 0.863, 0.862, 0.861, 0.860, 0.859, 0.858, 0.858, 0.857, 0.856);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_04[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 0.854; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 0.851; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 0.849; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 0.848; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 0.847; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 0.846; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 0.846; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 0.845; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 0.844; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 0.843; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 0.842; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 0.842; }
        if($k >= 1000)            { $TDISTRIB[$k] = 0.841; }
      }
    }
  }

  elsif($_[0] == 0.3) {

    #
    # probability 0.85 (intervalsize: 0.3; +/- 0.15); degree of freedom 1...25
    #
    @TDISTRIB_03 = (1.963, 1.386, 1.250, 1.190, 1.156, 1.134, 1.119, 1.108, 1.100, 1.093, 1.088, 1.083, 1.079, 1.076, 1.074, 1.071, 1.069, 1.067, 1.066, 1.064, 1.063, 1.061, 1.060, 1.059, 1.058);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_03[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 1.055; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 1.050; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 1.047; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 1.045; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 1.044; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 1.043; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 1.042; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 1.042; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 1.040; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 1.039; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 1.038; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 1.037; }
        if($k >= 1000)            { $TDISTRIB[$k] = 1.036; }
      }
    }
  }

  elsif($_[0] == 0.2) {

    #
    # probability 0.9 (intervalsize: 0.2; +/- 0.1); degree of freedom 1...25
    #
    @TDISTRIB_02 = (3.078, 1.886, 1.638, 1.533, 1.476, 1.440, 1.415, 1.397, 1.383, 1.372, 1.363, 1.356, 1.350, 1.345, 1.341, 1.337, 1.333, 1.330, 1.328, 1.325, 1.323, 1.321, 1.319, 1.318, 1.316);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_02[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 1.310; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 1.303; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 1.299; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 1.296; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 1.294; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 1.292; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 1.291; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 1.290; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 1.287; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 1.286; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 1.283; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 1.282; }
        if($k >= 1000)            { $TDISTRIB[$k] = 1.281; }
      }
    }
  }

  elsif($_[0] == 0.1) {

    #
    # probability 0.95 (intervalsize: 0.1; +/- 0.05); degree of freedom 1...25
    #
    @TDISTRIB_01 = (6.314, 2.92, 2.353, 2.132, 2.015, 1.943, 1.895, 1.860, 1.833, 1.812, 1.796, 1.782, 1.771, 1.761, 1.753, 1.746, 1.740, 1.734, 1.729, 1.725, 1.721, 1.717, 1.714, 1.711, 1.708);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_01[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 1.697; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 1.684; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 1.676; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 1.671; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 1.667; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 1.664; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 1.662; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 1.660; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 1.655; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 1.653; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 1.648; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 1.646; }
        if($k >= 1000)            { $TDISTRIB[$k] = 1.644; }
      }
    }
  }

  elsif($_[0] == 0.05) {

    #
    # probability 0.975 (intervalsize: 0.05; +/- 0.025); degree of freedom 1...25
    #
    @TDISTRIB_005 = (12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228, 2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101, 2.093, 2.086, 2.080, 2.074, 2.069, 2.064, 2.060);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_005[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 2.042; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 2.021; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 2.009; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 2.000; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 1.994; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 1.990; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 1.987; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 1.984; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 1.976; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 1.972; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 1.965; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 1.962; }
        if($k >= 1000)            { $TDISTRIB[$k] = 1.960; }
      }
    }
  }

  elsif($_[0] == 0.02) {

    #
    # probability 0.99 (intervalsize: 0.02; +/- 0.01); degree of freedom 1...25
    #
    @TDISTRIB_002 = (31.821, 6.965, 4.541, 3.747, 3.365, 3.143, 2.998, 2.896, 2.821, 2.764, 2.718, 2.681, 2.650, 2.624, 2.602, 2.583, 2.567, 2.552, 2.539, 2.528, 2.518, 2.508, 2.500, 2.492, 2.485);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_002[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 2.457; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 2.423; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 2.403; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 2.390; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 2.381; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 2.374; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 2.368; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 2.364; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 2.351; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 2.345; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 2.334; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 2.330; }
        if($k >= 1000)            { $TDISTRIB[$k] = 2.328; }
      }
    }
  }

  elsif($_[0] == 0.01) {

    #
    # probability 0.995 (intervalsize: 0.01; +/- 0.005); degree of freedom 1...25
    #
    @TDISTRIB_001 = (63.656, 9.952, 5.841, 4.604, 4.032, 3.707, 3.499, 3.355, 3.250, 3.169, 3.106, 3.055, 3.012, 2.977, 2.947, 2.921, 2.898, 2.878, 2.861, 2.845, 2.831, 2.819, 2.807, 2.797, 2.787);

    for($k=0;$k<$NUM_MEAS_VALUES;$k++) {
      if($k < 25) {
        $TDISTRIB[$k] = $TDISTRIB_001[$k]; 
      }
      if($k >= 25) {
        if($k < 30 && $k >= 25)   { $TDISTRIB[$k] = 2.750; }
        if($k < 40 && $k >= 30)   { $TDISTRIB[$k] = 2.704; }
        if($k < 50 && $k >= 40)   { $TDISTRIB[$k] = 2.678; }
        if($k < 60 && $k >= 50)   { $TDISTRIB[$k] = 2.660; }
        if($k < 70 && $k >= 60)   { $TDISTRIB[$k] = 2.648; }
        if($k < 80 && $k >= 70)   { $TDISTRIB[$k] = 2.639; }
        if($k < 90 && $k >= 80)   { $TDISTRIB[$k] = 2.632; }
        if($k < 100 && $k >= 90)  { $TDISTRIB[$k] = 2.626; }
        if($k < 150 && $k >= 100) { $TDISTRIB[$k] = 2.609; }
        if($k < 200 && $k >= 150) { $TDISTRIB[$k] = 2.601; }
        if($k < 500 && $k >= 200) { $TDISTRIB[$k] = 2.586; }
        if($k < 1000 && $k >= 500){ $TDISTRIB[$k] = 2.581; }
        if($k >= 1000)            { $TDISTRIB[$k] = 2.578; }
      }
    }
  }

  else {
    return -1;
  }

  #
  # calculation of mean value
  #
  $MEAN_VALUE_TMP = 0;
  for($i=0;$i<$NUM_MEAS_VALUES;$i++) {
    $MEAN_VALUE_TMP = $MEAS_VALUES[$i] + $MEAN_VALUE_TMP;
  }
  $MEAN_VALUE = $MEAN_VALUE_TMP/$NUM_MEAS_VALUES;

  #
  # calculation of standard variation
  #
  $STD_VAR_TMP = 0;
  for($j=0;$j<$NUM_MEAS_VALUES;$j++) {
    $STD_VAR_TMP = ((($MEAS_VALUES[$j] - $MEAN_VALUE)**2)/($NUM_MEAS_VALUES - 1)) + $STD_VAR_TMP;
  }
  $STD_VAR = $STD_VAR_TMP**0.5;

  #
  # calculation of confidence intervall
  #
  $CONF_INT = $TDISTRIB[$NUM_MEAS_VALUES - 2] * $STD_VAR / ($NUM_MEAS_VALUES**0.5);

  #
  # calculation of relative error
  #
  $REL_ERR = $CONF_INT / $MEAN_VALUE * 100;

  return $REL_ERR;
}

# #########################
# ## End of ConfInt Code ##
# #########################

1;
__END__
