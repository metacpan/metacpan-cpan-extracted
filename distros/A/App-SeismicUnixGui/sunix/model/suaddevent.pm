package App::SeismicUnixGui::sunix::model::suaddevent;

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


 SUADDEVENT - add a linear or hyperbolic moveout event to seismic data 



 suaddevent <stdin >stdout [optional parameters]		       



 Required parameters:						  

       none								



 Optional parameters:						  

     type=nmo    =lmo for linear event 				

     t0=1.0      zero-offset intercept time IN SECONDS			

     vel=3000.   moveout velocity in m/s				

     amp=1.      amplitude						

     dt=	 must provide if 0 in headers (seconds)		



 Typical usage: 

     sunull nt=500 dt=0.004 ntr=100 | sushw key=offset a=-1000 b=20 \\ 

     | suaddevent v=1000 t0=0.05 type=lmo | suaddevent v=1800 t0=0.8 \

     | sufilter f=8,12,75,90 | suxwigb clip=1 &	     		







 Credits:

      Gary Billings, Talisman Energy, May 1996, Apr 2000, June 2001



 Note:  code is inefficient in that to add a single "spike", with sinc

	interpolation, an entire trace is generated and added to 

	the input trace.  In fact, only a few points needed be created

	and added, but the current coding avoids the bookkeeping re

	which are the relevant points!



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

my $suaddevent			= {
	_amp					=> '',
	_dt					=> '',
	_f					=> '',
	_nt					=> '',
	_t0					=> '',
	_type					=> '',
	_v					=> '',
	_vel					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suaddevent->{_Step}     = 'suaddevent'.$suaddevent->{_Step};
	return ( $suaddevent->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suaddevent->{_note}     = 'suaddevent'.$suaddevent->{_note};
	return ( $suaddevent->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suaddevent->{_amp}			= '';
		$suaddevent->{_dt}			= '';
		$suaddevent->{_f}			= '';
		$suaddevent->{_nt}			= '';
		$suaddevent->{_t0}			= '';
		$suaddevent->{_type}			= '';
		$suaddevent->{_v}			= '';
		$suaddevent->{_vel}			= '';
		$suaddevent->{_Step}			= '';
		$suaddevent->{_note}			= '';
 }


=head2 sub amp 


=cut

 sub amp {

	my ( $self,$amp )		= @_;
	if ( $amp ne $empty_string ) {

		$suaddevent->{_amp}		= $amp;
		$suaddevent->{_note}		= $suaddevent->{_note}.' amp='.$suaddevent->{_amp};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' amp='.$suaddevent->{_amp};

	} else { 
		print("suaddevent, amp, missing amp,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suaddevent->{_dt}		= $dt;
		$suaddevent->{_note}		= $suaddevent->{_note}.' dt='.$suaddevent->{_dt};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' dt='.$suaddevent->{_dt};

	} else { 
		print("suaddevent, dt, missing dt,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$suaddevent->{_f}		= $f;
		$suaddevent->{_note}		= $suaddevent->{_note}.' f='.$suaddevent->{_f};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' f='.$suaddevent->{_f};

	} else { 
		print("suaddevent, f, missing f,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suaddevent->{_nt}		= $nt;
		$suaddevent->{_note}		= $suaddevent->{_note}.' nt='.$suaddevent->{_nt};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' nt='.$suaddevent->{_nt};

	} else { 
		print("suaddevent, nt, missing nt,\n");
	 }
 }


=head2 sub t0 


=cut

 sub t0 {

	my ( $self,$t0 )		= @_;
	if ( $t0 ne $empty_string ) {

		$suaddevent->{_t0}		= $t0;
		$suaddevent->{_note}		= $suaddevent->{_note}.' t0='.$suaddevent->{_t0};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' t0='.$suaddevent->{_t0};

	} else { 
		print("suaddevent, t0, missing t0,\n");
	 }
 }


=head2 sub type 


=cut

 sub type {

	my ( $self,$type )		= @_;
	if ( $type ne $empty_string ) {

		$suaddevent->{_type}		= $type;
		$suaddevent->{_note}		= $suaddevent->{_note}.' type='.$suaddevent->{_type};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' type='.$suaddevent->{_type};

	} else { 
		print("suaddevent, type, missing type,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$suaddevent->{_v}		= $v;
		$suaddevent->{_note}		= $suaddevent->{_note}.' v='.$suaddevent->{_v};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' v='.$suaddevent->{_v};

	} else { 
		print("suaddevent, v, missing v,\n");
	 }
 }


=head2 sub vel 


=cut

 sub vel {

	my ( $self,$vel )		= @_;
	if ( $vel ne $empty_string ) {

		$suaddevent->{_vel}		= $vel;
		$suaddevent->{_note}		= $suaddevent->{_note}.' vel='.$suaddevent->{_vel};
		$suaddevent->{_Step}		= $suaddevent->{_Step}.' vel='.$suaddevent->{_vel};

	} else { 
		print("suaddevent, vel, missing vel,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
