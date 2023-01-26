package App::SeismicUnixGui::sunix::statsMath::cpftrend;

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
char* sdoc[] = {



   CPFTREND - generate picks of the Cumulate Probability Function 	



 Required parameters:							

  ix=      - column containing X variable				

  iy=      - column containing Y variable				

  min_x=   - minimum X bin						

  max_x=   - maximum X bin						

  min_y=   - minimum Y bin 						

  max_y=   - maximum Y bin						



 Optional parameters:							

  nx=100    - number of X bins 					

  ny=100    - number of Y bins 					

  logx=0   - =1 use logarithmic scale for X axis			

  logy=0   - =1 use logarithmic scale for Y axis			

  ir=       - column containing reject variable 			

  rmin=     - reject values below rmin 				

  rmax=     - reject values above rmax 				

              NOTE: only one, rmin or rmax, may be used		

 NOTES:								

  cpftrend makes picks on the 2D cumulate representing the		

  probability density function of the input data.			



   Commandline options allow selecting any of several normalizations	

   to apply to the distributions.					





  cpftrend(1) makes picks on the 2D cumulate representing the

  probability density function of the input data.



   Commandline options allow selecting any of several normalizations 

   to apply to the distributions.



 Credits:  Reginald H. Beardsley                      rhb@acm.org

     Copyright 2006 Exploration Software Consultants Inc.

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

my $cpftrend			= {
	_ir					=> '',
	_ix					=> '',
	_iy					=> '',
	_logx					=> '',
	_logy					=> '',
	_max_x					=> '',
	_max_y					=> '',
	_min_x					=> '',
	_min_y					=> '',
	_nx					=> '',
	_ny					=> '',
	_rmax					=> '',
	_rmin					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$cpftrend->{_Step}     = 'cpftrend'.$cpftrend->{_Step};
	return ( $cpftrend->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$cpftrend->{_note}     = 'cpftrend'.$cpftrend->{_note};
	return ( $cpftrend->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$cpftrend->{_ir}			= '';
		$cpftrend->{_ix}			= '';
		$cpftrend->{_iy}			= '';
		$cpftrend->{_logx}			= '';
		$cpftrend->{_logy}			= '';
		$cpftrend->{_max_x}			= '';
		$cpftrend->{_max_y}			= '';
		$cpftrend->{_min_x}			= '';
		$cpftrend->{_min_y}			= '';
		$cpftrend->{_nx}			= '';
		$cpftrend->{_ny}			= '';
		$cpftrend->{_rmax}			= '';
		$cpftrend->{_rmin}			= '';
		$cpftrend->{_Step}			= '';
		$cpftrend->{_note}			= '';
 }


=head2 sub ir 


=cut

 sub ir {

	my ( $self,$ir )		= @_;
	if ( $ir ne $empty_string ) {

		$cpftrend->{_ir}		= $ir;
		$cpftrend->{_note}		= $cpftrend->{_note}.' ir='.$cpftrend->{_ir};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' ir='.$cpftrend->{_ir};

	} else { 
		print("cpftrend, ir, missing ir,\n");
	 }
 }


=head2 sub ix 


=cut

 sub ix {

	my ( $self,$ix )		= @_;
	if ( $ix ne $empty_string ) {

		$cpftrend->{_ix}		= $ix;
		$cpftrend->{_note}		= $cpftrend->{_note}.' ix='.$cpftrend->{_ix};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' ix='.$cpftrend->{_ix};

	} else { 
		print("cpftrend, ix, missing ix,\n");
	 }
 }


=head2 sub iy 


=cut

 sub iy {

	my ( $self,$iy )		= @_;
	if ( $iy ne $empty_string ) {

		$cpftrend->{_iy}		= $iy;
		$cpftrend->{_note}		= $cpftrend->{_note}.' iy='.$cpftrend->{_iy};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' iy='.$cpftrend->{_iy};

	} else { 
		print("cpftrend, iy, missing iy,\n");
	 }
 }


=head2 sub logx 


=cut

 sub logx {

	my ( $self,$logx )		= @_;
	if ( $logx ne $empty_string ) {

		$cpftrend->{_logx}		= $logx;
		$cpftrend->{_note}		= $cpftrend->{_note}.' logx='.$cpftrend->{_logx};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' logx='.$cpftrend->{_logx};

	} else { 
		print("cpftrend, logx, missing logx,\n");
	 }
 }


=head2 sub logy 


=cut

 sub logy {

	my ( $self,$logy )		= @_;
	if ( $logy ne $empty_string ) {

		$cpftrend->{_logy}		= $logy;
		$cpftrend->{_note}		= $cpftrend->{_note}.' logy='.$cpftrend->{_logy};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' logy='.$cpftrend->{_logy};

	} else { 
		print("cpftrend, logy, missing logy,\n");
	 }
 }


=head2 sub max_x 


=cut

 sub max_x {

	my ( $self,$max_x )		= @_;
	if ( $max_x ne $empty_string ) {

		$cpftrend->{_max_x}		= $max_x;
		$cpftrend->{_note}		= $cpftrend->{_note}.' max_x='.$cpftrend->{_max_x};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' max_x='.$cpftrend->{_max_x};

	} else { 
		print("cpftrend, max_x, missing max_x,\n");
	 }
 }


=head2 sub max_y 


=cut

 sub max_y {

	my ( $self,$max_y )		= @_;
	if ( $max_y ne $empty_string ) {

		$cpftrend->{_max_y}		= $max_y;
		$cpftrend->{_note}		= $cpftrend->{_note}.' max_y='.$cpftrend->{_max_y};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' max_y='.$cpftrend->{_max_y};

	} else { 
		print("cpftrend, max_y, missing max_y,\n");
	 }
 }


=head2 sub min_x 


=cut

 sub min_x {

	my ( $self,$min_x )		= @_;
	if ( $min_x ne $empty_string ) {

		$cpftrend->{_min_x}		= $min_x;
		$cpftrend->{_note}		= $cpftrend->{_note}.' min_x='.$cpftrend->{_min_x};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' min_x='.$cpftrend->{_min_x};

	} else { 
		print("cpftrend, min_x, missing min_x,\n");
	 }
 }


=head2 sub min_y 


=cut

 sub min_y {

	my ( $self,$min_y )		= @_;
	if ( $min_y ne $empty_string ) {

		$cpftrend->{_min_y}		= $min_y;
		$cpftrend->{_note}		= $cpftrend->{_note}.' min_y='.$cpftrend->{_min_y};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' min_y='.$cpftrend->{_min_y};

	} else { 
		print("cpftrend, min_y, missing min_y,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$cpftrend->{_nx}		= $nx;
		$cpftrend->{_note}		= $cpftrend->{_note}.' nx='.$cpftrend->{_nx};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' nx='.$cpftrend->{_nx};

	} else { 
		print("cpftrend, nx, missing nx,\n");
	 }
 }


=head2 sub ny 


=cut

 sub ny {

	my ( $self,$ny )		= @_;
	if ( $ny ne $empty_string ) {

		$cpftrend->{_ny}		= $ny;
		$cpftrend->{_note}		= $cpftrend->{_note}.' ny='.$cpftrend->{_ny};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' ny='.$cpftrend->{_ny};

	} else { 
		print("cpftrend, ny, missing ny,\n");
	 }
 }


=head2 sub rmax 


=cut

 sub rmax {

	my ( $self,$rmax )		= @_;
	if ( $rmax ne $empty_string ) {

		$cpftrend->{_rmax}		= $rmax;
		$cpftrend->{_note}		= $cpftrend->{_note}.' rmax='.$cpftrend->{_rmax};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' rmax='.$cpftrend->{_rmax};

	} else { 
		print("cpftrend, rmax, missing rmax,\n");
	 }
 }


=head2 sub rmin 


=cut

 sub rmin {

	my ( $self,$rmin )		= @_;
	if ( $rmin ne $empty_string ) {

		$cpftrend->{_rmin}		= $rmin;
		$cpftrend->{_note}		= $cpftrend->{_note}.' rmin='.$cpftrend->{_rmin};
		$cpftrend->{_Step}		= $cpftrend->{_Step}.' rmin='.$cpftrend->{_rmin};

	} else { 
		print("cpftrend, rmin, missing rmin,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
