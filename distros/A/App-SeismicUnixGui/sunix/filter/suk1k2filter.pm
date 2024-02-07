package App::SeismicUnixGui::sunix::filter::suk1k2filter;

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
 SUK1K2FILTER - symmetric box-like K-domain filter defined by the	

		  cartesian product of two sin^2-tapered polygonal	

		  filters defined in k1 and k2				



     suk1k2filter <infile >outfile [optional parameters]		



 Optional parameters:							

 k1=val1,val2,...	array of K1 filter wavenumbers			

 k2=val1,val2,...	array of K2 filter wavenumbers			

 amps1=a1,a2,...	array of K1 filter amplitudes			

 amps2=a1,a2,...	array of K2 filter amplitudes			

 d1=tr.d1 or 1.0	sampling interval in first (fast) dimension	

 d2=tr.d1 or 1.0	sampling interval in second (slow) dimension	

 quad=0		=0 all four quandrants				

			=1 (quadrants 1 and 4) 				

			=2 (quadrants 2 and 3) 				



 Defaults:								

 k1=.10*(nyq1),.15*(nyq1),.45*(nyq1),.50*(nyq1)			

 k2=.10*(nyq2),.15*(nyq2),.45*(nyq2),.50*(nyq2)			

 amps1=0.,1.,...,1.,0.  trapezoid-like bandpass filter			

 amps2=0.,1.,...,1.,0.  trapezoid-like bandpass filter			



 The nyquist wavenumbers, nyq1 and nyq2, are computed internally.	



 verbose=0	verbose = 1 echoes information				



 tmpdir= 	 if non-empty, use the value as a directory path	

		 prefix for storing temporary files; else if the	

	         the CWP_TMPDIR environment variable is set use		

	         its value for the path; else use tmpfile()		



 Notes:								

 The filter is assumed to be symmetric, to yield real output		



 Because the data are assumed to be purely spatial (i.e. non-seismic), 

 the data are assumed to have trace id (30), corresponding to (z,x) data



 The relation: w = 2 pi F is well known for frequency, but there	

 doesn't seem to be a commonly used letter corresponding to F for the	

 spatial conjugate transform variables.  We use K1 and K2 for this.	

 More specifically we assume a phase:					

		-i(k1 x1 + k2 x2) = -2 pi i(K1 x1 + K2 x2).		

 and K1, K2 define our respective wavenumbers.				





 Credits:

     CWP: John Stockwell, November 1995.



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

my $suk1k2filter			= {
	_amps1					=> '',
	_amps2					=> '',
	_d1					=> '',
	_d2					=> '',
	_k1					=> '',
	_k2					=> '',
	_quad					=> '',
	_tmpdir					=> '',
	_verbose					=> '',
	_w					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suk1k2filter->{_Step}     = 'suk1k2filter'.$suk1k2filter->{_Step};
	return ( $suk1k2filter->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suk1k2filter->{_note}     = 'suk1k2filter'.$suk1k2filter->{_note};
	return ( $suk1k2filter->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suk1k2filter->{_amps1}			= '';
		$suk1k2filter->{_amps2}			= '';
		$suk1k2filter->{_d1}			= '';
		$suk1k2filter->{_d2}			= '';
		$suk1k2filter->{_k1}			= '';
		$suk1k2filter->{_k2}			= '';
		$suk1k2filter->{_quad}			= '';
		$suk1k2filter->{_tmpdir}			= '';
		$suk1k2filter->{_verbose}			= '';
		$suk1k2filter->{_w}			= '';
		$suk1k2filter->{_Step}			= '';
		$suk1k2filter->{_note}			= '';
 }


=head2 sub amps1 


=cut

 sub amps1 {

	my ( $self,$amps1 )		= @_;
	if ( $amps1 ne $empty_string ) {

		$suk1k2filter->{_amps1}		= $amps1;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' amps1='.$suk1k2filter->{_amps1};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' amps1='.$suk1k2filter->{_amps1};

	} else { 
		print("suk1k2filter, amps1, missing amps1,\n");
	 }
 }


=head2 sub amps2 


=cut

 sub amps2 {

	my ( $self,$amps2 )		= @_;
	if ( $amps2 ne $empty_string ) {

		$suk1k2filter->{_amps2}		= $amps2;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' amps2='.$suk1k2filter->{_amps2};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' amps2='.$suk1k2filter->{_amps2};

	} else { 
		print("suk1k2filter, amps2, missing amps2,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$suk1k2filter->{_d1}		= $d1;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' d1='.$suk1k2filter->{_d1};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' d1='.$suk1k2filter->{_d1};

	} else { 
		print("suk1k2filter, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$suk1k2filter->{_d2}		= $d2;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' d2='.$suk1k2filter->{_d2};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' d2='.$suk1k2filter->{_d2};

	} else { 
		print("suk1k2filter, d2, missing d2,\n");
	 }
 }


=head2 sub k1 


=cut

 sub k1 {

	my ( $self,$k1 )		= @_;
	if ( $k1 ne $empty_string ) {

		$suk1k2filter->{_k1}		= $k1;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' k1='.$suk1k2filter->{_k1};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' k1='.$suk1k2filter->{_k1};

	} else { 
		print("suk1k2filter, k1, missing k1,\n");
	 }
 }


=head2 sub k2 


=cut

 sub k2 {

	my ( $self,$k2 )		= @_;
	if ( $k2 ne $empty_string ) {

		$suk1k2filter->{_k2}		= $k2;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' k2='.$suk1k2filter->{_k2};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' k2='.$suk1k2filter->{_k2};

	} else { 
		print("suk1k2filter, k2, missing k2,\n");
	 }
 }


=head2 sub quad 


=cut

 sub quad {

	my ( $self,$quad )		= @_;
	if ( $quad ne $empty_string ) {

		$suk1k2filter->{_quad}		= $quad;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' quad='.$suk1k2filter->{_quad};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' quad='.$suk1k2filter->{_quad};

	} else { 
		print("suk1k2filter, quad, missing quad,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$suk1k2filter->{_tmpdir}		= $tmpdir;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' tmpdir='.$suk1k2filter->{_tmpdir};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' tmpdir='.$suk1k2filter->{_tmpdir};

	} else { 
		print("suk1k2filter, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suk1k2filter->{_verbose}		= $verbose;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' verbose='.$suk1k2filter->{_verbose};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' verbose='.$suk1k2filter->{_verbose};

	} else { 
		print("suk1k2filter, verbose, missing verbose,\n");
	 }
 }


=head2 sub w 


=cut

 sub w {

	my ( $self,$w )		= @_;
	if ( $w ne $empty_string ) {

		$suk1k2filter->{_w}		= $w;
		$suk1k2filter->{_note}		= $suk1k2filter->{_note}.' w='.$suk1k2filter->{_w};
		$suk1k2filter->{_Step}		= $suk1k2filter->{_Step}.' w='.$suk1k2filter->{_w};

	} else { 
		print("suk1k2filter, w, missing w,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 9;

    return($max_index);
}
 
 
1;
