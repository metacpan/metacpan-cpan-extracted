package App::SeismicUnixGui::sunix::well::suwellrf;

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
 SUWELLRF - convert WELL log depth, velocity, density data into a	

	uniformly sampled normal incidence Reflectivity Function of time



 suwellrf [required parameters] [optional parameters] > [stdout]	



 Required Parameters:							

 dvrfile=	file containing depth, velocity, and density values	

 ...or...								

 dvfile=	file containing depth and velocity values		

 drfile=	file containing depth and density values		

 ...or...								

 dfile=	file containing depth values				

 vfile=	file containing velocity log values			

 rhofile=	file containing density log values			

 nval= 	number of triplets of d,v,r values if dvrfile is set,	

 		number of pairs of d,v and d,r values dvfile and drfile	

		are set, or number of values if dfile, vfile, and rhofile

		are set.						



 Optional Parameters:							

 dtout=.004	desired time sampling interval (sec) in output		

 ntr=1         number of traces to output 				



 Notes:								

 The format of the input file(s) is C-style binary float. These files	

 may be constructed from ascii file via:   				



       a2b n1=3 < dvrfile.ascii > dvrfile.bin				

 ...or...								

       a2b n1=2 < dvfile.ascii > dvfile.bin				

       a2b n1=2 < drfile.ascii > drfile.bin				

 ...or...								

       a2b n1=1 < dfile.ascii > dfile.bin				

       a2b n1=1 < vfile.ascii > dfile.bin				

       a2b n1=1 < rhofile.ascii > rhofile.bin				



 A raw normal-incidence impedence reflectivity as a function of time is

 is generated using the smallest two-way traveltime implied by the	

 input velocities as the time sampling interval. This raw reflectivity	

 trace is then resampled to the desired output time sampling interval	

 via 8 point sinc interpolation. If the number of samples on the output

 exceeds SU_NFLTS the output trace will be truncated to that value.	



 Caveat: 								

 This program is really only a first rough attempt at creating a well	

 log utility. User input and modifications are welcome.		



 See also:  suresamp 							







 Author:  CWP: John Stockwell, Summer 2001, updated Summer 2002.

 inspired by a project by GP grad student Leo Brown



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

my $suwellrf			= {
	_dfile					=> '',
	_drfile					=> '',
	_dtout					=> '',
	_dvfile					=> '',
	_dvrfile					=> '',
	_n1					=> '',
	_ntr					=> '',
	_nval					=> '',
	_rhofile					=> '',
	_vfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suwellrf->{_Step}     = 'suwellrf'.$suwellrf->{_Step};
	return ( $suwellrf->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suwellrf->{_note}     = 'suwellrf'.$suwellrf->{_note};
	return ( $suwellrf->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suwellrf->{_dfile}			= '';
		$suwellrf->{_drfile}			= '';
		$suwellrf->{_dtout}			= '';
		$suwellrf->{_dvfile}			= '';
		$suwellrf->{_dvrfile}			= '';
		$suwellrf->{_n1}			= '';
		$suwellrf->{_ntr}			= '';
		$suwellrf->{_nval}			= '';
		$suwellrf->{_rhofile}			= '';
		$suwellrf->{_vfile}			= '';
		$suwellrf->{_Step}			= '';
		$suwellrf->{_note}			= '';
 }


=head2 sub dfile 


=cut

 sub dfile {

	my ( $self,$dfile )		= @_;
	if ( $dfile ne $empty_string ) {

		$suwellrf->{_dfile}		= $dfile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' dfile='.$suwellrf->{_dfile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' dfile='.$suwellrf->{_dfile};

	} else { 
		print("suwellrf, dfile, missing dfile,\n");
	 }
 }


=head2 sub drfile 


=cut

 sub drfile {

	my ( $self,$drfile )		= @_;
	if ( $drfile ne $empty_string ) {

		$suwellrf->{_drfile}		= $drfile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' drfile='.$suwellrf->{_drfile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' drfile='.$suwellrf->{_drfile};

	} else { 
		print("suwellrf, drfile, missing drfile,\n");
	 }
 }


=head2 sub dtout 


=cut

 sub dtout {

	my ( $self,$dtout )		= @_;
	if ( $dtout ne $empty_string ) {

		$suwellrf->{_dtout}		= $dtout;
		$suwellrf->{_note}		= $suwellrf->{_note}.' dtout='.$suwellrf->{_dtout};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' dtout='.$suwellrf->{_dtout};

	} else { 
		print("suwellrf, dtout, missing dtout,\n");
	 }
 }


=head2 sub dvfile 


=cut

 sub dvfile {

	my ( $self,$dvfile )		= @_;
	if ( $dvfile ne $empty_string ) {

		$suwellrf->{_dvfile}		= $dvfile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' dvfile='.$suwellrf->{_dvfile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' dvfile='.$suwellrf->{_dvfile};

	} else { 
		print("suwellrf, dvfile, missing dvfile,\n");
	 }
 }


=head2 sub dvrfile 


=cut

 sub dvrfile {

	my ( $self,$dvrfile )		= @_;
	if ( $dvrfile ne $empty_string ) {

		$suwellrf->{_dvrfile}		= $dvrfile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' dvrfile='.$suwellrf->{_dvrfile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' dvrfile='.$suwellrf->{_dvrfile};

	} else { 
		print("suwellrf, dvrfile, missing dvrfile,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$suwellrf->{_n1}		= $n1;
		$suwellrf->{_note}		= $suwellrf->{_note}.' n1='.$suwellrf->{_n1};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' n1='.$suwellrf->{_n1};

	} else { 
		print("suwellrf, n1, missing n1,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$suwellrf->{_ntr}		= $ntr;
		$suwellrf->{_note}		= $suwellrf->{_note}.' ntr='.$suwellrf->{_ntr};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' ntr='.$suwellrf->{_ntr};

	} else { 
		print("suwellrf, ntr, missing ntr,\n");
	 }
 }


=head2 sub nval 


=cut

 sub nval {

	my ( $self,$nval )		= @_;
	if ( $nval ne $empty_string ) {

		$suwellrf->{_nval}		= $nval;
		$suwellrf->{_note}		= $suwellrf->{_note}.' nval='.$suwellrf->{_nval};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' nval='.$suwellrf->{_nval};

	} else { 
		print("suwellrf, nval, missing nval,\n");
	 }
 }


=head2 sub rhofile 


=cut

 sub rhofile {

	my ( $self,$rhofile )		= @_;
	if ( $rhofile ne $empty_string ) {

		$suwellrf->{_rhofile}		= $rhofile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' rhofile='.$suwellrf->{_rhofile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' rhofile='.$suwellrf->{_rhofile};

	} else { 
		print("suwellrf, rhofile, missing rhofile,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suwellrf->{_vfile}		= $vfile;
		$suwellrf->{_note}		= $suwellrf->{_note}.' vfile='.$suwellrf->{_vfile};
		$suwellrf->{_Step}		= $suwellrf->{_Step}.' vfile='.$suwellrf->{_vfile};

	} else { 
		print("suwellrf, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
