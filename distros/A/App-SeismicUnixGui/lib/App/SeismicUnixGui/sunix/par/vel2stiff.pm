package App::SeismicUnixGui::sunix::par::vel2stiff;

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
 VEL2STIFF - Transforms VELocities, densities, and Thomsen or Sayers   

		parameters to elastic STIFFnesses 			



 vel2stiff  [Required parameters] [Optional Parameters] > stdout	



 Required parameters:							

 vpfile=	file with P-wave velocities				

 vsfile=	file with S-wave velocities				

 rhofile=	file with densities					



 Optional Parameters:							

 epsfile=	file with Thomsen/Sayers epsilon			

 deltafile=	file with Thomsen/Sayers delta			 	

 gammafile=	file with Thomsen/Sayers gamma			 	

 phi_file=	angle of axis of symmetry from vertical (radians)	



 c11_file=c11_file     output filename for c11 values                  

 c13_file=c13_file     output filename for c13 values                  

 c15_file=c15_file     output filename for c15 values                  

 c33_file=c33_file     output filename for c33 values                  

 c35_file=c35_file     output filename for c35 values                  

 c44_file=c44_file     output filename for c44 values                  

 c55_file=c55_file     output filename for c55 values                  

 c66_file=c66_file     output filename for c66 values                  



 paramtype=1  (1) Thomsen parameters, (0) Sayers parameters(see below) 



 nx=101	number of x samples 2nd (slow) dimension		

 nz=101	number of z samples 1st (fast) dimension		



 Notes: 								

 Transforms velocities, density and Thomsen/Sayers parameters		

 epsilon, delta, and gamma into elastic stiffness coefficients.	



 If only P-wave, S-wave velocities and density is given as input,	

 the model is assumed to be isotropic.					



 If files containing Thomsen/Sayers parameters are given, the model	

 will be assumed to have VTI symmetry.		 			



 All input files  vpfile, vsfile, rhofile etc. are assumed to consist  

 only of C style binary floating point numbers representing the        

 corresponding  material values of vp, vs, rho etc. Similarly, the output

 files consist of the coresponding stiffnesses as C style binary floats. 

 If the output files are to be used as input for a modeling program,   

 such as suea2df, then further, the contents are assumed be arrays of  

 floating point numbers of the form of   Array[n2][n1], where the fast 

 dimension, dimension 1, represents depth.                             







  Author:

  CWP: Sverre Brandsberg-Dahl 1999



  Extended:

  CWP: Stig-Kyrre Foss 2001

  - to include the option to use the parameters by Sayers (1995) 

  instead of the Thomsen parameters



 Technical reference:

 Sayers, C. M.: Simplified anisotropy parameters for transversely 

 isotropic sedimentary rocks. Geophysics 1995, pages 1933-1935.



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

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $vel2stiff = {
	_c11_file  => '',
	_c13_file  => '',
	_c15_file  => '',
	_c33_file  => '',
	_c35_file  => '',
	_c44_file  => '',
	_c55_file  => '',
	_c66_file  => '',
	_deltafile => '',
	_epsfile   => '',
	_gammafile => '',
	_nx        => '',
	_nz        => '',
	_paramtype => '',
	_phi_file  => '',
	_rhofile   => '',
	_vpfile    => '',
	_vsfile    => '',
	_Step      => '',
	_note      => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$vel2stiff->{_Step} = 'vel2stiff' . $vel2stiff->{_Step};
	return ( $vel2stiff->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$vel2stiff->{_note} = 'vel2stiff' . $vel2stiff->{_note};
	return ( $vel2stiff->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$vel2stiff->{_c11_file}  = '';
	$vel2stiff->{_c13_file}  = '';
	$vel2stiff->{_c15_file}  = '';
	$vel2stiff->{_c33_file}  = '';
	$vel2stiff->{_c35_file}  = '';
	$vel2stiff->{_c44_file}  = '';
	$vel2stiff->{_c55_file}  = '';
	$vel2stiff->{_c66_file}  = '';
	$vel2stiff->{_deltafile} = '';
	$vel2stiff->{_epsfile}   = '';
	$vel2stiff->{_gammafile} = '';
	$vel2stiff->{_nx}        = '';
	$vel2stiff->{_nz}        = '';
	$vel2stiff->{_paramtype} = '';
	$vel2stiff->{_phi_file}  = '';
	$vel2stiff->{_rhofile}   = '';
	$vel2stiff->{_vpfile}    = '';
	$vel2stiff->{_vsfile}    = '';
	$vel2stiff->{_Step}      = '';
	$vel2stiff->{_note}      = '';
}

=head2 sub c11_file 


=cut

sub c11_file {

	my ( $self, $c11_file ) = @_;
	if ( $c11_file ne $empty_string ) {

		$vel2stiff->{_c11_file} = $c11_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c11_file=' . $vel2stiff->{_c11_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c11_file=' . $vel2stiff->{_c11_file};

	} else {
		print("vel2stiff, c11_file, missing c11_file,\n");
	}
}

=head2 sub c13_file 


=cut

sub c13_file {

	my ( $self, $c13_file ) = @_;
	if ( $c13_file ne $empty_string ) {

		$vel2stiff->{_c13_file} = $c13_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c13_file=' . $vel2stiff->{_c13_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c13_file=' . $vel2stiff->{_c13_file};

	} else {
		print("vel2stiff, c13_file, missing c13_file,\n");
	}
}

=head2 sub c15_file 


=cut

sub c15_file {

	my ( $self, $c15_file ) = @_;
	if ( $c15_file ne $empty_string ) {

		$vel2stiff->{_c15_file} = $c15_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c15_file=' . $vel2stiff->{_c15_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c15_file=' . $vel2stiff->{_c15_file};

	} else {
		print("vel2stiff, c15_file, missing c15_file,\n");
	}
}

=head2 sub c33_file 


=cut

sub c33_file {

	my ( $self, $c33_file ) = @_;
	if ( $c33_file ne $empty_string ) {

		$vel2stiff->{_c33_file} = $c33_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c33_file=' . $vel2stiff->{_c33_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c33_file=' . $vel2stiff->{_c33_file};

	} else {
		print("vel2stiff, c33_file, missing c33_file,\n");
	}
}

=head2 sub c35_file 


=cut

sub c35_file {

	my ( $self, $c35_file ) = @_;
	if ( $c35_file ne $empty_string ) {

		$vel2stiff->{_c35_file} = $c35_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c35_file=' . $vel2stiff->{_c35_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c35_file=' . $vel2stiff->{_c35_file};

	} else {
		print("vel2stiff, c35_file, missing c35_file,\n");
	}
}

=head2 sub c44_file 


=cut

sub c44_file {

	my ( $self, $c44_file ) = @_;
	if ( $c44_file ne $empty_string ) {

		$vel2stiff->{_c44_file} = $c44_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c44_file=' . $vel2stiff->{_c44_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c44_file=' . $vel2stiff->{_c44_file};

	} else {
		print("vel2stiff, c44_file, missing c44_file,\n");
	}
}

=head2 sub c55_file 


=cut

sub c55_file {

	my ( $self, $c55_file ) = @_;
	if ( $c55_file ne $empty_string ) {

		$vel2stiff->{_c55_file} = $c55_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c55_file=' . $vel2stiff->{_c55_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c55_file=' . $vel2stiff->{_c55_file};

	} else {
		print("vel2stiff, c55_file, missing c55_file,\n");
	}
}

=head2 sub c66_file 


=cut

sub c66_file {

	my ( $self, $c66_file ) = @_;
	if ( $c66_file ne $empty_string ) {

		$vel2stiff->{_c66_file} = $c66_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' c66_file=' . $vel2stiff->{_c66_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' c66_file=' . $vel2stiff->{_c66_file};

	} else {
		print("vel2stiff, c66_file, missing c66_file,\n");
	}
}

=head2 sub deltafile 


=cut

sub deltafile {

	my ( $self, $deltafile ) = @_;
	if ( $deltafile ne $empty_string ) {

		$vel2stiff->{_deltafile} = $deltafile;
		$vel2stiff->{_note}      = $vel2stiff->{_note} . ' deltafile=' . $vel2stiff->{_deltafile};
		$vel2stiff->{_Step}      = $vel2stiff->{_Step} . ' deltafile=' . $vel2stiff->{_deltafile};

	} else {
		print("vel2stiff, deltafile, missing deltafile,\n");
	}
}

=head2 sub epsfile 


=cut

sub epsfile {

	my ( $self, $epsfile ) = @_;
	if ( $epsfile ne $empty_string ) {

		$vel2stiff->{_epsfile} = $epsfile;
		$vel2stiff->{_note}    = $vel2stiff->{_note} . ' epsfile=' . $vel2stiff->{_epsfile};
		$vel2stiff->{_Step}    = $vel2stiff->{_Step} . ' epsfile=' . $vel2stiff->{_epsfile};

	} else {
		print("vel2stiff, epsfile, missing epsfile,\n");
	}
}

=head2 sub gammafile 


=cut

sub gammafile {

	my ( $self, $gammafile ) = @_;
	if ( $gammafile ne $empty_string ) {

		$vel2stiff->{_gammafile} = $gammafile;
		$vel2stiff->{_note}      = $vel2stiff->{_note} . ' gammafile=' . $vel2stiff->{_gammafile};
		$vel2stiff->{_Step}      = $vel2stiff->{_Step} . ' gammafile=' . $vel2stiff->{_gammafile};

	} else {
		print("vel2stiff, gammafile, missing gammafile,\n");
	}
}

=head2 sub nx 


=cut

sub nx {

	my ( $self, $nx ) = @_;
	if ( $nx ne $empty_string ) {

		$vel2stiff->{_nx}   = $nx;
		$vel2stiff->{_note} = $vel2stiff->{_note} . ' nx=' . $vel2stiff->{_nx};
		$vel2stiff->{_Step} = $vel2stiff->{_Step} . ' nx=' . $vel2stiff->{_nx};

	} else {
		print("vel2stiff, nx, missing nx,\n");
	}
}

=head2 sub nz 


=cut

sub nz {

	my ( $self, $nz ) = @_;
	if ( $nz ne $empty_string ) {

		$vel2stiff->{_nz}   = $nz;
		$vel2stiff->{_note} = $vel2stiff->{_note} . ' nz=' . $vel2stiff->{_nz};
		$vel2stiff->{_Step} = $vel2stiff->{_Step} . ' nz=' . $vel2stiff->{_nz};

	} else {
		print("vel2stiff, nz, missing nz,\n");
	}
}

=head2 sub paramtype 


=cut

sub paramtype {

	my ( $self, $paramtype ) = @_;
	if ( $paramtype ne $empty_string ) {

		$vel2stiff->{_paramtype} = $paramtype;
		$vel2stiff->{_note}      = $vel2stiff->{_note} . ' paramtype=' . $vel2stiff->{_paramtype};
		$vel2stiff->{_Step}      = $vel2stiff->{_Step} . ' paramtype=' . $vel2stiff->{_paramtype};

	} else {
		print("vel2stiff, paramtype, missing paramtype,\n");
	}
}

=head2 sub phi_file 


=cut

sub phi_file {

	my ( $self, $phi_file ) = @_;
	if ( $phi_file ne $empty_string ) {

		$vel2stiff->{_phi_file} = $phi_file;
		$vel2stiff->{_note}     = $vel2stiff->{_note} . ' phi_file=' . $vel2stiff->{_phi_file};
		$vel2stiff->{_Step}     = $vel2stiff->{_Step} . ' phi_file=' . $vel2stiff->{_phi_file};

	} else {
		print("vel2stiff, phi_file, missing phi_file,\n");
	}
}

=head2 sub rhofile 


=cut

sub rhofile {

	my ( $self, $rhofile ) = @_;
	if ( $rhofile ne $empty_string ) {

		$vel2stiff->{_rhofile} = $rhofile;
		$vel2stiff->{_note}    = $vel2stiff->{_note} . ' rhofile=' . $vel2stiff->{_rhofile};
		$vel2stiff->{_Step}    = $vel2stiff->{_Step} . ' rhofile=' . $vel2stiff->{_rhofile};

	} else {
		print("vel2stiff, rhofile, missing rhofile,\n");
	}
}

=head2 sub vpfile 


=cut

sub vpfile {

	my ( $self, $vpfile ) = @_;
	if ( $vpfile ne $empty_string ) {

		$vel2stiff->{_vpfile} = $vpfile;
		$vel2stiff->{_note}   = $vel2stiff->{_note} . ' vpfile=' . $vel2stiff->{_vpfile};
		$vel2stiff->{_Step}   = $vel2stiff->{_Step} . ' vpfile=' . $vel2stiff->{_vpfile};

	} else {
		print("vel2stiff, vpfile, missing vpfile,\n");
	}
}

=head2 sub vsfile 


=cut

sub vsfile {

	my ( $self, $vsfile ) = @_;
	if ( $vsfile ne $empty_string ) {

		$vel2stiff->{_vsfile} = $vsfile;
		$vel2stiff->{_note}   = $vel2stiff->{_note} . ' vsfile=' . $vel2stiff->{_vsfile};
		$vel2stiff->{_Step}   = $vel2stiff->{_Step} . ' vsfile=' . $vel2stiff->{_vsfile};

	} else {
		print("vel2stiff, vsfile, missing vsfile,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 17;

	return ($max_index);
}

1;
