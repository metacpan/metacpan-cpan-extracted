package App::SeismicUnixGui::misc::unif2;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: unif2 
 AUTHOR: Juan Lorenzo
 DATE: June 2 2016 
 DESCRIPTION surface consistent receiver-source static
 Version 1
 Notes: 
 Package name is the same as the file name
 Moose is a package that allows an object-oriented
 syntax to organizing your programs

=cut

=head2  Notes from Seismic Unix

UNIF2 - generate a 2-D UNIFormly sampled velocity profile 
from a layered
  	 model. In each layer, velocity is a linear functio
n of position.
 								
  unif2 < infile > outfile [parameters]				
 								
 Required parameters:						
 none								
 								
 Optional Parameters:						
 ninf=5	number of interfaces					
 nx=100	number of x samples (2nd dimension)			
 nz=100	number of z samples (1st dimension)			
 dx=10		x sampling interval				
 dz=10		z sampling interval				
 								
 npmax=201	maximum number of points on interfaces		
 								
 fx=0.0	first x sample						
 fz=0.0	first z sample						
 								
 x0=0.0,0.0,..., 	distance x at which v00 is specifie
d		
 z0=0.0,0.0,..., 	depth z at which v00 is specified	
 v00=1500,2000,2500...,	velocity at each x0,z0 (m/sec)		
 dvdx=0.0,0.0,...,	derivative of velocity with distanc
e x (dv/dx)	
 method=linear		for linear interpolation of interfa
ce		
 			=mono for monotonic cubic interpola
tion of interface
			=akima for Akima's cubic interpolat
ion of interface
			=spline for cubic spline interpolat
ion of interface
 								
 tfile=		=testfilename  if set, a sample input datas
et is
 			 output to "testfilename".		
 			 					
 Notes:								
 The input file is an ASCII file containing x z values repr
esenting a	
 piecewise continuous velocity model with a flat surface on
 top. The surface
 and each successive boundary between media are represented
 by a list of
 selected x z pairs written column form. The first and last
 x values must
 be the same for all boundaries. Use the entry   1.0  -9999
9  to separate
 entries for successive boundaries. No boundary may cross a
nother. Note
 that the choice of the method of interpolation may cause b
oundaries 	
 to cross that do not appear to cross in the input data fil
e.		
 The number of interfaces is specified by the parameter "ni
nf". This 
 number does not include the top surface of the model. The 
input data	
 format is the same as a CSHOT model file with all comments
 removed.	
								
 Example using test input file generating feature:		
 unif2 tfile=testfilename    produces a 5 interface demonst
ration model
 unif2 < testfilename | psimage n1=100 n2=100 d1=10 d2=10 |
 ...	


=head2 USAGE 1 

 Example

        $unif2->numberOfBuriedSurfaces;
	$unif2->numberXGridPoints;
	$unif2->numberZGridPoints;
	$unif2->horizontalGridSpacing_m;
	$unif2->verticalGridSpacing_m;
	$unif2->maxNumberGridPointsOnBuriedSurfaces;
	$unif2->firstXvalue_m;
	$unif2->firstZvalue_m;
	$unif2->horizontalVelocityGradient;
	$unif2->verticalVelocityGradient;
        $unif2->XVelocityList_m
        $unif2->ZVelocityList_m
        $unif2->velocityList_mps
	$unif2->interpolateBuriedSurfaceWith;
	$unif2->outboundTestFile;
        $unif2->Step();


=cut

my $unif2 = {
    _numberOfBuriedSurfaces              => '',
    _ninf                                => '',
    _numberXGridPoints                   => '',
    _nx                                  => '',
    _note                                => '',
    _numberZGridPoints                   => '',
    _nz                                  => '',
    _maxNumberGridPointsOnBuriedSurfaces => '',
    _npmax                               => '',
    _verticalGridSpacing_m               => '',
    _dz                                  => '',
    _horizontalGridSpacing_m             => '',
    _dx                                  => '',
    _Step                                => '',
    _firstXvalue_m                       => '',
    _fx                                  => '',
    _firstZvalue_m                       => '',
    _fz                                  => '',
    _verticalVelocityGradient            => '',
    _dvdz                                => '',
    _horizontalVelocityGradient          => '',
    _dvdx                                => '',
    _XVelocityList_m                     => '',
    _x0                                  => '',
    _ZVelocityList_m                     => '',
    _z0                                  => '',
    _velocityList_mps                    => '',
    _v00                                 => '',
    _interpolateBuriedSurfaceWith        => '',
    _method                              => '',
    _outboundTestFile                    => '',
    _tfile                               => '',
    _Step                                => ''
};

