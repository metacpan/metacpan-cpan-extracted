package App::SeismicUnixGui::sunix::statsMath::suhrot;

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
 SUHROT - Horizontal ROTation of three-component data			



 suhrot <stdin >stdout [optional parameters]				



 Required parameters:							

 none									



 Optional parameters:							

 angle=rad	unit of angles, choose "rad", "deg", or "gon

 inv=0		1 = inverse rotation (counter-clockwise)		

 verbose=0	1 = echo angle for each 3-C station			



 a=...		array of user-supplied rotation angles			

 x=0.0,...	array of corresponding header value(s)			

 key=tracf	header word defining 3-C station ("x")		



 ... or input angles from files:					

 n=0		 number of x and a values in input files		

 xfile=...   file containing the x values as specified by the		

 				"key" parameter			

 afile=...   file containing the a values				



 Notes:								

 Three adjacent traces are considered as one three-component		

 dataset.								

 By default, the data will be rotated from the Z-North-East (Z,N,E)	

 coordinate system into Z-Radial-Transverse (Z,R,T).			



	If one of the parameters "a=" or "afile=" is set, the data	

	are rotated by these user-supplied angles. Specified x values	

	must be monotonically increasing or decreasing, and afile and	

	xfile are files of binary (C-style) floats.			





 

 Author: Nils Maercklin,

		 Geophysics, Kiel University, Germany, 1999.





 Trace header fields accessed: ns, sx, sy, gx, gy, key=keyword

 Trace header fields modified: trid
 

=head2 User's notes (Juan Lorenzo)
 
Clockwise rotation for a left-handed system (ZNE): inv=0 and negative angles or inv=1 and positive angles

Two simple demos exist for suhrot -- 9.15.21

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

my $suhrot			= {
	_a					=> '',
	_afile					=> '',
	_angle					=> '',
	_inv					=> '',
	_key					=> '',
	_n					=> '',
	_verbose					=> '',
	_x					=> '',
	_xfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suhrot->{_Step}     = 'suhrot'.$suhrot->{_Step};
	return ( $suhrot->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suhrot->{_note}     = 'suhrot'.$suhrot->{_note};
	return ( $suhrot->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suhrot->{_a}			= '';
		$suhrot->{_afile}			= '';
		$suhrot->{_angle}			= '';
		$suhrot->{_inv}			= '';
		$suhrot->{_key}			= '';
		$suhrot->{_n}			= '';
		$suhrot->{_verbose}			= '';
		$suhrot->{_x}			= '';
		$suhrot->{_xfile}			= '';
		$suhrot->{_Step}			= '';
		$suhrot->{_note}			= '';
 }

=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$suhrot->{_a}		= $a;
		$suhrot->{_note}		= $suhrot->{_note}.' a='.$suhrot->{_a};
		$suhrot->{_Step}		= $suhrot->{_Step}.' a='.$suhrot->{_a};

	} else { 
		print("suhrot, a, missing a,\n");
	 }
 }


=head2 sub afile 


=cut

 sub afile {

	my ( $self,$afile )		= @_;
	if ( $afile ne $empty_string ) {

		$suhrot->{_afile}		= $afile;
		$suhrot->{_note}		= $suhrot->{_note}.' afile='.$suhrot->{_afile};
		$suhrot->{_Step}		= $suhrot->{_Step}.' afile='.$suhrot->{_afile};

	} else { 
		print("suhrot, afile, missing afile,\n");
	 }
 }


=head2 sub angle 


=cut

 sub angle {

	my ( $self,$angle )		= @_;
	if ( $angle ne $empty_string ) {

		$suhrot->{_angle}		= $angle;
		$suhrot->{_note}		= $suhrot->{_note}.' angle='.$suhrot->{_angle};
		$suhrot->{_Step}		= $suhrot->{_Step}.' angle='.$suhrot->{_angle};

	} else { 
		print("suhrot, angle, missing angle,\n");
	 }
 }


=head2 sub inv 


=cut

 sub inv {

	my ( $self,$inv )		= @_;
	if ( $inv ne $empty_string ) {

		$suhrot->{_inv}		= $inv;
		$suhrot->{_note}		= $suhrot->{_note}.' inv='.$suhrot->{_inv};
		$suhrot->{_Step}		= $suhrot->{_Step}.' inv='.$suhrot->{_inv};

	} else { 
		print("suhrot, inv, missing inv,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$suhrot->{_key}		= $key;
		$suhrot->{_note}		= $suhrot->{_note}.' key='.$suhrot->{_key};
		$suhrot->{_Step}		= $suhrot->{_Step}.' key='.$suhrot->{_key};

	} else { 
		print("suhrot, key, missing key,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$suhrot->{_n}		= $n;
		$suhrot->{_note}		= $suhrot->{_note}.' n='.$suhrot->{_n};
		$suhrot->{_Step}		= $suhrot->{_Step}.' n='.$suhrot->{_n};

	} else { 
		print("suhrot, n, missing n,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suhrot->{_verbose}		= $verbose;
		$suhrot->{_note}		= $suhrot->{_note}.' verbose='.$suhrot->{_verbose};
		$suhrot->{_Step}		= $suhrot->{_Step}.' verbose='.$suhrot->{_verbose};

	} else { 
		print("suhrot, verbose, missing verbose,\n");
	 }
 }


=head2 sub x 


=cut

 sub x {

	my ( $self,$x )		= @_;
	if ( $x ne $empty_string ) {

		$suhrot->{_x}		= $x;
		$suhrot->{_note}		= $suhrot->{_note}.' x='.$suhrot->{_x};
		$suhrot->{_Step}		= $suhrot->{_Step}.' x='.$suhrot->{_x};

	} else { 
		print("suhrot, x, missing x,\n");
	 }
 }


=head2 sub xfile 


=cut

 sub xfile {

	my ( $self,$xfile )		= @_;
	if ( $xfile ne $empty_string ) {

		$suhrot->{_xfile}		= $xfile;
		$suhrot->{_note}		= $suhrot->{_note}.' xfile='.$suhrot->{_xfile};
		$suhrot->{_Step}		= $suhrot->{_Step}.' xfile='.$suhrot->{_xfile};

	} else { 
		print("suhrot, xfile, missing xfile,\n");
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
