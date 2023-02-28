package App::SeismicUnixGui::sunix::statsMath::sualford;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUALFORD - trace by trace Alford Rotation of shear wave data volumes  



 sualford inS11=file1 inS22=file2 inS12=file3 inS21=file4		

 outS11=file5 outS22=file6 outS12=file7 outS21=file8 [optional         

 parameters]                                                           



 Required Parameters:                                                  

 inS11=	input data volume for the 11 component			

 inS12=	input data volume for the 12 component			

 inS21=	input data volume for the 21 component			

 inS22=	input data volume for the 22 component			

 outS11=	output data volume for the 11 component			

 outS12=	output data volume for the 11 component			

 outS21=	output data volume for the 11 component			

 outS22=	output data volume for the 11 component			



 Optional parameters:                                                  

 angle_inc=               sets the increment to the angle by which	

                         the data sets are rotated. The minimum is     

                         set to be 1 degree and default is 5.          

 Az_key=                  to set the header field storing the azimuths	

                         for the fast shear wave on the output volumes 

 Q_key=                   to set the header field storing the quality	

                         factors of performed optimum rotations        

 lag_key=                 to set the header field storing the lag in	

                         miliseconds the fast and slow shear components

 xcorr_key=               to set the header field containing the maxi-	

                         mum normalized cross-correlation between the	

                         and slow shear waves.                         

 taper=		  2*taper+1 is the length of the sample overlap 

			  between the unrotated data with the rotated   

			  data on the traces. The boundary between them 

 			  is defined by time windowning.                

				taper = -1, for no-overlap		

				taper = 0, for overlap of one sample	

				taper =>1, for use of cosine scale to   

					   to interpolate between the 	

					   unrotated and rotated parts	

					   of the traces		



 taperwin=               another taper used to taper the data within   

			  the window of analysis to diminish the effect 

                         of data near the window edges.In this way one 

                         can focus on a given reflector. Also given in 

                         number of samples                             



 maxlag=		  maximum limit in ms for the lag between fast  

 			  and slow shear waves. If this threshold is 	

			  attained or surpassed, the quality factor for	

			  the rotation is zeroed as well as all the     

			  parameters found for that certain rotation 	





 ntraces=		  number of traces to be used per computation   

			  ntraces=3 will use three adjacent traces to   

		          compute the angle of rotation                 "



 Notes:                                                                



 The Alford Rotation is a method to rotate the four components         

 of a shear wave survey into its natural coordinate system, where      

 the fast and slow shear correspond to the inline to inline shear (S11)

 and xline to xline (S22) volumes, respectively.                       



 This Alford Rotation code tries to maximize the energy in the         

 diagonal volumes, i.e., S11 and S22, while minimizing the energy      

 in the off-diagonals, i.e., in volumes S12 and S21, in a trace by     

 trace manner. It then returns the new rotated volumes, saving the     

 the quality factor for the rotation and azimuth angle of the fast     

 shear wave direction for each trace headers of the new rotated S11    

 volume.                                                               



 The fields in the header containing the Azimuth and Quality factor    

 and the sample lag between fast and slow shear are otrav, grnolf and  

 grnofr, respectively, by default. The values are multiplied by ten in 

 the case of the angles and by a thousand for quality factors. To      

 change this defaults use the optional parameters Az_key, Q_key and    

 lag_key                                                             	



 

 modified header fields:                                               

 the ones specified by Az_key, Q_key, lag_key and xcorr_key. By default

 these are otrav, grnlof, tstat and grnors, respectively.            	



 Credits:

	CWP: Rodrigo Felicio Fuck

      Code translated and adapted from original version in Fortran

      by Ted Schuck (1993)





 Schuck, E. L. , 1993, Multicomponent, three dimensional seismic 

 characterization of a fractured coalbed methane reservoir, 

 Cedar Hill Field, San Juan County, New Mexico, Ph.D. Thesis,

 Colorado School of Mines





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