=head2 Notes

   Create mesh for finite difference modeling 

=head2 sub clear:

 clean hash of its values

=cut

sub clear {
    $unif2->{_numberOfBuriedSurfaces}              = '';
    $unif2->{_ninf}                                = '';
    $unif2->{_numberXGridPoints}                   = '';
    $unif2->{_nx}                                  = '';
    $unif2->{_numberZGridPoints}                   = '';
    $unif2->{_nz}                                  = '';
    $unif2->{_maxNumberGridPointsOnBuriedSurfaces} = '';
    $unif2->{_npmax}                               = '';
    $unif2->{_verticalGridSpacing_m}               = '';
    $unif2->{_dz}                                  = '';
    $unif2->{_horizontalGridSpacing_m}             = '';
    $unif2->{_dx}                                  = '';
    $unif2->{_firstXvalue_m}                       = '';
    $unif2->{_fx}                                  = '';
    $unif2->{_firstZvalue_m}                       = '';
    $unif2->{_fz}                                  = '';
    $unif2->{_verticalVelocityGradient}            = '';
    $unif2->{_dvdz}                                = '';
    $unif2->{_horizontalVelocityGradient}          = '';
    $unif2->{_dvdx}                                = '';
    $unif2->{_XVelocityList_m}                     = '';
    $unif2->{_x0}                                  = '';
    $unif2->{_ZVelocityList_m}                     = '';
    $unif2->{_z0}                                  = '';
    $unif2->{_velocityList_mps}                    = '';
    $unif2->{_v00}                                 = '';
    $unif2->{_interpolateBuriedSurfaceWith}        = '';
    $unif2->{_method}                              = '';
    $unif2->{_outboundTestFile}                    = '';
    $unif2->{_tfile}                               = '';
    $unif2->{_note}                                = '';
    $unif2->{_Step}                                = '';
}

=head2 subroutine  numberOfBuriedSurfaces


=cut

sub numberOfBuriedSurfaces {
    my ( $variable, $numberOfBuriedSurfaces ) = @_;
    if ($numberOfBuriedSurfaces) {
        $unif2->{_numberOfBuriedSurfaces} = $numberOfBuriedSurfaces;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' numberOfBuriedSurfaces='
          . $unif2->{_numberOfBuriedSurfaces};
        $unif2->{_note} =
            $unif2->{_note}
          . ' numberOfBuriedSurfaces='
          . $unif2->{_numberOfBuriedSurfaces};
    }
}

=head2 subroutine ninf

=cut

sub ninf {
    my ( $variable, $ninf ) = @_;
    if ($ninf) {
        $unif2->{_ninf} = $ninf;
        $unif2->{_Step} = $unif2->{_Step} . ' ninf=' . $unif2->{_ninf};
        $unif2->{_note} = $unif2->{_note} . ' ninf=' . $unif2->{_ninf};
    }
}

=head2 subroutine  numberXGridPoints

=cut

sub numberXGridPoints {
    my ( $variable, $numberXGridPoints ) = @_;
    if ($numberXGridPoints) {
        $unif2->{_numberXGridPoints} = $numberXGridPoints;

        $unif2->{_Step} =
            $unif2->{_Step}
          . ' numberXGridPoints='
          . $unif2->{_numberXGridPoints};
        $unif2->{_note} =
            $unif2->{_note}
          . ' numberXGridPoints='
          . $unif2->{_numberXGridPoints};
    }
}

=head2 subroutine nx 

=cut

sub nx {

    my ( $variable, $nx ) = @_;
    if ($nx) {
        $unif2->{_nx}   = $nx;
        $unif2->{_Step} = $unif2->{_Step} . ' nx=' . $unif2->{_nx};
        $unif2->{_note} = $unif2->{_note} . ' nx=' . $unif2->{_nx};
    }
}

