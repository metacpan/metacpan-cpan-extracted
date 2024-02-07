package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suresamp;

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
 SURESAMP - Resample in time                                       



 suresamp <stdin >stdout  [optional parameters]                    



 Required parameters:                                              

     none                                                          



 Optional Parameters:                                              

    nt=tr.ns    number of time samples on output                   

    dt=         time sampling interval on output                   

                default is:                                        

                tr.dt/10^6     seismic data                        

                tr.d1          non-seismic data                    

    tmin=       time of first sample in output                     

                default is:                                        

                tr.delrt/10^3  seismic data                        

                tr.f1          non-seismic data                    

    rf=         resampling factor;                                 

                if defined, set nt=nt_in*rf and dt=dt_in/rf        

    verbose=0   =1 for advisory messages                           





 Example 1: (assume original data had dt=.004 nt=256)              

    sufilter <data f=40,50 amps=1.,0. |                            

    suresamp nt=128 dt=.008 | ...                                  

 Using the resampling factor rf, this example translates to:       

    sufilter <data f=40,50 amps=1.,0. | suresamp rf=0.5 | ...      



 Note the typical anti-alias filtering before sub-sampling!        



 Example 2: (assume original data had dt=.004 nt=256)              

    suresamp <data nt=512 dt=.002 | ...                            

 or use:                                                           

    suresamp <data rf=2 | ...                                      



 Example 3: (assume original data had d1=.1524 nt=8192)            

    sufilter <data f=0,1,3,3.28 amps=1,1,1,0 |                     

    suresamp <data nt=4096 dt=.3048 | ...                          



 Example 4: (assume original data had d1=.5 nt=4096)               

    suresamp <data nt=8192 dt=.25 | ...                            





 Credits:

    CWP: Dave (resamp algorithm), Jack (SU adaptation)

    CENPET: Werner M. Heigl - modified for well log support

    RISSC: Nils Maercklin 2006 - minor fixes, added rf option



 Algorithm:

    Resampling is done via 8-coefficient sinc-interpolation.

    See "$CWPROOT/src/cwp/lib/intsinc8.c" for technical details.



 Trace header fields accessed:  ns, dt, delrt, d1, f1, trid

 Trace header fields modified:  ns, dt, delrt (only when set tmin)

                                d1, f1 (only when set tmin)



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

my $suresamp			= {
	_d1					=> '',
	_dt					=> '',
	_f					=> '',
	_nt					=> '',
	_rf					=> '',
	_tmin					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suresamp->{_Step}     = 'suresamp'.$suresamp->{_Step};
	return ( $suresamp->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suresamp->{_note}     = 'suresamp'.$suresamp->{_note};
	return ( $suresamp->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suresamp->{_d1}			= '';
		$suresamp->{_dt}			= '';
		$suresamp->{_f}			= '';
		$suresamp->{_nt}			= '';
		$suresamp->{_rf}			= '';
		$suresamp->{_tmin}			= '';
		$suresamp->{_verbose}			= '';
		$suresamp->{_Step}			= '';
		$suresamp->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$suresamp->{_d1}		= $d1;
		$suresamp->{_note}		= $suresamp->{_note}.' d1='.$suresamp->{_d1};
		$suresamp->{_Step}		= $suresamp->{_Step}.' d1='.$suresamp->{_d1};

	} else { 
		print("suresamp, d1, missing d1,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suresamp->{_dt}		= $dt;
		$suresamp->{_note}		= $suresamp->{_note}.' dt='.$suresamp->{_dt};
		$suresamp->{_Step}		= $suresamp->{_Step}.' dt='.$suresamp->{_dt};

	} else { 
		print("suresamp, dt, missing dt,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$suresamp->{_f}		= $f;
		$suresamp->{_note}		= $suresamp->{_note}.' f='.$suresamp->{_f};
		$suresamp->{_Step}		= $suresamp->{_Step}.' f='.$suresamp->{_f};

	} else { 
		print("suresamp, f, missing f,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suresamp->{_nt}		= $nt;
		$suresamp->{_note}		= $suresamp->{_note}.' nt='.$suresamp->{_nt};
		$suresamp->{_Step}		= $suresamp->{_Step}.' nt='.$suresamp->{_nt};

	} else { 
		print("suresamp, nt, missing nt,\n");
	 }
 }


=head2 sub rf 


=cut

 sub rf {

	my ( $self,$rf )		= @_;
	if ( $rf ne $empty_string ) {

		$suresamp->{_rf}		= $rf;
		$suresamp->{_note}		= $suresamp->{_note}.' rf='.$suresamp->{_rf};
		$suresamp->{_Step}		= $suresamp->{_Step}.' rf='.$suresamp->{_rf};

	} else { 
		print("suresamp, rf, missing rf,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$suresamp->{_tmin}		= $tmin;
		$suresamp->{_note}		= $suresamp->{_note}.' tmin='.$suresamp->{_tmin};
		$suresamp->{_Step}		= $suresamp->{_Step}.' tmin='.$suresamp->{_tmin};

	} else { 
		print("suresamp, tmin, missing tmin,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suresamp->{_verbose}		= $verbose;
		$suresamp->{_note}		= $suresamp->{_note}.' verbose='.$suresamp->{_verbose};
		$suresamp->{_Step}		= $suresamp->{_Step}.' verbose='.$suresamp->{_verbose};

	} else { 
		print("suresamp, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
