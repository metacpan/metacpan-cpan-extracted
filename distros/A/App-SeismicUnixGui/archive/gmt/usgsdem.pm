package App::SeismicUnixGui::gmt::usgsdem;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE: usgsdem 
 AUTHOR: Juan Lorenzo
 DATE: V 1. Oct 7 2002

 DESCRIPTION 

 contains functions to estimate homogeneous strain
 variables on the raw DEM data

 BASED ON:

=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
	V 1.1 Nov 15 2005 
	Now can read UTM min and max values
=cut 

our $VERSION = '1.20';
use Moose;

=head2 private hash

=cut

my $usgsdem = {
    _sheet_name4utm       => '',
    _sheet_name4lat_lon   => '',
    _quarter_sheet_num    => '',
    _quarter_sheet_uc_ref => '',
};

=head2 sub get_utm_corner_NE

   LHC has xmin and y min or point 2 , line 2 in the corners file
   RHC top  has xmax and y max or point 3 , line 3 in the corners file
#   remember that counter starts at 0 and not 1!!!!
=cut

sub get_utm_corner_NE {

    my ($self) = @_;
    my $file_name = $usgsdem->{_sheet_name4utm};

    # print "usgsdem, get_utm_corner_NE, file_name: $file_name \n";
    open( my $FILE, '<', $file_name ) or die("Can not open $file_name $! \n");
    my $i = 0;
    my ( @X, @Y );

    # print("usgsdem,get_utm_corner_NE,i:$i\n");
    while ( my $line = <$FILE> ) {
        chomp $line;
        my ( $x, $y, $z ) = split( " ", $line );
        $Y[$i] = $y;
        $X[$i] = $x;
        $i++;

        # print("usgsdem,get_utm_corner_NE,x, y, z:$x, $y, $z\n");
    }
    close($FILE);

    my $xmin_m = $X[1];
    my $xmax_m = $X[2];
    my $ymin_m = $Y[1];
    my $ymax_m = $Y[2];
    return ( $xmin_m, $xmax_m, $ymin_m, $ymax_m );
}

=head2 	sub get_quarter_sheet_lats_lons 
		extract latitude
	   	and longitues of
	   	the corners of the 
	   	quarter-sheet

=cut

sub get_quarter_sheet_lats_lons {

    my ($self) = @_;
    my $inbound = $usgsdem->{_sheet_num4lat_lon};
    my ( $lon_min, $lat_min, $lon_max, $lat_max );
    my ($file_name);
    my @words;

    $file_name = $usgsdem->{_sheet_name4lat_lon};

    open( FILE, $file_name || "Can't open file_name, $!\n" );
    my $i = 0;
    while ( my $line = <FILE> ) {
        @words = split( /:|\\n/, $line );
        if ( $words[0] eq '      West_Bounding_Coordinate' ) {
            $lon_min = $words[1];
            $lon_min = substr $lon_min, 0, -2;
            $lon_min = substr $lon_min, 1;

        }
        if ( $words[0] eq '      East_Bounding_Coordinate' ) {
            $lon_max = $words[1];
            $lon_max = substr $lon_max, 0, -2;
            $lon_max = substr $lon_max, 1;
        }
        if ( $words[0] eq '      North_Bounding_Coordinate' ) {
            $lat_max = $words[1];
            $lat_max = substr $lat_max, 0, -2;
            $lat_max = substr $lat_max, 1;
        }
        if ( $words[0] eq '      South_Bounding_Coordinate' ) {
            $lat_min = $words[1];
            $lat_min = substr $lat_min, 0, -2;
            $lat_min = substr $lat_min, 1;
        }
    }
    close(FILE);

# print "strain,read_corners_ll $file_name  $lon_min $lon_max,$lat_min $lat_max \n";
    return ( $lon_min, $lon_max, $lat_min, $lat_max );
}

=head2 	sub get_quarter_sheet_utms 

=cut