=head2 subroutine numberZGridPoints 


=cut

sub numberZGridPoints {

    my ( $variable, $numberZGridPoints ) = @_;
    if ($numberZGridPoints) {
        $unif2->{_numberZGridPoints} = $numberZGridPoints;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' numberZGridPoints='
          . $unif2->{_numberZGridPoints};
        $unif2->{_note} =
            $unif2->{_note}
          . ' numberZGridPoints='
          . $unif2->{_numberZGridPoints};
    }
}

=head2 subroutine nz

=cut

sub nz {
    my ( $variable, $nz ) = @_;
    if ($nz) {
        $unif2->{_nz}   = $nz;
        $unif2->{_Step} = $unif2->{_Step} . ' nz=' . $unif2->{_nz};
        $unif2->{_note} = $unif2->{_note} . ' nz=' . $unif2->{_nz};
    }
}

=head2 subroutine maxNumberGridPointsOnBuriedSurfaces

=cut

sub maxNumberGridPointsOnBuriedSurfaces {
    my ( $variable, $maxNumberGridPointsOnBuriedSurfaces ) = @_;
    if ($maxNumberGridPointsOnBuriedSurfaces) {
        $unif2->{_maxNumberGridPointsOnBuriedSurfaces} =
          $maxNumberGridPointsOnBuriedSurfaces;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' maxNumberGridPointsOnBuriedSurfaces='
          . $unif2->{_maxNumberGridPointsOnBuriedSurfaces};
        $unif2->{_note} =
            $unif2->{_note}
          . ' maxNumberGridPointsOnBuriedSurfaces='
          . $unif2->{_maxNumberGridPointsOnBuriedSurfaces};
    }
}

=head2 subroutine npmax

=cut

sub npmax {
    my ( $variable, $npmax ) = @_;
    if ($npmax) {
        $unif2->{_npmax} = $npmax;
        $unif2->{_Step}  = $unif2->{_Step} . ' npmax=' . $unif2->{_npmax};
        $unif2->{_note}  = $unif2->{_note} . ' npmax=' . $unif2->{_npmax};
    }
}

=head2 subroutine verticalGridSpacing_m

=cut

sub verticalGridSpacing_m {
    my ( $variable, $verticalGridSpacing_m ) = @_;
    if ($verticalGridSpacing_m) {
        $unif2->{_verticalGridSpacing_m} = $verticalGridSpacing_m;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' verticalGridSpacing_m='
          . $unif2->{_verticalGridSpacing_m};
        $unif2->{_note} =
            $unif2->{_note}
          . ' verticalGridSpacing_m='
          . $unif2->{_verticalGridSpacing_m};
    }
}

=head2 subroutine dz

=cut

sub dz {
    my ( $variable, $dz ) = @_;
    if ($dz) {
        $unif2->{_dz}   = $dz;
        $unif2->{_Step} = $unif2->{_Step} . ' dz=' . $unif2->{_dz};
        $unif2->{_note} = $unif2->{_note} . ' dz=' . $unif2->{_dz};
    }
}

=head2 subroutine horizontalGridSpacing_m

=cut

sub horizontalGridSpacing_m {
    my ( $variable, $horizontalGridSpacing_m ) = @_;
    if ($horizontalGridSpacing_m) {
        $unif2->{_horizontalGridSpacing_m} = $horizontalGridSpacing_m;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' horizontalGridSpacing_m='
          . $unif2->{_horizontalGridSpacing_m};
        $unif2->{_note} =
            $unif2->{_note}
          . ' horizontalGridSpacing_m='
          . $unif2->{_horizontalGridSpacing_m};
    }
}

=head2 subroutine dx

=cut

sub dx {
    my ( $variable, $dx ) = @_;
    if ($dx) {
        $unif2->{_dx}   = $dx;
        $unif2->{_Step} = $unif2->{_Step} . ' dx=' . $unif2->{_dx};
        $unif2->{_note} = $unif2->{_note} . ' dx=' . $unif2->{_dx};
    }
}

=head2 subroutine firstXvalue_m

=cut

