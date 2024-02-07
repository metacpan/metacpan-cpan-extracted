package App::SeismicUnixGui::sunix::model::elatriuni;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 ELATRIUNI - convert TRIangulated ELAstic models to UNIformly sampled models



  elatriuni <modelfile nx= nz= [optional parameters]			



Required Parameters:							

nx                     number of x samples				

nz                     number of z samples				



Optional Parameters:							

dx=1.0                 x sampling interval    			    	

dz=1.0                 z sampling interval				

fx=0.0                 first x sampled					

fz=0.0                 first z sampled					

a1111file=a1111.bin    bin-file to store a1111 components 		

a3333file=a3333.bin    bin-file to store a3333 components 		

a1133file=a1133.bin    bin-file to store a1133 components 		

a1313file=a1313.bin    bin-file to store a1313 components 		

a1113file=a1113.bin    bin-file to store a1113 components 		

a3313file=a3313.bin    bin-file to store a3313 components 		

a1212file=a1212.bin    bin-file to store a1212 components 		

a1223file=a1212.bin    bin-file to store a1223 components 		

a2323file=a2323.bin    bin-file to store a2323 components 		

rhofile=rho.bin        bin-file to store rho components 		







 AUTHORS:  Andreas Rueger, Colorado School of Mines, 01/02/95

		  Dave Hale, Colorado School of Mines, 04/23/91

 	       	





=head2 User's notes (Juan Lorenzo)
untested

