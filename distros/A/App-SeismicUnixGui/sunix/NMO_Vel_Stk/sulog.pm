package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sulog;

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
 SULOG -- time axis log-stretch of seismic traces		



 sulog [optional parameters] <stdin >stdout 			



 Required parameters:						

	none				 			



 Optional parameters:						

	ntmin= .1*nt		minimum time sample of interest	

	outpar=/dev/tty		output parameter file, contains:

				number of samples (nt=)		

				minimum time sample (ntmin=)	

				output number of samples (ntau=)

	m=3			length of stretched data	

				is set according to		

					ntau = nextpow(m*nt)	

	ntau= pow of 2		override for length of stretched

				data (useful for padding zeros	

				to avoid aliasing)		



 NOTES:							

	ntmin is required to avoid taking log of zero and to 	

	keep number of outsamples (ntau) from becoming enormous.

        Data above ntmin is zeroed out.			



	The output parameters will be needed by suilog to 	

	reconstruct the original data. 				



 EXAMPLE PROCESSING SEQUENCE:					

		sulog outpar=logpar <data1 >data2		

		suilog par=logpar <data2 >data3			





 Credits:

	CWP: Shuki, Chris



 Caveats:

 	Amplitudes are not well preserved.



 Trace header fields accessed: ns, dt

 Trace header fields modified: ns, dt



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

my $sulog			= {
	_m					=> '',
	_nt					=> '',
	_ntau					=> '',
	_ntmin					=> '',
	_outpar					=> '',
	_par					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sulog->{_Step}     = 'sulog'.$sulog->{_Step};
	return ( $sulog->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sulog->{_note}     = 'sulog'.$sulog->{_note};
	return ( $sulog->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sulog->{_m}			= '';
		$sulog->{_nt}			= '';
		$sulog->{_ntau}			= '';
		$sulog->{_ntmin}			= '';
		$sulog->{_outpar}			= '';
		$sulog->{_par}			= '';
		$sulog->{_Step}			= '';
		$sulog->{_note}			= '';
 }


=head2 sub m 


=cut

 sub m {

	my ( $self,$m )		= @_;
	if ( $m ne $empty_string ) {

		$sulog->{_m}		= $m;
		$sulog->{_note}		= $sulog->{_note}.' m='.$sulog->{_m};
		$sulog->{_Step}		= $sulog->{_Step}.' m='.$sulog->{_m};

	} else { 
		print("sulog, m, missing m,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sulog->{_nt}		= $nt;
		$sulog->{_note}		= $sulog->{_note}.' nt='.$sulog->{_nt};
		$sulog->{_Step}		= $sulog->{_Step}.' nt='.$sulog->{_nt};

	} else { 
		print("sulog, nt, missing nt,\n");
	 }
 }


=head2 sub ntau 


=cut

 sub ntau {

	my ( $self,$ntau )		= @_;
	if ( $ntau ne $empty_string ) {

		$sulog->{_ntau}		= $ntau;
		$sulog->{_note}		= $sulog->{_note}.' ntau='.$sulog->{_ntau};
		$sulog->{_Step}		= $sulog->{_Step}.' ntau='.$sulog->{_ntau};

	} else { 
		print("sulog, ntau, missing ntau,\n");
	 }
 }


=head2 sub ntmin 


=cut

 sub ntmin {

	my ( $self,$ntmin )		= @_;
	if ( $ntmin ne $empty_string ) {

		$sulog->{_ntmin}		= $ntmin;
		$sulog->{_note}		= $sulog->{_note}.' ntmin='.$sulog->{_ntmin};
		$sulog->{_Step}		= $sulog->{_Step}.' ntmin='.$sulog->{_ntmin};

	} else { 
		print("sulog, ntmin, missing ntmin,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$sulog->{_outpar}		= $outpar;
		$sulog->{_note}		= $sulog->{_note}.' outpar='.$sulog->{_outpar};
		$sulog->{_Step}		= $sulog->{_Step}.' outpar='.$sulog->{_outpar};

	} else { 
		print("sulog, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$sulog->{_par}		= $par;
		$sulog->{_note}		= $sulog->{_note}.' par='.$sulog->{_par};
		$sulog->{_Step}		= $sulog->{_Step}.' par='.$sulog->{_par};

	} else { 
		print("sulog, par, missing par,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
