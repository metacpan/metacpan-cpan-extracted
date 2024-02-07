package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudivstack;

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
 SUDIVSTACK -  Diversity Stacking using either average power or peak   

               power within windows                                    





 Required parameters:                                                  

    none                                                               



 Optional parameters:                                                  

    key=tracf        key header word to stack on                       

    winlen=0.064     window length in seconds.                         

                     typical choices: 0.064, 0.128, 0.256,             

                                      0.512, 1.024, 2.048, 4.096       

                     if not specified the entire trace is used         



    peak=1           peak power option default is average power        



 Notes:                                                                

    Diversity stacking is a noise reduction technique used in the      

    summation of duplicate data. Each trace is scaled by the inverse   

    of its average power prior to stacking.  The composite trace is    

    then renormalized by dividing by the sum of the scalers used.      



    This program stacks adjacent traces having the same key header     

    word, which can be specified by the key parameter. The default     

    is "tracf" (trace number within field record).                   

    For more information on key header words, type "sukeyword -o".   



 Examples:                                                             

    For duplicate field shot records:                                  

        susort < field.data tracf | sudivstack > stack.data            

    For CDP ordered data:                                              

        sudivstack < cdp.data key=cdp > stack.data                     





 

 Author: Mary Palen-Murphy,

         Masters' candidate, Colorado School of Mines,

         Geophysics Department, 1994



 Implementation of "key=" option: Nils Maercklin,

         GeoForschungsZentrum (GFZ) Potsdam, Germany, 2002.



 References:



    Embree, P.,1968, Diversity seismic record stacking method and system:

        U.S. patent 3,398,396.

    Gimlin, D. R., and Smith, J. W., 1980, A comparison of seismic trace 

        summing techniques: Geophysics, vol. 45, pages 1017-1041.



 Trace header fields accessed: ns, dt, key=keyword

 Trace header fields modified: tracl





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

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $sudivstack			= {
	_key					=> '',
	_peak					=> '',
	_winlen					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudivstack->{_Step}     = 'sudivstack'.$sudivstack->{_Step};
	return ( $sudivstack->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudivstack->{_note}     = 'sudivstack'.$sudivstack->{_note};
	return ( $sudivstack->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudivstack->{_key}			= '';
		$sudivstack->{_peak}			= '';
		$sudivstack->{_winlen}			= '';
		$sudivstack->{_Step}			= '';
		$sudivstack->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sudivstack->{_key}		= $key;
		$sudivstack->{_note}		= $sudivstack->{_note}.' key='.$sudivstack->{_key};
		$sudivstack->{_Step}		= $sudivstack->{_Step}.' key='.$sudivstack->{_key};

	} else { 
		print("sudivstack, key, missing key,\n");
	 }
 }


=head2 sub peak 


=cut

 sub peak {

	my ( $self,$peak )		= @_;
	if ( $peak ne $empty_string ) {

		$sudivstack->{_peak}		= $peak;
		$sudivstack->{_note}		= $sudivstack->{_note}.' peak='.$sudivstack->{_peak};
		$sudivstack->{_Step}		= $sudivstack->{_Step}.' peak='.$sudivstack->{_peak};

	} else { 
		print("sudivstack, peak, missing peak,\n");
	 }
 }


=head2 sub winlen 


=cut

 sub winlen {

	my ( $self,$winlen )		= @_;
	if ( $winlen ne $empty_string ) {

		$sudivstack->{_winlen}		= $winlen;
		$sudivstack->{_note}		= $sudivstack->{_note}.' winlen='.$sudivstack->{_winlen};
		$sudivstack->{_Step}		= $sudivstack->{_Step}.' winlen='.$sudivstack->{_winlen};

	} else { 
		print("sudivstack, winlen, missing winlen,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 2;

    return($max_index);
}
 
 
1;
