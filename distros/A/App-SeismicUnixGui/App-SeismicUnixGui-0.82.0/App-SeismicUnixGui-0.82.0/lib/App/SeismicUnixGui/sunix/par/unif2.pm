package App::SeismicUnixGui::sunix::par::unif2;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  UNIF2 - generate a 2-D UNIFormly sampled velocity profile from a layered
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 UNIF2 - generate a 2-D UNIFormly sampled velocity profile from a layered
  	 model. In each layer, velocity is a linear function of position.

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
 Is relatively independent of nx: 
 e.g.,
	nx =100 and npmax= 10 is OK

 fx=0.0	first x sample						
 fz=0.0	first z sample						

 x0=0.0,0.0,..., 	distance x at which v00 is specified		
 z0=0.0,0.0,..., 	depth z at which v00 is specified		
 v00=1500,2000,2500...,	velocity at each x0,z0 (m/sec)		
 dvdx=0.0,0.0,...,	derivative of velocity with distance x (dv/dx)	
 dvdz=0.0,0.0,...,	derivative of velocity with depth z (dv/dz)	

 method=linear		for linear interpolation of interface		
 			=mono for monotonic cubic interpolation of interface
			=akima for Akima's cubic interpolation of interface
			=spline for cubic spline interpolation of interface

 tfile=		=testfilename  if set, a sample input dataset is
 			 output to "testfilename".			

 Notes:								
 The input file is an ASCII file containing x z values representing a	
 piecewise continuous velocity model with a flat surface on top. The surface
 and each successive boundary between media are represented by a list of
 selected x z pairs written column form. The first and last x values must
 be the same for all boundaries. Use the entry   1.0  -99999  to separate
 entries for successive boundaries. No boundary may cross another. Note
 that the choice of the method of interpolation may cause boundaries 	
 to cross that do not appear to cross in the input data file.		
 The number of interfaces is specified by the parameter "ninf". This 
 number does not include the top surface of the model. The input data	
 format is the same as a CSHOT model file with all comments removed.	

 Example using test input file generating feature:			
 unif2 tfile=testfilename    produces a 5 interface demonstration model
 unif2 < testfilename | psimage n1=100 n2=100 d1=10 d2=10 | ...	



 Credits:
 	CWP: Zhenyue Liu, 1994 
      CWP: John Stockwell, 1994, added demonstration model stuff. 


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $unif2 = {
    _dvdx   => '',
    _dvdz   => '',
    _dx     => '',
    _dz     => '',
    _fx     => '',
    _fz     => '',
    _method => '',
    _ninf   => '',
    _npmax  => '',
    _nx     => '',
    _nz     => '',
    _tfile  => '',
    _v00    => '',
    _x0     => '',
    _z0     => '',
    _Step   => '',
    _note   => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $unif2->{_Step} = 'unif2' . $unif2->{_Step};
    return ( $unif2->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $unif2->{_note} = 'unif2' . $unif2->{_note};
    return ( $unif2->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $unif2->{_dvdx}   = '';
    $unif2->{_dvdz}   = '';
    $unif2->{_dx}     = '';
    $unif2->{_dz}     = '';
    $unif2->{_fx}     = '';
    $unif2->{_fz}     = '';
    $unif2->{_method} = '';
    $unif2->{_ninf}   = '';
    $unif2->{_npmax}  = '';
    $unif2->{_nx}     = '';
    $unif2->{_nz}     = '';
    $unif2->{_tfile}  = '';
    $unif2->{_v00}    = '';
    $unif2->{_x0}     = '';
    $unif2->{_z0}     = '';
    $unif2->{_Step}   = '';
    $unif2->{_note}   = '';
}

=head2 sub dvdx 


=cut

sub dvdx {

    my ( $self, $dvdx ) = @_;
    if ( $dvdx ne $empty_string ) {

        $unif2->{_dvdx} = $dvdx;
        $unif2->{_note} = $unif2->{_note} . ' dvdx=' . $unif2->{_dvdx};
        $unif2->{_Step} = $unif2->{_Step} . ' dvdx=' . $unif2->{_dvdx};

    }
    else {
        print("unif2, dvdx, missing dvdx,\n");
    }
}

=head2 sub dvdz 


=cut

sub dvdz {

    my ( $self, $dvdz ) = @_;
    if ( $dvdz ne $empty_string ) {

        $unif2->{_dvdz} = $dvdz;
        $unif2->{_note} = $unif2->{_note} . ' dvdz=' . $unif2->{_dvdz};
        $unif2->{_Step} = $unif2->{_Step} . ' dvdz=' . $unif2->{_dvdz};

    }
    else {
        print("unif2, dvdz, missing dvdz,\n");
    }
}

=head2 sub dx 


=cut

sub dx {

    my ( $self, $dx ) = @_;
    if ( $dx ne $empty_string ) {

        $unif2->{_dx}   = $dx;
        $unif2->{_note} = $unif2->{_note} . ' dx=' . $unif2->{_dx};
        $unif2->{_Step} = $unif2->{_Step} . ' dx=' . $unif2->{_dx};

    }
    else {
        print("unif2, dx, missing dx,\n");
    }
}

=head2 sub dz 


=cut

sub dz {

    my ( $self, $dz ) = @_;
    if ( $dz ne $empty_string ) {

        $unif2->{_dz}   = $dz;
        $unif2->{_note} = $unif2->{_note} . ' dz=' . $unif2->{_dz};
        $unif2->{_Step} = $unif2->{_Step} . ' dz=' . $unif2->{_dz};

    }
    else {
        print("unif2, dz, missing dz,\n");
    }
}

=head2 sub fx 


=cut

sub fx {

    my ( $self, $fx ) = @_;
    if ( $fx ne $empty_string ) {

        $unif2->{_fx}   = $fx;
        $unif2->{_note} = $unif2->{_note} . ' fx=' . $unif2->{_fx};
        $unif2->{_Step} = $unif2->{_Step} . ' fx=' . $unif2->{_fx};

    }
    else {
        print("unif2, fx, missing fx,\n");
    }
}

=head2 sub fz 


=cut

sub fz {

    my ( $self, $fz ) = @_;
    if ( $fz ne $empty_string ) {

        $unif2->{_fz}   = $fz;
        $unif2->{_note} = $unif2->{_note} . ' fz=' . $unif2->{_fz};
        $unif2->{_Step} = $unif2->{_Step} . ' fz=' . $unif2->{_fz};

    }
    else {
        print("unif2, fz, missing fz,\n");
    }
}

=head2 sub method 


=cut

sub method {

    my ( $self, $method ) = @_;
    if ( $method ne $empty_string ) {

        $unif2->{_method} = $method;
        $unif2->{_note}   = $unif2->{_note} . ' method=' . $unif2->{_method};
        $unif2->{_Step}   = $unif2->{_Step} . ' method=' . $unif2->{_method};

    }
    else {
        print("unif2, method, missing method,\n");
    }
}

=head2 sub ninf 


=cut

sub ninf {

    my ( $self, $ninf ) = @_;
    if ( $ninf ne $empty_string ) {

        $unif2->{_ninf} = $ninf;
        $unif2->{_note} = $unif2->{_note} . ' ninf=' . $unif2->{_ninf};
        $unif2->{_Step} = $unif2->{_Step} . ' ninf=' . $unif2->{_ninf};

    }
    else {
        print("unif2, ninf, missing ninf,\n");
    }
}

=head2 sub npmax 


=cut

sub npmax {

    my ( $self, $npmax ) = @_;
    if ( $npmax ne $empty_string ) {

        $unif2->{_npmax} = $npmax;
        $unif2->{_note}  = $unif2->{_note} . ' npmax=' . $unif2->{_npmax};
        $unif2->{_Step}  = $unif2->{_Step} . ' npmax=' . $unif2->{_npmax};

    }
    else {
        print("unif2, npmax, missing npmax,\n");
    }
}

=head2 sub nx 


=cut

sub nx {

    my ( $self, $nx ) = @_;
    if ( $nx ne $empty_string ) {

        $unif2->{_nx}   = $nx;
        $unif2->{_note} = $unif2->{_note} . ' nx=' . $unif2->{_nx};
        $unif2->{_Step} = $unif2->{_Step} . ' nx=' . $unif2->{_nx};

    }
    else {
        print("unif2, nx, missing nx,\n");
    }
}

=head2 sub nz 


=cut

sub nz {

    my ( $self, $nz ) = @_;
    if ( $nz ne $empty_string ) {

        $unif2->{_nz}   = $nz;
        $unif2->{_note} = $unif2->{_note} . ' nz=' . $unif2->{_nz};
        $unif2->{_Step} = $unif2->{_Step} . ' nz=' . $unif2->{_nz};

    }
    else {
        print("unif2, nz, missing nz,\n");
    }
}

=head2 sub tfile 


=cut

sub tfile {

    my ( $self, $tfile ) = @_;
    if ( $tfile ne $empty_string ) {

        $unif2->{_tfile} = $tfile;
        $unif2->{_note}  = $unif2->{_note} . ' tfile=' . $unif2->{_tfile};
        $unif2->{_Step}  = $unif2->{_Step} . ' tfile=' . $unif2->{_tfile};

    }
    else {
        print("unif2, tfile, missing tfile,\n");
    }
}

=head2 sub v00 


=cut

sub v00 {

    my ( $self, $v00 ) = @_;
    if ( $v00 ne $empty_string ) {

        $unif2->{_v00}  = $v00;
        $unif2->{_note} = $unif2->{_note} . ' v00=' . $unif2->{_v00};
        $unif2->{_Step} = $unif2->{_Step} . ' v00=' . $unif2->{_v00};

    }
    else {
        print("unif2, v00, missing v00,\n");
    }
}

=head2 sub x0 


=cut

sub x0 {

    my ( $self, $x0 ) = @_;
    if ( $x0 ne $empty_string ) {

        $unif2->{_x0}   = $x0;
        $unif2->{_note} = $unif2->{_note} . ' x0=' . $unif2->{_x0};
        $unif2->{_Step} = $unif2->{_Step} . ' x0=' . $unif2->{_x0};

    }
    else {
        print("unif2, x0, missing x0,\n");
    }
}

=head2 sub z0 


=cut

sub z0 {

    my ( $self, $z0 ) = @_;
    if ( $z0 ne $empty_string ) {

        $unif2->{_z0}   = $z0;
        $unif2->{_note} = $unif2->{_note} . ' z0=' . $unif2->{_z0};
        $unif2->{_Step} = $unif2->{_Step} . ' z0=' . $unif2->{_z0};

    }
    else {
        print("unif2, z0, missing z0,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 14;

    return ($max_index);
}

1;