sub firstXvalue {
    my ( $variable, $firstXvalue ) = @_;
    if ($firstXvalue) {
        $unif2->{_firstXvalue} = $firstXvalue;
        $unif2->{_Step} =
          $unif2->{_Step} . ' firstXvalue=' . $unif2->{_firstXvalue};
        $unif2->{_note} =
          $unif2->{_note} . ' firstXvalue=' . $unif2->{_firstXvalue};
    }
}

=head2 subroutine firstZvalue_m

=cut

sub firstZvalue_m {
    my ( $variable, $firstZvalue_m ) = @_;
    if ($firstZvalue_m) {
        $unif2->{_firstZvalue_m} = $firstZvalue_m;
        $unif2->{_Step} =
          $unif2->{_Step} . ' firstZvalue_m=' . $unif2->{_firstZvalue_m};
        $unif2->{_note} =
          $unif2->{_note} . ' firstZvalue_m=' . $unif2->{_firstZvalue_m};
    }
}

=head2 subroutine fz

=cut

sub fz {
    my ( $variable, $fz ) = @_;
    if ($fz) {
        $unif2->{_fz}   = $fz;
        $unif2->{_Step} = $unif2->{_Step} . ' fz=' . $unif2->{_fz};
        $unif2->{_note} = $unif2->{_note} . ' fz=' . $unif2->{_fz};
    }
}

=head2 subroutine fx

=cut

sub fx {
    my ( $variable, $fx ) = @_;
    if ($fx) {
        $unif2->{_fx}   = $fx;
        $unif2->{_Step} = $unif2->{_Step} . ' fx=' . $unif2->{_fx};
        $unif2->{_note} = $unif2->{_note} . ' fx=' . $unif2->{_fx};
    }
}

=head2 subroutine verticalVelocityGradient

=cut

sub verticalVelocityGradient {
    my ( $variable, $verticalVelocityGradient ) = @_;
    if ($verticalVelocityGradient) {
        $unif2->{_verticalVelocityGradient} = $verticalVelocityGradient;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' verticalVelocityGradient='
          . $unif2->{_verticalVelocityGradient};
        $unif2->{_note} =
            $unif2->{_note}
          . ' verticalVelocityGradient='
          . $unif2->{_verticalVelocityGradient};
    }
}

=head2 subroutine horizontalVelocityGradient

=cut

sub horizontalVelocityGradient {
    my ( $variable, $horizontalVelocityGradient ) = @_;
    if ($horizontalVelocityGradient) {
        $unif2->{_horizontalVelocityGradient} = $horizontalVelocityGradient;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' horizontalVelocityGradient='
          . $unif2->{_horizontalVelocityGradient};
        $unif2->{_note} =
            $unif2->{_note}
          . ' horizontalVelocityGradient='
          . $unif2->{_horizontalVelocityGradient};
    }
}

=head2 subroutine dvdx

=cut

sub dvdx {
    my ( $variable, $dvdx ) = @_;
    if ($dvdx) {
        $unif2->{_dvdx} = $dvdx;
        $unif2->{_Step} = $unif2->{_Step} . ' dvdx=' . $unif2->{_dvdx};
        $unif2->{_note} = $unif2->{_note} . ' dvdx=' . $unif2->{_dvdx};
    }
}

=head2 subroutine dvdz

=cut

sub dvdz {
    my ( $variable, $dvdz ) = @_;
    if ($dvdz) {
        $unif2->{_dvdz} = $dvdz;
        $unif2->{_Step} = $unif2->{_Step} . ' dvdz=' . $unif2->{_dvdz};
        $unif2->{_note} = $unif2->{_note} . ' dvdz=' . $unif2->{_dvdz};
    }
}

=head2 subroutine XVelocityList_m

=cut

sub XVelocityList_m {
    my ( $variable, $XVelocityList_m ) = @_;
    if ($XVelocityList_m) {
        $unif2->{_XVelocityList_m} = $XVelocityList_m;
        $unif2->{_Step} =
          $unif2->{_Step} . ' XVelocityList_m=' . $unif2->{_XVelocityList_m};
        $unif2->{_note} =
          $unif2->{_note} . ' XVelocityList_m=' . $unif2->{_XVelocityList_m};
    }
}

=head2 subroutine x0

=cut

