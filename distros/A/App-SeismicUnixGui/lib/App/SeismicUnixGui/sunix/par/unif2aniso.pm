package App::SeismicUnixGui::sunix::par::unif2aniso;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

   UNIF2ANISO - generate a 2-D UNIFormly sampled profile of elastic	
  constants from a layered model.					



  unif2aniso < infile [Parameters]					



 Required Parameters:							

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





 x0=0.0,0.0,..., 	distance x at which vp00 and vs00 are specified	

 z0=0.0,0.0,..., 	depth z at which vp00 and vs00 are specified	



 vp00=1500,2000,...,	P-velocity at each x0,z0 (m/sec)		

 vs00=866,1155...,	S-velocity at each x0,z0 (m/sec)		

 rho00=1000,1100,...,	density at each x0,z0 (kg/m^3)			

 q00=110,120,130,..,		attenuation Q, at each x0,z0 (kg/m^3)	



 eps00=0,0,0...,	Thomsen or Sayers epsilon			

 delta00=0,0,0...,	Thomsen or Sayers delta				

 gamma00=0,0,0...,	Thomsen or Sayers gamma				



 dqdx=0.0,0.0,...,	x-derivative of Q (d q/dx)			

 dqdz=0.0,0.0,...,	z-derivative of Q (d q/dz)			



 drdx=0.0,0.0,...,	x-derivative of density (d rho/dx)		

 drdz=0.0,0.0,...,	z-derivative of density (d rho/dz)		



 dvpdx=0.0,0.0,...,	x-derivative of P-velocity (dvp/dx)		

 dvpdz=0.0,0.0,...,	z-derivative of P-velocity (dvs/dz)		



 dvsdx=0.0,0.0,...,	x-derivative of S-velocity (dvs/dx)		

 dvsdz=0.0,0.0,...,	z-derivative of S-velocity (dvs/dz)		



 dedx=0.0,0.0,...,	x-derivative of epsilon (de/dx)			

 dedz=0.0,0.0,...,	z-derivative of epsilon with depth z (de/dz)	



 dddx=0.0,0.0,...,	x-derivative of delta (dd/dx)			

 dddz=0.0,0.0,...,	z-derivative of delta (dd/dz)			



 dgdz=0.0,0.0,...,	x-derivative of gamma (dg/dz)			

 dgdx=0.0,0.0,...,	z-derivative of gamma (dg/dx)			



 phi00=0,0,..., 	rotation angle(s) in each layer			



 ...output filenames 							

 c11_file=c11_file	output filename for c11 values	 		

 c13_file=c13_file	output filename for c13 values	 		

 c15_file=c15_file	output filename for c15 values	 		

 c33_file=c33_file	output filename for c33 values	 		

 c35_file=c35_file	output filename for c35 values	 		

 c44_file=c44_file	output filename for c44 values	 		

 c55_file=c55_file	output filename for c55 values	 		

 c66_file=c66_file	output filename for c66 values	 		



 rho_file=rho_file	output filename for density values 		

 q_file=q_file		output filename for Q values	 		



 paramtype=1   =1 Thomsen parameters, =0 Sayers parameters(see below)	

 method=linear		for linear interpolation of interface		

 			=mono for monotonic cubic interpolation of interface

			=akima for Akima's cubic interpolation of interface

			=spline for cubic spline interpolation of interface



 tfile=		=testfilename  if set, a sample input dataset is

 			 output to "testfilename".			
 			 
 			 prevents completion of demos -JL 7.14.21



 Notes:								

 The input file is an ASCII file containing x z values representing a	

 piecewise continuous velocity model with a flat surface on top.	



 The surface and each successive boundary between media is represented 

 by a list of selected x z pairs written column form. The first and	

 last x values must be the same for all boundaries. Use the entry	

 1.0  -99999  to separate the entries for successive boundaries. No	

 boundary may cross another. Note that the choice of the method of	

 interpolation may cause boundaries to cross that do not appear to	

 cross in the input data file.						



 The number of interfaces is specified by the parameter "ninf". This 

 number does not include the top surface of the model. The input data	

 format is the same as a CSHOT model file with all comments removed.	



 The algorithm works by transforming the P-wavespeed , S-wavespeed,	

 density and the Thomsen or Sayers parameters epsilon, delta, and gamma

 into elastic stiffness coefficients. Furthermore, the	user can specify

 rotations, phi, to the elasticity tensor in each layer.		



 Common ranges of Thomsen parameters are				

  epsilon:  0.0 -> 0.5							

  delta:   -0.2 -> 0.4							

  gamma:	0.0 -> 0.4							



 If only P-wave, S-wave velocities and density is given as input,	

 the model is, by definition,  isotropic.				



 If files containing Thomsen/Sayers parameters are given, the model	

 will be assumed to have VTI symmetry.		 			



 Example using test input file generating feature:			

 unif2aniso tfile=testfilename  produces a 5 interface demonstration model

 unif2aniso < testfilename 						

 ximage < c11_file n1=100 n2=100					

 ximage < c13_file n1=100 n2=100					

 ximage < c15_file n1=100 n2=100					

 ximage < c33_file n1=100 n2=100					

 ximage < c35_file n1=100 n2=100					

 ximage < c44_file n1=100 n2=100					

 ximage < c55_file n1=100 n2=100					

 ximage < c66_file n1=100 n2=100					

 ximage < rho_file n1=100 n2=100					

 ximage < q_file   n1=100 n2=100					







 Credits:

	CWP: John Stockwell, April 2005. 

 	CWP: based on program unif2 by Zhenyue Liu, 1994 





