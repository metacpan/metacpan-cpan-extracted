package App::SeismicUnixGui::sunix::filter::sutvband;

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
 SUTVBAND - time-variant bandpass filter (sine-squared taper)  



 sutvband <stdin >stdout tf= f=			        



 Required parameters:                                          

       dt = (from header)      time sampling interval (sec)    

       tf=             times for which f-vector is specified   

       f=f1,f2,f3,f4   Corner frequencies corresponding to the 

                       times in tf. Specify as many f= as      

                       there are entries in tf.                



 The filters are applied in frequency domain.                  



 Example:                                                      

 sutvband <data tf=.2,1.5 f=10,12.5,40,50 f=10,12.5,30,40 | ...



 Credits:

      CWP: Jack, Ken



 Trace header fields accessed:  ns, dt, delrt



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

my $sutvband			= {
	_dt					=> '',
	_f					=> '',
	_tf					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sutvband->{_Step}     = 'sutvband'.$sutvband->{_Step};
	return ( $sutvband->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sutvband->{_note}     = 'sutvband'.$sutvband->{_note};
	return ( $sutvband->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sutvband->{_dt}			= '';
		$sutvband->{_f}			= '';
		$sutvband->{_tf}			= '';
		$sutvband->{_Step}			= '';
		$sutvband->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sutvband->{_dt}		= $dt;
		$sutvband->{_note}		= $sutvband->{_note}.' dt='.$sutvband->{_dt};
		$sutvband->{_Step}		= $sutvband->{_Step}.' dt='.$sutvband->{_dt};

	} else { 
		print("sutvband, dt, missing dt,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$sutvband->{_f}		= $f;
		$sutvband->{_note}		= $sutvband->{_note}.' f='.$sutvband->{_f};
		$sutvband->{_Step}		= $sutvband->{_Step}.' f='.$sutvband->{_f};

	} else { 
		print("sutvband, f, missing f,\n");
	 }
 }


=head2 sub tf 


=cut

 sub tf {

	my ( $self,$tf )		= @_;
	if ( $tf ne $empty_string ) {

		$sutvband->{_tf}		= $tf;
		$sutvband->{_note}		= $sutvband->{_note}.' tf='.$sutvband->{_tf};
		$sutvband->{_Step}		= $sutvband->{_Step}.' tf='.$sutvband->{_tf};

	} else { 
		print("sutvband, tf, missing tf,\n");
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