sub get_quarter_sheet_utms {

    my ($self) = @_;
    my $file_name = $usgsdem->{_sheet_name4utm};

    # print "usgsdem, get_quarter_sheet_utms, file_name: $file_name \n";
    open( my $FILE, '<', $file_name ) or die("Can not open $file_name $! \n");
    my $i = 0;
    my ( @X, @Y );

    # print("usgsdem,get_quarter_sheet_utms,i:$i\n");
    while ( my $line = <$FILE> ) {
        chomp $line;
        my ( $x, $y, $z ) = split( " ", $line );
        $Y[$i] = $y;
        $X[$i] = $x;
        $i++;

        #   print("usgsdem,get_quarter_sheet_utms,x, y, z:$x, $y, $z\n");
    }
    close($FILE);

    my $xmin_m = $X[1];
    my $xmax_m = $X[2];
    my $ymin_m = $Y[1];
    my $ymax_m = $Y[2];
    return ( $xmin_m, $xmax_m, $ymin_m, $ymax_m );
}

#
#
#sub read_corners {
#
## get filename
#   $file_name = $_[0];
#
#   open(FILE,$file_name || "Can't open file_name, $!\n");
#    $i=0;
#    while ($line = <FILE>) {
#        ($x, $y, $z)    = split (" ",$line);
##   LHC has xmin and y min or point 2 , line 2 in the corners file
#        $Y[$i]           = $y;
#        $X[$i]           = $x;
#        $i = $i +1;
#    }
#   $yshift = $Y[1];
#   $xmin_m = $X[1];
#   $xmax_m = $X[3];
#   $ymin_m = $Y[1];
#   $xwidth = $xmax_m -$xmin_m;
#   close(FILE);
#   return ($yshift,$xwidth,$xmin_m);
#}
#
#
#sub yscale_error {
#
##set gmt defaults
#        system("gmtset ELLIPSOID GRS-80");
#        system("gmtset D_FORMAT 0.000000");
#        system("gmtset MEASURE_UNIT m");
#
## get filename and region limits from passed array
#        ($region,$xwidth,$xscale,$file_name,$xshift,$yshift,$deg) = split (" ",$_[0]);
#        ($xmin,$xmax,$ymin,$ymax) = split(/ |\//,$region);
#
##set some variables
#        $verbose      = ' -V'  ;
#        $projection   = 'U15/'.$xwidth;
#
## define work file names
#        $projected_file     = 'temp6';
#        $grd_bat_file       = 'temp7';
#        $out_file           = $file_name.'.proj.llz';
#
## defaults working parameters and their values
#
#	$min_y_err = 100000;
#        $min_x_err = 100000;
#        $rad     =  $deg /180. * 3.141592654   ;
#        $cost    =  cos($rad);
#        $sint    =  sin($rad);
#
## scale from 750 1500f original length
#for ( $yscale =0.75 ; $yscale < 1.1 ; $yscale = ($yscale + .005) ) {
#
##  shift, CCW rotate and scale  x-y values before transforming
##  strain the data field so that after transformation it matches
##  espected corner values for the region
#
#        open(FILE,$file_name || "Can't open file_name, $!\n");
#        open(OUT,">$grd_bat_file") ;
#
#        $i=0;
#        while ($line = <FILE>) {
#        ($x, $y, $z)    = split (" ",$line);
##shift
#        $X[$i]          = ($x - $xshift);
#        $Y[$i]          = ($y - $yshift);
#        $tmpXshft       = $X[0];  # assume this value is greater than 0
#
##	$tmpYshft       = 0;  # this value is assumed to be 0 because $yshift=$Y[1]
## and has already been subtaracted in the previous line
#
## temporarily make bottomleft corner the origin (X=0,Y=0), N.B. Y is already 0
## the rotate CCW  and
## then restore the original X
#
#        $X[$i]          = ( ($X[$i] - $tmpXshft) * $cost + $Y[$i] * $sint) + $tmpXshft;
#        $Y[$i]          = (-($X[$i] - $tmpXshft) * $sint + $Y[$i] * $cost);
#
## scale along x direction
#        $X[$i]          = ( $X[$i] - ($X[$i] - $tmpXshft ) * $xscale);
#
##scale along the y direction
#        $Y[$i]          = ( $Y[$i] * $yscale);
#
#       print OUT  ("$X[$i] $Y[$i] $z\n");
#        $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
## RUN main program from here on
#        system ("mapproject $grd_bat_file -Dm -I  -R$region -J$projection  > $projected_file ");
#
## make longitudes have negative format
#        open(FILE,$projected_file) || "Can't open $projected_file, $!\n";
#        open(OUT,">$out_file") ;
#
#        while ($line = <FILE>) {
#           ($x, $y, $z) = split (" ",$line);
#           $x              = ($x - 360.00);
#           print OUT  ("$x $y $z\n");
##          print  (" BEFORE $x $y $z\n");
#        }
#        close(FILE);
#        close(OUT);
#
##  compare outputs with expected best results and find the best parameter
#
#        open(FILE,$out_file) || "Can't open $out_file, $!\n";
#        $i=0;
#        while ($line = <FILE>) {
#           ($X[$i], $Y[$i], $z) = split (" ",$line);
##          print  ("AFTER: $X[$i] $Y[$i] $z\n");
#           $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
##  calculate the error in the y's
#        $deg2m = 100000;
#
## total average absolute error in the y's
#       $y_err = $deg2m * (abs($ymin -$Y[1]) + abs($ymin - $Y[3]) + abs($ymax -$Y[0]) +abs($ymax-$Y[2]))/4;
#
#	if($y_err < $min_y_err) {
#	   $min_y_err = $y_err;
#           $best_scale = $yscale;
#	}
#   }
#
#       return ($best_scale,$min_y_err);
#}
#
#
#
#sub xscale_error {
#
##set gmt defaults
#        system("gmtset ELLIPSOID GRS-80");
#        system("gmtset D_FORMAT 0.000000");
#        system("gmtset MEASURE_UNIT m");
#
## get filename ad region limits from passed array
#        ($region,$xwidth,$file_name,$xshift,$yshift,$deg) = split (" ",$_[0]);
#        ($xmin,$xmax,$ymin,$ymax) = split(/ |\//,$region);
#
##set some variables
#        $verbose      = ' -V'  ;
#        $projection   = 'U15/'.$xwidth;
#
## define work file names
#        $projected_file     = 'temp4';
##        $grd_bat_file       = 'temp5';
#        $out_file           = $file_name.'.proj.llz';
#
## defaults working parameters and their values
#
#	$min_y_err = 100000;
#        $min_x_err = 100000;
#        $rad     =  $deg /180. * 3.141592654   ;
#        $cost    =  cos($rad);
#        $sint    =  sin($rad);
#
#for ( $xscale = -0.5; $xscale < 0.5 ; $xscale = ($xscale + .005) ) {
#
##  shift, CCW rotate and scale  x-y values before transforming
##  strain the data field so that after transformation it matches
##  espected corner values for the region
#
#        open(FILE,$file_name || "Can't open file_name, $!\n");
#        open(OUT,">$grd_bat_file") ;
#
#        $i=0;
#        while ($line = <FILE>) {
#        ($x, $y, $z)    = split (" ",$line);
##shift
#        $X[$i]          = ($x - $xshift);
#        $Y[$i]          = ($y - $yshift);
#        $tmpXshft       = $X[0];  # assume this value is greater than 0
#
## temporarily make bottomleft corner the origin (X=0,Y=0), N.B. Y is already 0
## the rotate CCW  and
## then restore the original X
#
#        $X[$i]          = ( ($X[$i] - $tmpXshft) * $cost + $Y[$i] * $sint) + $tmpXshft;
#        $Y[$i]          = (-($X[$i] - $tmpXshft) * $sint + $Y[$i] * $cost);
#
## then scale , (only along x is needed)
# $X[$i]          = ( $X[$i] - ($X[$i] - $tmpXshft ) * $xscale);
#        print OUT  ("$X[$i] $Y[$i] $z\n");
#        $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
## RUN main program from here on
#        system ("mapproject $grd_bat_file -Dm -I  -R$region -J$projection  > $projected_file ");
#
## make longitudes have negative format
#        open(FILE,$projected_file) || "Can't open $projected_file, $!\n";
#        open(OUT,">$out_file") ;
#
#        while ($line = <FILE>) {
#           ($x, $y, $z) = split (" ",$line);
#           $x              = ($x - 360.00);
#           print OUT  ("$x $y $z\n");
##          print  (" BEFORE $x $y $z\n");
#        }
#        close(FILE);
#        close(OUT);
#
##  compare outputs with expected best results and find the best parameter
#
#        open(FILE,$out_file) || "Can't open $out_file, $!\n";
#        $i=0;
#        while ($line = <FILE>) {
#           ($X[$i], $Y[$i], $z) = split (" ",$line);
##          print  ("AFTER: $X[$i] $Y[$i] $z\n");
#           $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
##  calculate the error in the x's
#        $deg2m = 100000;
#
## for the total error in the x's
#       $x_err = $deg2m * (abs($xmin -$X[0]) + abs($xmin - $X[1]) + abs($xmax -$X[2]) +abs($xmax-$
#X[3]))/4;
#
#        if($x_err < $min_x_err) {
#           $min_x_err= $x_err;
#           $best_scale = $xscale;
#        }
#
## total average absolute error in the y's
#       $y_err = $deg2m * (abs($ymin -$Y[1]) + abs($ymin - $Y[3]) + abs($ymax -$Y[0]) +abs($ymax-$Y[2]))/4;
#
#	if($y_err < $min_y_err) {
#	   $min_y_err = $y_err;
#	}
#   }
#
#       return ($best_scale,$min_x_err,$min_y_err);
#}
#
#
#
#sub rotate_error {
#
##set gmt defaults
#        system("gmtset ELLIPSOID GRS-80");
#	system("gmtset D_FORMAT 0.000000");
#        system("gmtset MEASURE_UNIT m");
#
#
## get filename ad region limits from passed array
#        ($region,$xwidth,$file_name,$xshift,$yshift) = split (" ",$_[0]);
#        ($xmin,$xmax,$ymin,$ymax) = split(/ |\//,$region);
#
##set some variables
#        $verbose      = ' -V'  ;
#        $projection   = 'U15/'.$xwidth;
#
## define work file names
#        $projected_file     = 'temp3';
#        $grd_bat_file       = 'temp4';
#        $out_file           = $file_name.'.proj.llz';
#
## defaults working parameters and their values
#
#        $xscale  =  0;
#        $min_x_err = 100000;
#	$min_y_err = 100000;
#
#   for ( $deg = -2; $deg < (2 ); $deg = ($deg + .01) ) {
#
#	$rad     =  $deg /180. * 3.141592654   ;
#        $cost    =  cos($rad);
#        $sint    =  sin($rad);
#
##  shift, CCW rotate and scale  x-y values before transforming
##  strain the data field so that after transformation it matches
##  espected corner values for the region
#
#        open(FILE,$file_name || "Can't open file_name, $!\n");
#        open(OUT,">$grd_bat_file") ;
#
#        $i=0;
#        while ($line = <FILE>) {
#        ($x, $y, $z)    = split (" ",$line);
##shift
#        $X[$i]          = ($x - $xshift);
#        $Y[$i]          = ($y - $yshift);
#	$tmpXshft       = $X[0];  # assume this value is greater than 0
#
## temporarily make bottomleft corner the origin (X=0,Y=0), N.B. Y is already 0
## the rotate CCW  and
## then restore the original X
#
#        $X[$i]          = ( ($X[$i] - $tmpXshft) * $cost + $Y[$i] * $sint) + $tmpXshft;
#        $Y[$i]          = (-($X[$i] - $tmpXshft) * $sint + $Y[$i] * $cost);
#
## then scale , (only along x is needed)
#
#        $X[$i]          = ( $X[$i] - ($X[$i] - $tmpXshft ) * $xscale);
#        print OUT  ("$X[$i] $Y[$i] $z\n");
#        $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
#
## RUN main program from here on
#        system ("mapproject $grd_bat_file -Dm -I  -R$region -J$projection  > $projected_file ");
#
## make longitudes have negative format
#        open(FILE,$projected_file) || "Can't open $projected_file, $!\n";
#        open(OUT,">$out_file") ;
#
#        while ($line = <FILE>) {
#           ($x, $y, $z) = split (" ",$line);
#           $x              = ($x - 360.00);
#
#           print OUT  ("$x $y $z\n");
##          print  (" BEFORE $x $y $z\n");
#        }
#        close(FILE);
#        close(OUT);
#
##  compare outputs with expected best results and find the best parameter
#
#        open(FILE,$out_file) || "Can't open $out_file, $!\n";
#
#        $i=0;
#        while ($line = <FILE>) {
#           ($X[$i], $Y[$i], $z) = split (" ",$line);
##          print  ("AFTER: $X[$i] $Y[$i] $z\n");
#           $i = $i +1;
#        }
#        close(FILE);
#        close(OUT);
#
##  calculate the error in the x's
#        $deg2m = 100000;
#
## for the total error
##       $x_err = $deg2m * (abs($xmin -$X[0]) + abs($xmin - $X[1]) + abs($xmax -$X[2]) +abs($xmax-$
##X[3]))/4;
#
## make the top left corner of the DEM land lie on a line of longitude,so that the x error is minimal
#       $x_err = $deg2m * abs($xmin -$X[0]);
#
#        if($x_err < $min_x_err) {
#           $min_x_err= $x_err;
#           $best_angle = $deg;
#        }
#
## total average absolute error in the y direction for all four corners
#       $y_err = $deg2m * (abs($ymin -$Y[1]) + abs($ymin - $Y[3]) + abs($ymax -$Y[0]) +abs($ymax-$Y[2]))/4;
#
#        if($y_err < $min_y_err) {
#           $min_y_err= $y_err;
#        }
#
#   }
#
#        return ($best_angle,$min_x_err,$min_y_err);
#}
#
#
#sub xshift_error {
#
##set gmt defaults
#	system("gmtset ELLIPSOID GRS-80");
# 	system("gmtset D_FORMAT 0.000000");
# 	system("gmtset MEASURE_UNIT m");
#
#
## get filename ad region limits from passed array
#	($region,$xwidth,$xmin_m,$file_name,$yshift) = split (" ",$_[0]);
#	($xmin,$xmax,$ymin,$ymax) = split(/ |\//,$region);
#
##set some variables
#	$verbose      = ' -V'  ;
# 	$projection   = 'U15/'.$xwidth;
#	print ("$region\n$xmin $xmax $ymin $ymax\n");
#
## define work file names
#   	$projected_file     = 'temp';
#   	$grd_bat_file	       = 'temp2';
#   	$out_file           = $file_name.'.proj.llz';
#
## defaults working parameters and their values
#
#        $deg     =  0;
#        $rad     =  $deg /180. * 3.141592654;
#        $cost    =  cos($rad);
#        $sint    =  sin($rad);
#        $xscale  =  0; # not used
#	$min_x_err = 100000;
#	$min_y_err_LHC = 100000;
#	$min_y_err = 100000;
#
#   for ( $xshift = $xmin_m - 1000 ; $xshift < $xmin_m + 1000; $xshift= $xshift + 5) {
#
##  shift, CCW rotate and scale  x-y values before transforming
##  strain the data field so that after transformation it matches
##  espected corner values for the region
#
#        open(FILE,$file_name || "Can't open file_name, $!\n");
#        open(OUT,">$grd_bat_file") ;
#
#	$i=0;
#	while ($line = <FILE>) {
#        ($x, $y, $z)    = split (" ",$line);
##shift
#        $X[$i]          = ($x - $xshift);
#        $Y[$i]          = ($y - $yshift);
#        $tmpXshft       = $X[0];  # assume this value is greater than 0
#
## temporarily make bottomleft corner the origin (X=0,Y=0), N.B. Y is already 0
## the rotate CCW  and
## then restore the original X
#
#        $X[$i]          = ( ($X[$i] - $tmpXshft) * $cost + $Y[$i] * $sint) + $tmpXshft;
#        $Y[$i]          = (-($X[$i] - $tmpXshft) * $sint + $Y[$i] * $cost);
#
## then scale , (only along x is needed)
#
#        $X[$i]          = ( $X[$i] - ($X[$i] - $tmpXshft ) * $xscale);
#        print OUT  ("$X[$i] $Y[$i] $z\n");
#        $i = $i +1;
#	}
#	close(FILE);
#	close(OUT);
#
#
#
## RUN main program from here on
#  	system ("mapproject $grd_bat_file -Dm -I  -R$region -J$projection  > $projected_file ");
#
## make longitudes have negative format
#        open(FILE,$projected_file) || "Can't open $projected_file, $!\n";
#        open(OUT,">$out_file") ;
#
#	while ($line = <FILE>) {
#           ($x, $y, $z) = split (" ",$line);
#           $x              = ($x - 360.00);
#
#           print OUT  ("$x $y $z\n");
##          print  (" BEFORE $x $y $z\n");
#	}
#	close(FILE);
#	close(OUT);
#
##  compare outputs with expected best results and find the best parameter
#
#
#	open(FILE,$out_file) || "Can't open $out_file, $!\n";
#
#	$i=0;
#	while ($line = <FILE>) {
#           ($X[$i], $Y[$i], $z) = split (" ",$line);
##          print  ("AFTER: $X[$i] $Y[$i] $z\n");
#	   $i = $i +1;
#	}
#	close(FILE);
#	close(OUT);
#
##  calculate the error in the x's
#	$deg2m = 100000;
#
## for the total error
##	$x_err = $deg2m * (abs($xmin -$X[0]) + abs($xmin - $X[1]) + abs($xmax -$X[2]) +abs($xmax-$X[3]))/4;
#
## for total average absolute error in the y direction
##	$y_err = $deg2m * (abs($ymin - $Y[1])+ abs($ymin - $Y[3]) + abs($ymax -$Y[0]) +abs($ymax-$Y[2]))/4;
##
#	$y_err = $deg2m * abs($ymin - $Y[1]);
##	if($y_err < $min_y_err) {
#	   $min_y_err = $y_err;
#	   $best_yshift = $yshift;
#	}
#
# for error only of the bottom left-hand corner
#	$y_err_LHC = $deg2m * abs($ymin - $Y[1]);
#	if($y_err_LHC < $min_y_err_LHC) {
#	   $min_y_err_LHC = $y_err_LHC;
#	}
#	:
## for the error of only the lower left-hand corner
#	$x_err = $deg2m * abs($xmin - $X[1]);
#	if($x_err < $min_x_err) {
#	   $min_x_err = $x_err;
#	   $best_xshift = $xshift;
#	}
#
#   }
#	return ($best_xshift,$min_x_err,$best_yshift,$min_y_err_LHC,$min_y_err);
#}
##
#

