package App::SeismicUnixGui::sunix::filter::sukfilter;

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
 SUKFILTER - radially symmetric K-domain, sin^2-tapered, polygonal	

		  filter						



     sukfilter <infile >outfile [optional parameters]			



 Optional parameters:							

 k=val1,val2,...	array of K filter wavenumbers			

 amps=a1,a2,...	array of K filter amplitudes			

 d1=tr.d1 or 1.0	sampling interval in first (fast) dimension	

 d2=tr.d1 or 1.0	sampling interval in second (slow) dimension	



 Defaults:								

 k=.10*(nyq),.15*(nyq),.45*(nyq),.50*(nyq)				

 amps=0.,1.,...,1.,0.  trapezoid-like bandpass filter			



 The nyquist wavenumbers, nyq=sqrt(nyq1^2 + nyq2^2) is  computed	

 internally.								



 Notes:								

 The filter is assumed to be symmetric, to yield real output.		



 Because the data are assumed to be purely spatial (i.e. non-seismic), 

 the data are assumed to have trace id (30), corresponding to (z,x) data



 The relation: w = 2 pi F is well known for frequency, but there	

 doesn't seem to be a commonly used letter corresponding to F for the	

 spatial conjugate transform variables.  We use K1 and K2 for this.	

 More specifically we assume a phase:					

		-i(k1 x1 + k2 x2) = -2 pi i(K1 x1 + K2 x2).		

 and K1, K2 define our respective wavenumbers.				





 Credits:

     CWP: John Stockwell, June 1997.



 Trace header fields accessed: ns, d1, d2



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

my $sukfilter			= {
	_amps					=> '',
	_d1					=> '',
	_d2					=> '',
	_k					=> '',
	_nyq					=> '',
	_w					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sukfilter->{_Step}     = 'sukfilter'.$sukfilter->{_Step};
	return ( $sukfilter->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sukfilter->{_note}     = 'sukfilter'.$sukfilter->{_note};
	return ( $sukfilter->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sukfilter->{_amps}			= '';
		$sukfilter->{_d1}			= '';
		$sukfilter->{_d2}			= '';
		$sukfilter->{_k}			= '';
		$sukfilter->{_nyq}			= '';
		$sukfilter->{_w}			= '';
		$sukfilter->{_Step}			= '';
		$sukfilter->{_note}			= '';
 }


=head2 sub amps 


=cut

 sub amps {

	my ( $self,$amps )		= @_;
	if ( $amps ne $empty_string ) {

		$sukfilter->{_amps}		= $amps;
		$sukfilter->{_note}		= $sukfilter->{_note}.' amps='.$sukfilter->{_amps};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' amps='.$sukfilter->{_amps};

	} else { 
		print("sukfilter, amps, missing amps,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$sukfilter->{_d1}		= $d1;
		$sukfilter->{_note}		= $sukfilter->{_note}.' d1='.$sukfilter->{_d1};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' d1='.$sukfilter->{_d1};

	} else { 
		print("sukfilter, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$sukfilter->{_d2}		= $d2;
		$sukfilter->{_note}		= $sukfilter->{_note}.' d2='.$sukfilter->{_d2};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' d2='.$sukfilter->{_d2};

	} else { 
		print("sukfilter, d2, missing d2,\n");
	 }
 }


=head2 sub k 


=cut

 sub k {

	my ( $self,$k )		= @_;
	if ( $k ne $empty_string ) {

		$sukfilter->{_k}		= $k;
		$sukfilter->{_note}		= $sukfilter->{_note}.' k='.$sukfilter->{_k};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' k='.$sukfilter->{_k};

	} else { 
		print("sukfilter, k, missing k,\n");
	 }
 }


=head2 sub nyq 


=cut

 sub nyq {

	my ( $self,$nyq )		= @_;
	if ( $nyq ne $empty_string ) {

		$sukfilter->{_nyq}		= $nyq;
		$sukfilter->{_note}		= $sukfilter->{_note}.' nyq='.$sukfilter->{_nyq};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' nyq='.$sukfilter->{_nyq};

	} else { 
		print("sukfilter, nyq, missing nyq,\n");
	 }
 }


=head2 sub w 


=cut

 sub w {

	my ( $self,$w )		= @_;
	if ( $w ne $empty_string ) {

		$sukfilter->{_w}		= $w;
		$sukfilter->{_note}		= $sukfilter->{_note}.' w='.$sukfilter->{_w};
		$sukfilter->{_Step}		= $sukfilter->{_Step}.' w='.$sukfilter->{_w};

	} else { 
		print("sukfilter, w, missing w,\n");
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