=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();
my $PL_SEISMIC                 = $Project->PL_SEISMIC();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $unif2aniso = {
	_aniso     => '',
	_c11_file  => '',
	_c13_file  => '',
	_c15_file  => '',
	_c33_file  => '',
	_c35_file  => '',
	_c44_file  => '',
	_c55_file  => '',
	_c66_file  => '',
	_dddx      => '',
	_dddz      => '',
	_dedx      => '',
	_dedz      => '',
	_delta00   => '',
	_dgdx      => '',
	_dgdz      => '',
	_dqdx      => '',
	_dqdz      => '',
	_drdx      => '',
	_drdz      => '',
	_dvpdx     => '',
	_dvpdz     => '',
	_dvsdx     => '',
	_dvsdz     => '',
	_dx        => '',
	_dz        => '',
	_eps00     => '',
	_fx        => '',
	_fz        => '',
	_gamma00   => '',
	_method    => '',
	_n1        => '',
	_ninf      => '',
	_npmax     => '',
	_nx        => '',
	_nz        => '',
	_paramtype => '',
	_phi00     => '',
	_q00       => '',
	_q_file    => '',
	_rho00     => '',
	_rho_file  => '',
	_tfile     => '',
	_vp00      => '',
	_vs00      => '',
	_x0        => '',
	_z0        => '',
	_Step      => '',
	_note      => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

unif2aniso writes anisotropy files locally wherever the executable
is run

=cut

sub Step {

	$unif2aniso->{_Step} =  "cd $PL_SEISMIC \n".'unif2aniso' . $unif2aniso->{_Step};
	return ( $unif2aniso->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$unif2aniso->{_note} = 'unif2aniso' . $unif2aniso->{_note};
	return ( $unif2aniso->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$unif2aniso->{_aniso}     = '';
	$unif2aniso->{_c11_file}  = '';
	$unif2aniso->{_c13_file}  = '';
	$unif2aniso->{_c15_file}  = '';
	$unif2aniso->{_c33_file}  = '';
	$unif2aniso->{_c35_file}  = '';
	$unif2aniso->{_c44_file}  = '';
	$unif2aniso->{_c55_file}  = '';
	$unif2aniso->{_c66_file}  = '';
	$unif2aniso->{_dddx}      = '';
	$unif2aniso->{_dddz}      = '';
	$unif2aniso->{_dedx}      = '';
	$unif2aniso->{_dedz}      = '';
	$unif2aniso->{_delta00}   = '';
	$unif2aniso->{_dgdx}      = '';
	$unif2aniso->{_dgdz}      = '';
	$unif2aniso->{_dqdx}      = '';
	$unif2aniso->{_dqdz}      = '';
	$unif2aniso->{_drdx}      = '';
	$unif2aniso->{_drdz}      = '';
	$unif2aniso->{_dvpdx}     = '';
	$unif2aniso->{_dvpdz}     = '';
	$unif2aniso->{_dvsdx}     = '';
	$unif2aniso->{_dvsdz}     = '';
	$unif2aniso->{_dx}        = '';
	$unif2aniso->{_dz}        = '';
	$unif2aniso->{_eps00}     = '';
	$unif2aniso->{_fx}        = '';
	$unif2aniso->{_fz}        = '';
	$unif2aniso->{_gamma00}   = '';
	$unif2aniso->{_method}    = '';
	$unif2aniso->{_n1}        = '';
	$unif2aniso->{_ninf}      = '';
	$unif2aniso->{_npmax}     = '';
	$unif2aniso->{_nx}        = '';
	$unif2aniso->{_nz}        = '';
	$unif2aniso->{_paramtype} = '';
	$unif2aniso->{_phi00}     = '';
	$unif2aniso->{_q00}       = '';
	$unif2aniso->{_q_file}    = '';
	$unif2aniso->{_rho00}     = '';
	$unif2aniso->{_rho_file}  = '';
	$unif2aniso->{_tfile}     = '';
	$unif2aniso->{_vp00}      = '';
	$unif2aniso->{_vs00}      = '';
	$unif2aniso->{_x0}        = '';
	$unif2aniso->{_z0}        = '';
	$unif2aniso->{_Step}      = '';
	$unif2aniso->{_note}      = '';
}

=head2 sub c11_file 


=cut

sub c11_file {

	my ( $self, $c11_file ) = @_;
	if ( $c11_file ne $empty_string ) {

		$unif2aniso->{_c11_file} = $c11_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c11_file=' . $unif2aniso->{_c11_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c11_file=' . $unif2aniso->{_c11_file};

	} else {
		print("unif2aniso, c11_file, missing c11_file,\n");
	}
}

=head2 sub c13_file 


=cut

sub c13_file {

	my ( $self, $c13_file ) = @_;
	if ( $c13_file ne $empty_string ) {

		$unif2aniso->{_c13_file} = $c13_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c13_file=' . $unif2aniso->{_c13_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c13_file=' . $unif2aniso->{_c13_file};

	} else {
		print("unif2aniso, c13_file, missing c13_file,\n");
	}
}

=head2 sub c15_file 


=cut

sub c15_file {

	my ( $self, $c15_file ) = @_;
	if ( $c15_file ne $empty_string ) {

		$unif2aniso->{_c15_file} = $c15_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c15_file=' . $unif2aniso->{_c15_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c15_file=' . $unif2aniso->{_c15_file};

	} else {
		print("unif2aniso, c15_file, missing c15_file,\n");
	}
}

=head2 sub c33_file 


=cut

sub c33_file {

	my ( $self, $c33_file ) = @_;
	if ( $c33_file ne $empty_string ) {

		$unif2aniso->{_c33_file} = $c33_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c33_file=' . $unif2aniso->{_c33_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c33_file=' . $unif2aniso->{_c33_file};

	} else {
		print("unif2aniso, c33_file, missing c33_file,\n");
	}
}

=head2 sub c35_file 


=cut

sub c35_file {

	my ( $self, $c35_file ) = @_;
	if ( $c35_file ne $empty_string ) {

		$unif2aniso->{_c35_file} = $c35_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c35_file=' . $unif2aniso->{_c35_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c35_file=' . $unif2aniso->{_c35_file};

	} else {
		print("unif2aniso, c35_file, missing c35_file,\n");
	}
}

=head2 sub c44_file 


=cut

sub c44_file {

	my ( $self, $c44_file ) = @_;
	if ( $c44_file ne $empty_string ) {

		$unif2aniso->{_c44_file} = $c44_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c44_file=' . $unif2aniso->{_c44_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c44_file=' . $unif2aniso->{_c44_file};

	} else {
		print("unif2aniso, c44_file, missing c44_file,\n");
	}
}

=head2 sub c55_file 


=cut

sub c55_file {

	my ( $self, $c55_file ) = @_;
	if ( $c55_file ne $empty_string ) {

		$unif2aniso->{_c55_file} = $c55_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c55_file=' . $unif2aniso->{_c55_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c55_file=' . $unif2aniso->{_c55_file};

	} else {
		print("unif2aniso, c55_file, missing c55_file,\n");
	}
}

=head2 sub c66_file 


=cut

sub c66_file {

	my ( $self, $c66_file ) = @_;
	if ( $c66_file ne $empty_string ) {

		$unif2aniso->{_c66_file} = $c66_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' c66_file=' . $unif2aniso->{_c66_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' c66_file=' . $unif2aniso->{_c66_file};

	} else {
		print("unif2aniso, c66_file, missing c66_file,\n");
	}
}

=head2 sub dddx 


=cut

sub dddx {

	my ( $self, $dddx ) = @_;
	if ( $dddx ne $empty_string ) {

		$unif2aniso->{_dddx} = $dddx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dddx=' . $unif2aniso->{_dddx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dddx=' . $unif2aniso->{_dddx};

	} else {
		print("unif2aniso, dddx, missing dddx,\n");
	}
}

=head2 sub dddz 


=cut

sub dddz {

	my ( $self, $dddz ) = @_;
	if ( $dddz ne $empty_string ) {

		$unif2aniso->{_dddz} = $dddz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dddz=' . $unif2aniso->{_dddz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dddz=' . $unif2aniso->{_dddz};

	} else {
		print("unif2aniso, dddz, missing dddz,\n");
	}
}

=head2 sub dedx 


=cut

sub dedx {

	my ( $self, $dedx ) = @_;
	if ( $dedx ne $empty_string ) {

		$unif2aniso->{_dedx} = $dedx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dedx=' . $unif2aniso->{_dedx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dedx=' . $unif2aniso->{_dedx};

	} else {
		print("unif2aniso, dedx, missing dedx,\n");
	}
}

=head2 sub dedz 


=cut

sub dedz {

	my ( $self, $dedz ) = @_;
	if ( $dedz ne $empty_string ) {

		$unif2aniso->{_dedz} = $dedz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dedz=' . $unif2aniso->{_dedz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dedz=' . $unif2aniso->{_dedz};

	} else {
		print("unif2aniso, dedz, missing dedz,\n");
	}
}

=head2 sub delta00 


=cut

sub delta00 {

	my ( $self, $delta00 ) = @_;
	if ( $delta00 ne $empty_string ) {

		$unif2aniso->{_delta00} = $delta00;
		$unif2aniso->{_note}    = $unif2aniso->{_note} . ' delta00=' . $unif2aniso->{_delta00};
		$unif2aniso->{_Step}    = $unif2aniso->{_Step} . ' delta00=' . $unif2aniso->{_delta00};

	} else {
		print("unif2aniso, delta00, missing delta00,\n");
	}
}

=head2 sub dgdx 


=cut

sub dgdx {

	my ( $self, $dgdx ) = @_;
	if ( $dgdx ne $empty_string ) {

		$unif2aniso->{_dgdx} = $dgdx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dgdx=' . $unif2aniso->{_dgdx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dgdx=' . $unif2aniso->{_dgdx};

	} else {
		print("unif2aniso, dgdx, missing dgdx,\n");
	}
}

=head2 sub dgdz 


=cut

sub dgdz {

	my ( $self, $dgdz ) = @_;
	if ( $dgdz ne $empty_string ) {

		$unif2aniso->{_dgdz} = $dgdz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dgdz=' . $unif2aniso->{_dgdz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dgdz=' . $unif2aniso->{_dgdz};

	} else {
		print("unif2aniso, dgdz, missing dgdz,\n");
	}
}

=head2 sub dqdx 


=cut

sub dqdx {

	my ( $self, $dqdx ) = @_;
	if ( $dqdx ne $empty_string ) {

		$unif2aniso->{_dqdx} = $dqdx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dqdx=' . $unif2aniso->{_dqdx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dqdx=' . $unif2aniso->{_dqdx};

	} else {
		print("unif2aniso, dqdx, missing dqdx,\n");
	}
}

=head2 sub dqdz 


=cut

sub dqdz {

	my ( $self, $dqdz ) = @_;
	if ( $dqdz ne $empty_string ) {

		$unif2aniso->{_dqdz} = $dqdz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dqdz=' . $unif2aniso->{_dqdz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dqdz=' . $unif2aniso->{_dqdz};

	} else {
		print("unif2aniso, dqdz, missing dqdz,\n");
	}
}

=head2 sub drdx 


=cut

sub drdx {

	my ( $self, $drdx ) = @_;
	if ( $drdx ne $empty_string ) {

		$unif2aniso->{_drdx} = $drdx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' drdx=' . $unif2aniso->{_drdx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' drdx=' . $unif2aniso->{_drdx};

	} else {
		print("unif2aniso, drdx, missing drdx,\n");
	}
}

=head2 sub drdz 


=cut

sub drdz {

	my ( $self, $drdz ) = @_;
	if ( $drdz ne $empty_string ) {

		$unif2aniso->{_drdz} = $drdz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' drdz=' . $unif2aniso->{_drdz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' drdz=' . $unif2aniso->{_drdz};

	} else {
		print("unif2aniso, drdz, missing drdz,\n");
	}
}

=head2 sub dvpdx 


=cut

sub dvpdx {

	my ( $self, $dvpdx ) = @_;
	if ( $dvpdx ne $empty_string ) {

		$unif2aniso->{_dvpdx} = $dvpdx;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' dvpdx=' . $unif2aniso->{_dvpdx};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' dvpdx=' . $unif2aniso->{_dvpdx};

	} else {
		print("unif2aniso, dvpdx, missing dvpdx,\n");
	}
}

=head2 sub dvpdz 


=cut

sub dvpdz {

	my ( $self, $dvpdz ) = @_;
	if ( $dvpdz ne $empty_string ) {

		$unif2aniso->{_dvpdz} = $dvpdz;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' dvpdz=' . $unif2aniso->{_dvpdz};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' dvpdz=' . $unif2aniso->{_dvpdz};

	} else {
		print("unif2aniso, dvpdz, missing dvpdz,\n");
	}
}

=head2 sub dvsdx 


=cut

sub dvsdx {

	my ( $self, $dvsdx ) = @_;
	if ( $dvsdx ne $empty_string ) {

		$unif2aniso->{_dvsdx} = $dvsdx;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' dvsdx=' . $unif2aniso->{_dvsdx};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' dvsdx=' . $unif2aniso->{_dvsdx};

	} else {
		print("unif2aniso, dvsdx, missing dvsdx,\n");
	}
}

=head2 sub dvsdz 


=cut

sub dvsdz {

	my ( $self, $dvsdz ) = @_;
	if ( $dvsdz ne $empty_string ) {

		$unif2aniso->{_dvsdz} = $dvsdz;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' dvsdz=' . $unif2aniso->{_dvsdz};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' dvsdz=' . $unif2aniso->{_dvsdz};

	} else {
		print("unif2aniso, dvsdz, missing dvsdz,\n");
	}
}

=head2 sub dx 


=cut

sub dx {

	my ( $self, $dx ) = @_;
	if ( $dx ne $empty_string ) {

		$unif2aniso->{_dx}   = $dx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dx=' . $unif2aniso->{_dx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dx=' . $unif2aniso->{_dx};

	} else {
		print("unif2aniso, dx, missing dx,\n");
	}
}

=head2 sub dz 


=cut

sub dz {

	my ( $self, $dz ) = @_;
	if ( $dz ne $empty_string ) {

		$unif2aniso->{_dz}   = $dz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' dz=' . $unif2aniso->{_dz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' dz=' . $unif2aniso->{_dz};

	} else {
		print("unif2aniso, dz, missing dz,\n");
	}
}

=head2 sub eps00 


=cut

sub eps00 {

	my ( $self, $eps00 ) = @_;
	if ( $eps00 ne $empty_string ) {

		$unif2aniso->{_eps00} = $eps00;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' eps00=' . $unif2aniso->{_eps00};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' eps00=' . $unif2aniso->{_eps00};

	} else {
		print("unif2aniso, eps00, missing eps00,\n");
	}
}

=head2 sub fx 


=cut

sub fx {

	my ( $self, $fx ) = @_;
	if ( $fx ne $empty_string ) {

		$unif2aniso->{_fx}   = $fx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' fx=' . $unif2aniso->{_fx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' fx=' . $unif2aniso->{_fx};

	} else {
		print("unif2aniso, fx, missing fx,\n");
	}
}

=head2 sub fz 


=cut

sub fz {

	my ( $self, $fz ) = @_;
	if ( $fz ne $empty_string ) {

		$unif2aniso->{_fz}   = $fz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' fz=' . $unif2aniso->{_fz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' fz=' . $unif2aniso->{_fz};

	} else {
		print("unif2aniso, fz, missing fz,\n");
	}
}

=head2 sub gamma00 


=cut

sub gamma00 {

	my ( $self, $gamma00 ) = @_;
	if ( $gamma00 ne $empty_string ) {

		$unif2aniso->{_gamma00} = $gamma00;
		$unif2aniso->{_note}    = $unif2aniso->{_note} . ' gamma00=' . $unif2aniso->{_gamma00};
		$unif2aniso->{_Step}    = $unif2aniso->{_Step} . ' gamma00=' . $unif2aniso->{_gamma00};

	} else {
		print("unif2aniso, gamma00, missing gamma00,\n");
	}
}

=head2 sub method 


=cut

sub method {

	my ( $self, $method ) = @_;
	if ( $method ne $empty_string ) {

		$unif2aniso->{_method} = $method;
		$unif2aniso->{_note}   = $unif2aniso->{_note} . ' method=' . $unif2aniso->{_method};
		$unif2aniso->{_Step}   = $unif2aniso->{_Step} . ' method=' . $unif2aniso->{_method};

	} else {
		print("unif2aniso, method, missing method,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$unif2aniso->{_n1}   = $n1;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' n1=' . $unif2aniso->{_n1};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' n1=' . $unif2aniso->{_n1};

	} else {
		print("unif2aniso, n1, missing n1,\n");
	}
}

=head2 sub ninf 


=cut

sub ninf {

	my ( $self, $ninf ) = @_;
	if ( $ninf ne $empty_string ) {

		$unif2aniso->{_ninf} = $ninf;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' ninf=' . $unif2aniso->{_ninf};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' ninf=' . $unif2aniso->{_ninf};

	} else {
		print("unif2aniso, ninf, missing ninf,\n");
	}
}

=head2 sub npmax 


=cut

sub npmax {

	my ( $self, $npmax ) = @_;
	if ( $npmax ne $empty_string ) {

		$unif2aniso->{_npmax} = $npmax;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' npmax=' . $unif2aniso->{_npmax};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' npmax=' . $unif2aniso->{_npmax};

	} else {
		print("unif2aniso, npmax, missing npmax,\n");
	}
}

=head2 sub nx 


=cut

sub nx {

	my ( $self, $nx ) = @_;
	if ( $nx ne $empty_string ) {

		$unif2aniso->{_nx}   = $nx;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' nx=' . $unif2aniso->{_nx};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' nx=' . $unif2aniso->{_nx};

	} else {
		print("unif2aniso, nx, missing nx,\n");
	}
}

=head2 sub nz 


=cut

sub nz {

	my ( $self, $nz ) = @_;
	if ( $nz ne $empty_string ) {

		$unif2aniso->{_nz}   = $nz;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' nz=' . $unif2aniso->{_nz};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' nz=' . $unif2aniso->{_nz};

	} else {
		print("unif2aniso, nz, missing nz,\n");
	}
}

=head2 sub paramtype 


=cut

sub paramtype {

	my ( $self, $paramtype ) = @_;
	if ( $paramtype ne $empty_string ) {

		$unif2aniso->{_paramtype} = $paramtype;
		$unif2aniso->{_note}      = $unif2aniso->{_note} . ' paramtype=' . $unif2aniso->{_paramtype};
		$unif2aniso->{_Step}      = $unif2aniso->{_Step} . ' paramtype=' . $unif2aniso->{_paramtype};

	} else {
		print("unif2aniso, paramtype, missing paramtype,\n");
	}
}

=head2 sub phi00 


=cut

sub phi00 {

	my ( $self, $phi00 ) = @_;
	if ( $phi00 ne $empty_string ) {

		$unif2aniso->{_phi00} = $phi00;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' phi00=' . $unif2aniso->{_phi00};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' phi00=' . $unif2aniso->{_phi00};

	} else {
		print("unif2aniso, phi00, missing phi00,\n");
	}
}

=head2 sub q00 


=cut

sub q00 {

	my ( $self, $q00 ) = @_;
	if ( $q00 ne $empty_string ) {

		$unif2aniso->{_q00}  = $q00;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' q00=' . $unif2aniso->{_q00};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' q00=' . $unif2aniso->{_q00};

	} else {
		print("unif2aniso, q00, missing q00,\n");
	}
}

=head2 sub q_file 


=cut

sub q_file {

	my ( $self, $q_file ) = @_;
	if ( $q_file ne $empty_string ) {

		$unif2aniso->{_q_file} = $q_file;
		$unif2aniso->{_note}   = $unif2aniso->{_note} . ' q_file=' . $unif2aniso->{_q_file};
		$unif2aniso->{_Step}   = $unif2aniso->{_Step} . ' q_file=' . $unif2aniso->{_q_file};

	} else {
		print("unif2aniso, q_file, missing q_file,\n");
	}
}

=head2 sub rho00 


=cut

sub rho00 {

	my ( $self, $rho00 ) = @_;
	if ( $rho00 ne $empty_string ) {

		$unif2aniso->{_rho00} = $rho00;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' rho00=' . $unif2aniso->{_rho00};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' rho00=' . $unif2aniso->{_rho00};

	} else {
		print("unif2aniso, rho00, missing rho00,\n");
	}
}

=head2 sub rho_file 


=cut

sub rho_file {

	my ( $self, $rho_file ) = @_;
	if ( $rho_file ne $empty_string ) {

		$unif2aniso->{_rho_file} = $rho_file;
		$unif2aniso->{_note}     = $unif2aniso->{_note} . ' rho_file=' . $unif2aniso->{_rho_file};
		$unif2aniso->{_Step}     = $unif2aniso->{_Step} . ' rho_file=' . $unif2aniso->{_rho_file};

	} else {
		print("unif2aniso, rho_file, missing rho_file,\n");
	}
}

=head2 sub tfile 


=cut

sub tfile {

	my ( $self, $tfile ) = @_;
	if ( $tfile ne $empty_string ) {

		$unif2aniso->{_tfile} = $tfile;
		$unif2aniso->{_note}  = $unif2aniso->{_note} . ' tfile=' . $unif2aniso->{_tfile};
		$unif2aniso->{_Step}  = $unif2aniso->{_Step} . ' tfile=' . $unif2aniso->{_tfile};

	} else {
		print("unif2aniso, tfile, missing tfile,\n");
	}
}

=head2 sub vp00 


=cut

sub vp00 {

	my ( $self, $vp00 ) = @_;
	if ( $vp00 ne $empty_string ) {

		$unif2aniso->{_vp00} = $vp00;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' vp00=' . $unif2aniso->{_vp00};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' vp00=' . $unif2aniso->{_vp00};

	} else {
		print("unif2aniso, vp00, missing vp00,\n");
	}
}

=head2 sub vs00 


=cut

sub vs00 {

	my ( $self, $vs00 ) = @_;
	if ( $vs00 ne $empty_string ) {

		$unif2aniso->{_vs00} = $vs00;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' vs00=' . $unif2aniso->{_vs00};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' vs00=' . $unif2aniso->{_vs00};

	} else {
		print("unif2aniso, vs00, missing vs00,\n");
	}
}

=head2 sub x0 


=cut

sub x0 {

	my ( $self, $x0 ) = @_;
	if ( $x0 ne $empty_string ) {

		$unif2aniso->{_x0}   = $x0;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' x0=' . $unif2aniso->{_x0};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' x0=' . $unif2aniso->{_x0};

	} else {
		print("unif2aniso, x0, missing x0,\n");
	}
}

=head2 sub z0 


=cut

sub z0 {

	my ( $self, $z0 ) = @_;
	if ( $z0 ne $empty_string ) {

		$unif2aniso->{_z0}   = $z0;
		$unif2aniso->{_note} = $unif2aniso->{_note} . ' z0=' . $unif2aniso->{_z0};
		$unif2aniso->{_Step} = $unif2aniso->{_Step} . ' z0=' . $unif2aniso->{_z0};

	} else {
		print("unif2aniso, z0, missing z0,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 42;

	return ($max_index);
}

1;