=head2 sub set_quarter_sheet_num

=cut

sub set_quarter_sheet_num {

    my ( $self, $num ) = @_;
    if ($num) {
        $usgsdem->{quarter_sheet_num} = $num;
    }

    # print "usgsdem, set_quarter_sheet_num,num: $num \n";
    return ();
}

=head2 sub set_quarter_sheet_uc_ref

=cut

sub set_quarter_sheet_uc_ref {
    my ($self) = @_;

    my @quarter_sheet_uc;

    $quarter_sheet_uc[0]              = 'NE';
    $quarter_sheet_uc[1]              = 'NW';
    $quarter_sheet_uc[2]              = 'SE';
    $quarter_sheet_uc[3]              = 'SW';
    $usgsdem->{_quarter_sheet_uc_ref} = \@quarter_sheet_uc;

    # print "usgsdem, set_quarter_sheet_uc_ref,uc_ref: @quarter_sheet_uc \n";
    return ();
}

=head2 sub set_sheet_name4lat_lon

=cut

sub set_sheet_name4lat_lon {
    my ( $self, $sheet_name4lat_lon ) = @_;

    if ($sheet_name4lat_lon) {
        $usgsdem->{_sheet_name4lat_lon} = $sheet_name4lat_lon;

    }

# print("usgsdem,set_sheet_name4lat_lon,sheet4lat_lon: $usgsdem->{_sheet_name4lat_lon}\n");

    return ();
}

=head2 sub set_sheet_name4utm

=cut

sub set_sheet_name4utm {
    my ( $self, $sheet_name4utm ) = @_;

    if ($sheet_name4utm) {
        $usgsdem->{_sheet_name4utm} = $sheet_name4utm;
    }

# print("usgsdem,set_sheet_name4utm,sheet_name4utm: $usgsdem->{_sheet_name4utm}\n");
    return ();
}

1;