my $sualford			= {
	_Az_key					=> '',
	_Q_key					=> '',
	_angle_inc					=> '',
	_inS11					=> '',
	_inS12					=> '',
	_inS21					=> '',
	_inS22					=> '',
	_lag_key					=> '',
	_maxlag					=> '',
	_ntraces					=> '',
	_outS11					=> '',
	_outS12					=> '',
	_outS21					=> '',
	_outS22					=> '',
	_taper					=> '',
	_taperwin					=> '',
	_xcorr_key					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sualford->{_Step}     = 'sualford'.$sualford->{_Step};
	return ( $sualford->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sualford->{_note}     = 'sualford'.$sualford->{_note};
	return ( $sualford->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sualford->{_Az_key}			= '';
		$sualford->{_Q_key}			= '';
		$sualford->{_angle_inc}			= '';
		$sualford->{_inS11}			= '';
		$sualford->{_inS12}			= '';
		$sualford->{_inS21}			= '';
		$sualford->{_inS22}			= '';
		$sualford->{_lag_key}			= '';
		$sualford->{_maxlag}			= '';
		$sualford->{_ntraces}			= '';
		$sualford->{_outS11}			= '';
		$sualford->{_outS12}			= '';
		$sualford->{_outS21}			= '';
		$sualford->{_outS22}			= '';
		$sualford->{_taper}			= '';
		$sualford->{_taperwin}			= '';
		$sualford->{_xcorr_key}			= '';
		$sualford->{_Step}			= '';
		$sualford->{_note}			= '';
 }


=head2 sub Az_key 


=cut

 sub Az_key {

	my ( $self,$Az_key )		= @_;
	if ( $Az_key ne $empty_string ) {

		$sualford->{_Az_key}		= $Az_key;
		$sualford->{_note}		= $sualford->{_note}.' Az_key='.$sualford->{_Az_key};
		$sualford->{_Step}		= $sualford->{_Step}.' Az_key='.$sualford->{_Az_key};

	} else { 
		print("sualford, Az_key, missing Az_key,\n");
	 }
 }


=head2 sub Q_key 


=cut

 sub Q_key {

	my ( $self,$Q_key )		= @_;
	if ( $Q_key ne $empty_string ) {

		$sualford->{_Q_key}		= $Q_key;
		$sualford->{_note}		= $sualford->{_note}.' Q_key='.$sualford->{_Q_key};
		$sualford->{_Step}		= $sualford->{_Step}.' Q_key='.$sualford->{_Q_key};

	} else { 
		print("sualford, Q_key, missing Q_key,\n");
	 }
 }


=head2 sub angle_inc 


=cut

 sub angle_inc {

	my ( $self,$angle_inc )		= @_;
	if ( $angle_inc ne $empty_string ) {

		$sualford->{_angle_inc}		= $angle_inc;
		$sualford->{_note}		= $sualford->{_note}.' angle_inc='.$sualford->{_angle_inc};
		$sualford->{_Step}		= $sualford->{_Step}.' angle_inc='.$sualford->{_angle_inc};

	} else { 
		print("sualford, angle_inc, missing angle_inc,\n");
	 }
 }


=head2 sub inS11 


=cut

 sub inS11 {

	my ( $self,$inS11 )		= @_;
	if ( $inS11 ne $empty_string ) {

		$sualford->{_inS11}		= $inS11;
		$sualford->{_note}		= $sualford->{_note}.' inS11='.$sualford->{_inS11};
		$sualford->{_Step}		= $sualford->{_Step}.' inS11='.$sualford->{_inS11};

	} else { 
		print("sualford, inS11, missing inS11,\n");
	 }
 }


=head2 sub inS12 


=cut

 sub inS12 {

	my ( $self,$inS12 )		= @_;
	if ( $inS12 ne $empty_string ) {

		$sualford->{_inS12}		= $inS12;
		$sualford->{_note}		= $sualford->{_note}.' inS12='.$sualford->{_inS12};
		$sualford->{_Step}		= $sualford->{_Step}.' inS12='.$sualford->{_inS12};

	} else { 
		print("sualford, inS12, missing inS12,\n");
	 }
 }


=head2 sub inS21 


=cut

 sub inS21 {

	my ( $self,$inS21 )		= @_;
	if ( $inS21 ne $empty_string ) {

		$sualford->{_inS21}		= $inS21;
		$sualford->{_note}		= $sualford->{_note}.' inS21='.$sualford->{_inS21};
		$sualford->{_Step}		= $sualford->{_Step}.' inS21='.$sualford->{_inS21};

	} else { 
		print("sualford, inS21, missing inS21,\n");
	 }
 }


=head2 sub inS22 


=cut

 sub inS22 {

	my ( $self,$inS22 )		= @_;
	if ( $inS22 ne $empty_string ) {

		$sualford->{_inS22}		= $inS22;
		$sualford->{_note}		= $sualford->{_note}.' inS22='.$sualford->{_inS22};
		$sualford->{_Step}		= $sualford->{_Step}.' inS22='.$sualford->{_inS22};

	} else { 
		print("sualford, inS22, missing inS22,\n");
	 }
 }


=head2 sub lag_key 


=cut

 sub lag_key {

	my ( $self,$lag_key )		= @_;
	if ( $lag_key ne $empty_string ) {

		$sualford->{_lag_key}		= $lag_key;
		$sualford->{_note}		= $sualford->{_note}.' lag_key='.$sualford->{_lag_key};
		$sualford->{_Step}		= $sualford->{_Step}.' lag_key='.$sualford->{_lag_key};

	} else { 
		print("sualford, lag_key, missing lag_key,\n");
	 }
 }


=head2 sub maxlag 


=cut

 sub maxlag {

	my ( $self,$maxlag )		= @_;
	if ( $maxlag ne $empty_string ) {

		$sualford->{_maxlag}		= $maxlag;
		$sualford->{_note}		= $sualford->{_note}.' maxlag='.$sualford->{_maxlag};
		$sualford->{_Step}		= $sualford->{_Step}.' maxlag='.$sualford->{_maxlag};

	} else { 
		print("sualford, maxlag, missing maxlag,\n");
	 }
 }


=head2 sub ntraces 


=cut

 sub ntraces {

	my ( $self,$ntraces )		= @_;
	if ( $ntraces ne $empty_string ) {

		$sualford->{_ntraces}		= $ntraces;
		$sualford->{_note}		= $sualford->{_note}.' ntraces='.$sualford->{_ntraces};
		$sualford->{_Step}		= $sualford->{_Step}.' ntraces='.$sualford->{_ntraces};

	} else { 
		print("sualford, ntraces, missing ntraces,\n");
	 }
 }


=head2 sub outS11 


=cut

 sub outS11 {

	my ( $self,$outS11 )		= @_;
	if ( $outS11 ne $empty_string ) {

		$sualford->{_outS11}		= $outS11;
		$sualford->{_note}		= $sualford->{_note}.' outS11='.$sualford->{_outS11};
		$sualford->{_Step}		= $sualford->{_Step}.' outS11='.$sualford->{_outS11};

	} else { 
		print("sualford, outS11, missing outS11,\n");
	 }
 }


=head2 sub outS12 


=cut

 sub outS12 {

	my ( $self,$outS12 )		= @_;
	if ( $outS12 ne $empty_string ) {

		$sualford->{_outS12}		= $outS12;
		$sualford->{_note}		= $sualford->{_note}.' outS12='.$sualford->{_outS12};
		$sualford->{_Step}		= $sualford->{_Step}.' outS12='.$sualford->{_outS12};

	} else { 
		print("sualford, outS12, missing outS12,\n");
	 }
 }


=head2 sub outS21 


=cut

 sub outS21 {

	my ( $self,$outS21 )		= @_;
	if ( $outS21 ne $empty_string ) {

		$sualford->{_outS21}		= $outS21;
		$sualford->{_note}		= $sualford->{_note}.' outS21='.$sualford->{_outS21};
		$sualford->{_Step}		= $sualford->{_Step}.' outS21='.$sualford->{_outS21};

	} else { 
		print("sualford, outS21, missing outS21,\n");
	 }
 }


=head2 sub outS22 


=cut

 sub outS22 {

	my ( $self,$outS22 )		= @_;
	if ( $outS22 ne $empty_string ) {

		$sualford->{_outS22}		= $outS22;
		$sualford->{_note}		= $sualford->{_note}.' outS22='.$sualford->{_outS22};
		$sualford->{_Step}		= $sualford->{_Step}.' outS22='.$sualford->{_outS22};

	} else { 
		print("sualford, outS22, missing outS22,\n");
	 }
 }


=head2 sub taper 


=cut

 sub taper {

	my ( $self,$taper )		= @_;
	if ( $taper ne $empty_string ) {

		$sualford->{_taper}		= $taper;
		$sualford->{_note}		= $sualford->{_note}.' taper='.$sualford->{_taper};
		$sualford->{_Step}		= $sualford->{_Step}.' taper='.$sualford->{_taper};

	} else { 
		print("sualford, taper, missing taper,\n");
	 }
 }


=head2 sub taperwin 


=cut

 sub taperwin {

	my ( $self,$taperwin )		= @_;
	if ( $taperwin ne $empty_string ) {

		$sualford->{_taperwin}		= $taperwin;
		$sualford->{_note}		= $sualford->{_note}.' taperwin='.$sualford->{_taperwin};
		$sualford->{_Step}		= $sualford->{_Step}.' taperwin='.$sualford->{_taperwin};

	} else { 
		print("sualford, taperwin, missing taperwin,\n");
	 }
 }


=head2 sub xcorr_key 


=cut

 sub xcorr_key {

	my ( $self,$xcorr_key )		= @_;
	if ( $xcorr_key ne $empty_string ) {

		$sualford->{_xcorr_key}		= $xcorr_key;
		$sualford->{_note}		= $sualford->{_note}.' xcorr_key='.$sualford->{_xcorr_key};
		$sualford->{_Step}		= $sualford->{_Step}.' xcorr_key='.$sualford->{_xcorr_key};

	} else { 
		print("sualford, xcorr_key, missing xcorr_key,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 16;

    return($max_index);
}
 
 
1;