=cut


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

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $elatriuni			= {
	_a1111file					=> '',
	_a1113file					=> '',
	_a1133file					=> '',
	_a1212file					=> '',
	_a1223file					=> '',
	_a1313file					=> '',
	_a2323file					=> '',
	_a3313file					=> '',
	_a3333file					=> '',
	_dx					=> '',
	_dz					=> '',
	_fx					=> '',
	_fz					=> '',
	_nx					=> '',
	_rhofile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$elatriuni->{_Step}     = 'elatriuni'.$elatriuni->{_Step};
	return ( $elatriuni->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$elatriuni->{_note}     = 'elatriuni'.$elatriuni->{_note};
	return ( $elatriuni->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$elatriuni->{_a1111file}			= '';
		$elatriuni->{_a1113file}			= '';
		$elatriuni->{_a1133file}			= '';
		$elatriuni->{_a1212file}			= '';
		$elatriuni->{_a1223file}			= '';
		$elatriuni->{_a1313file}			= '';
		$elatriuni->{_a2323file}			= '';
		$elatriuni->{_a3313file}			= '';
		$elatriuni->{_a3333file}			= '';
		$elatriuni->{_dx}			= '';
		$elatriuni->{_dz}			= '';
		$elatriuni->{_fx}			= '';
		$elatriuni->{_fz}			= '';
		$elatriuni->{_nx}			= '';
		$elatriuni->{_rhofile}			= '';
		$elatriuni->{_Step}			= '';
		$elatriuni->{_note}			= '';
 }


=head2 sub a1111file 


=cut

 sub a1111file {

	my ( $self,$a1111file )		= @_;
	if ( $a1111file ne $empty_string ) {

		$elatriuni->{_a1111file}		= $a1111file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1111file='.$elatriuni->{_a1111file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1111file='.$elatriuni->{_a1111file};

	} else { 
		print("elatriuni, a1111file, missing a1111file,\n");
	 }
 }


=head2 sub a1113file 


=cut

 sub a1113file {

	my ( $self,$a1113file )		= @_;
	if ( $a1113file ne $empty_string ) {

		$elatriuni->{_a1113file}		= $a1113file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1113file='.$elatriuni->{_a1113file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1113file='.$elatriuni->{_a1113file};

	} else { 
		print("elatriuni, a1113file, missing a1113file,\n");
	 }
 }


=head2 sub a1133file 


=cut

 sub a1133file {

	my ( $self,$a1133file )		= @_;
	if ( $a1133file ne $empty_string ) {

		$elatriuni->{_a1133file}		= $a1133file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1133file='.$elatriuni->{_a1133file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1133file='.$elatriuni->{_a1133file};

	} else { 
		print("elatriuni, a1133file, missing a1133file,\n");
	 }
 }


=head2 sub a1212file 


=cut

 sub a1212file {

	my ( $self,$a1212file )		= @_;
	if ( $a1212file ne $empty_string ) {

		$elatriuni->{_a1212file}		= $a1212file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1212file='.$elatriuni->{_a1212file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1212file='.$elatriuni->{_a1212file};

	} else { 
		print("elatriuni, a1212file, missing a1212file,\n");
	 }
 }


=head2 sub a1223file 


=cut

 sub a1223file {

	my ( $self,$a1223file )		= @_;
	if ( $a1223file ne $empty_string ) {

		$elatriuni->{_a1223file}		= $a1223file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1223file='.$elatriuni->{_a1223file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1223file='.$elatriuni->{_a1223file};

	} else { 
		print("elatriuni, a1223file, missing a1223file,\n");
	 }
 }


=head2 sub a1313file 


=cut

 sub a1313file {

	my ( $self,$a1313file )		= @_;
	if ( $a1313file ne $empty_string ) {

		$elatriuni->{_a1313file}		= $a1313file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a1313file='.$elatriuni->{_a1313file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a1313file='.$elatriuni->{_a1313file};

	} else { 
		print("elatriuni, a1313file, missing a1313file,\n");
	 }
 }


=head2 sub a2323file 


=cut

 sub a2323file {

	my ( $self,$a2323file )		= @_;
	if ( $a2323file ne $empty_string ) {

		$elatriuni->{_a2323file}		= $a2323file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a2323file='.$elatriuni->{_a2323file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a2323file='.$elatriuni->{_a2323file};

	} else { 
		print("elatriuni, a2323file, missing a2323file,\n");
	 }
 }


=head2 sub a3313file 


=cut

 sub a3313file {

	my ( $self,$a3313file )		= @_;
	if ( $a3313file ne $empty_string ) {

		$elatriuni->{_a3313file}		= $a3313file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a3313file='.$elatriuni->{_a3313file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a3313file='.$elatriuni->{_a3313file};

	} else { 
		print("elatriuni, a3313file, missing a3313file,\n");
	 }
 }


=head2 sub a3333file 


=cut

 sub a3333file {

	my ( $self,$a3333file )		= @_;
	if ( $a3333file ne $empty_string ) {

		$elatriuni->{_a3333file}		= $a3333file;
		$elatriuni->{_note}		= $elatriuni->{_note}.' a3333file='.$elatriuni->{_a3333file};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' a3333file='.$elatriuni->{_a3333file};

	} else { 
		print("elatriuni, a3333file, missing a3333file,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$elatriuni->{_dx}		= $dx;
		$elatriuni->{_note}		= $elatriuni->{_note}.' dx='.$elatriuni->{_dx};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' dx='.$elatriuni->{_dx};

	} else { 
		print("elatriuni, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$elatriuni->{_dz}		= $dz;
		$elatriuni->{_note}		= $elatriuni->{_note}.' dz='.$elatriuni->{_dz};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' dz='.$elatriuni->{_dz};

	} else { 
		print("elatriuni, dz, missing dz,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$elatriuni->{_fx}		= $fx;
		$elatriuni->{_note}		= $elatriuni->{_note}.' fx='.$elatriuni->{_fx};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' fx='.$elatriuni->{_fx};

	} else { 
		print("elatriuni, fx, missing fx,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$elatriuni->{_fz}		= $fz;
		$elatriuni->{_note}		= $elatriuni->{_note}.' fz='.$elatriuni->{_fz};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' fz='.$elatriuni->{_fz};

	} else { 
		print("elatriuni, fz, missing fz,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$elatriuni->{_nx}		= $nx;
		$elatriuni->{_note}		= $elatriuni->{_note}.' nx='.$elatriuni->{_nx};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' nx='.$elatriuni->{_nx};

	} else { 
		print("elatriuni, nx, missing nx,\n");
	 }
 }


=head2 sub rhofile 


=cut

 sub rhofile {

	my ( $self,$rhofile )		= @_;
	if ( $rhofile ne $empty_string ) {

		$elatriuni->{_rhofile}		= $rhofile;
		$elatriuni->{_note}		= $elatriuni->{_note}.' rhofile='.$elatriuni->{_rhofile};
		$elatriuni->{_Step}		= $elatriuni->{_Step}.' rhofile='.$elatriuni->{_rhofile};

	} else { 
		print("elatriuni, rhofile, missing rhofile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 15;

    return($max_index);
}
 
 
1;