sub x0 {
    my ( $variable, $x0 ) = @_;
    if ($x0) {
        $unif2->{_x0}   = $x0;
        $unif2->{_Step} = $unif2->{_Step} . ' x0=' . $unif2->{_x0};
        $unif2->{_note} = $unif2->{_note} . ' x0=' . $unif2->{_x0};
    }
}

=head2 subroutine ZVelocityList_m

=cut

sub ZVelocityList_m {
    my ( $variable, $ZVelocityList_m ) = @_;
    if ($ZVelocityList_m) {
        $unif2->{_ZVelocityList_m} = $ZVelocityList_m;
        $unif2->{_Step} =
          $unif2->{_Step} . ' ZVelocityList_m=' . $unif2->{_ZVelocityList_m};
        $unif2->{_note} =
          $unif2->{_note} . ' ZVelocityList_m=' . $unif2->{_ZVelocityList_m};
    }
}

=head2 subroutine z0

=cut

sub z0 {
    my ( $variable, $z0 ) = @_;
    if ($z0) {
        $unif2->{_z0}   = $z0;
        $unif2->{_Step} = $unif2->{_Step} . ' z0=' . $unif2->{_z0};
        $unif2->{_note} = $unif2->{_note} . ' z0=' . $unif2->{_z0};
    }
}

=head2 subroutine velocityList_mps

=cut

sub velocityList_mps {
    my ( $variable, $velocityList_mps ) = @_;
    if ($velocityList_mps) {
        $unif2->{_velocityList_mps} = $velocityList_mps;
        $unif2->{_Step} =
          $unif2->{_Step} . ' velocityList_mps=' . $unif2->{_velocityList_mps};
        $unif2->{_note} =
          $unif2->{_note} . ' velocityList_mps=' . $unif2->{_velocityList_mps};
    }
}

=head2 subroutine v00

=cut

sub v00 {
    my ( $variable, $v00 ) = @_;
    if ($v00) {
        $unif2->{_v00}  = $v00;
        $unif2->{_Step} = $unif2->{_Step} . ' v00=' . $unif2->{_v00};
        $unif2->{_note} = $unif2->{_note} . ' v00=' . $unif2->{_v00};
    }
}

=head2 subroutine interpolateBuriedSurfaceWith

=cut

sub interpolateBuriedSurfaceWith {
    my ( $variable, $interpolateBuriedSurfaceWith ) = @_;
    if ($interpolateBuriedSurfaceWith) {
        $unif2->{_interpolateBuriedSurfaceWith} = $interpolateBuriedSurfaceWith;
        $unif2->{_Step} =
            $unif2->{_Step}
          . ' interpolateBuriedSurfaceWith='
          . $unif2->{_interpolateBuriedSurfaceWith};
        $unif2->{_note} =
            $unif2->{_note}
          . ' interpolateBuriedSurfaceWith='
          . $unif2->{_interpolateBuriedSurfaceWith};
    }
}

=head2 subroutine method

=cut

sub method {
    my ( $variable, $method ) = @_;
    if ($method) {
        $unif2->{_method} = $method;
        $unif2->{_Step}   = $unif2->{_Step} . ' method=' . $unif2->{_method};
        $unif2->{_note}   = $unif2->{_note} . ' method=' . $unif2->{_method};
    }
}

=head2 subroutine outboundTestFile

=cut

sub outboundTestFile {
    my ( $variable, $outboundTestFile ) = @_;
    if ($outboundTestFile) {
        $unif2->{_outboundTestFile} = $outboundTestFile;
        $unif2->{_Step} =
          $unif2->{_Step} . ' outboundTestFile=' . $unif2->{_outboundTestFile};
        $unif2->{_note} =
          $unif2->{_note} . ' outboundTestFile=' . $unif2->{_outboundTestFile};
    }
}

=head2 subroutine  note

=cut

sub note {
    my ( $variable, $note ) = @_;
    $unif2->{_note} = 'unif2 ' . $unif2->{_note};
    return $unif2->{_note};
}

=head2 subroutine  Step

=cut

sub Step {

    $unif2->{_Step} = 'unif2 ' . $unif2->{_Step};
    return $unif2->{_Step};
}

=head2

 place 1; at end of the package

=cut

1;
