package App::SeismicUnixGui::sunix::header::sulcthw;

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
 SULCTHW - Linear Coordinate Transformation of Header Words		



   sulcthw <infile >outfile						



 xt=0.0	Translation of X					

 yt=0.0	Translation of Y					

 zt=0.0	Translation of Z					

 xr=0.0	Rotation around X in degrees	 			

 yr=0.0	Rotation aroun Y  in degrees	 			

 zr=0.0	Rotation around Z in degrees 				



 Notes:								

 Translation:								

 x = x'+ xt;y = y'+ yt;z = z' + zt;					



 Rotations:					  			

 Around Z axis								

 X = x*cos(zr)+y*sin(zr);			  			

 Y = y*cos(zr)-x*sin(zr);			  			

 Around Y axis								

 Z = z*cos(yr)+x*sin(yr);			  			

 X = x*cos(yr)-z*sin(yr);			  			

 Around X axis								

 Y = y*cos(xr)+z*sin(xr);			  			

 Z = Z*cos(xr)-y*sin(xr);			  			



 Header words triplets that are transformed				

 sx,sy,selev								

 gx,gy,gelev								



 The header words restored as 32 bit integers using SEG-Y		

 convention (with coordinate scalers scalco and scalel).		



 After transformation they are converted back to integers and stored.	







  Credits: Potash Corporation of Saskatchewan: Balasz Nemeth   c. 2008







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

my $sulcthw			= {
	_X					=> '',
	_Y					=> '',
	_Z					=> '',
	_x					=> '',
	_xr					=> '',
	_xt					=> '',
	_yr					=> '',
	_yt					=> '',
	_zr					=> '',
	_zt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sulcthw->{_Step}     = 'sulcthw'.$sulcthw->{_Step};
	return ( $sulcthw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sulcthw->{_note}     = 'sulcthw'.$sulcthw->{_note};
	return ( $sulcthw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sulcthw->{_X}			= '';
		$sulcthw->{_Y}			= '';
		$sulcthw->{_Z}			= '';
		$sulcthw->{_x}			= '';
		$sulcthw->{_xr}			= '';
		$sulcthw->{_xt}			= '';
		$sulcthw->{_yr}			= '';
		$sulcthw->{_yt}			= '';
		$sulcthw->{_zr}			= '';
		$sulcthw->{_zt}			= '';
		$sulcthw->{_Step}			= '';
		$sulcthw->{_note}			= '';
 }


=head2 sub X 


=cut

 sub X {

	my ( $self,$X )		= @_;
	if ( $X ne $empty_string ) {

		$sulcthw->{_X}		= $X;
		$sulcthw->{_note}		= $sulcthw->{_note}.' X='.$sulcthw->{_X};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' X='.$sulcthw->{_X};

	} else { 
		print("sulcthw, X, missing X,\n");
	 }
 }


=head2 sub Y 


=cut

 sub Y {

	my ( $self,$Y )		= @_;
	if ( $Y ne $empty_string ) {

		$sulcthw->{_Y}		= $Y;
		$sulcthw->{_note}		= $sulcthw->{_note}.' Y='.$sulcthw->{_Y};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' Y='.$sulcthw->{_Y};

	} else { 
		print("sulcthw, Y, missing Y,\n");
	 }
 }


=head2 sub Z 


=cut

 sub Z {

	my ( $self,$Z )		= @_;
	if ( $Z ne $empty_string ) {

		$sulcthw->{_Z}		= $Z;
		$sulcthw->{_note}		= $sulcthw->{_note}.' Z='.$sulcthw->{_Z};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' Z='.$sulcthw->{_Z};

	} else { 
		print("sulcthw, Z, missing Z,\n");
	 }
 }


=head2 sub x 


=cut

 sub x {

	my ( $self,$x )		= @_;
	if ( $x ne $empty_string ) {

		$sulcthw->{_x}		= $x;
		$sulcthw->{_note}		= $sulcthw->{_note}.' x='.$sulcthw->{_x};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' x='.$sulcthw->{_x};

	} else { 
		print("sulcthw, x, missing x,\n");
	 }
 }


=head2 sub xr 


=cut

 sub xr {

	my ( $self,$xr )		= @_;
	if ( $xr ne $empty_string ) {

		$sulcthw->{_xr}		= $xr;
		$sulcthw->{_note}		= $sulcthw->{_note}.' xr='.$sulcthw->{_xr};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' xr='.$sulcthw->{_xr};

	} else { 
		print("sulcthw, xr, missing xr,\n");
	 }
 }


=head2 sub xt 


=cut

 sub xt {

	my ( $self,$xt )		= @_;
	if ( $xt ne $empty_string ) {

		$sulcthw->{_xt}		= $xt;
		$sulcthw->{_note}		= $sulcthw->{_note}.' xt='.$sulcthw->{_xt};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' xt='.$sulcthw->{_xt};

	} else { 
		print("sulcthw, xt, missing xt,\n");
	 }
 }


=head2 sub yr 


=cut

 sub yr {

	my ( $self,$yr )		= @_;
	if ( $yr ne $empty_string ) {

		$sulcthw->{_yr}		= $yr;
		$sulcthw->{_note}		= $sulcthw->{_note}.' yr='.$sulcthw->{_yr};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' yr='.$sulcthw->{_yr};

	} else { 
		print("sulcthw, yr, missing yr,\n");
	 }
 }


=head2 sub yt 


=cut

 sub yt {

	my ( $self,$yt )		= @_;
	if ( $yt ne $empty_string ) {

		$sulcthw->{_yt}		= $yt;
		$sulcthw->{_note}		= $sulcthw->{_note}.' yt='.$sulcthw->{_yt};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' yt='.$sulcthw->{_yt};

	} else { 
		print("sulcthw, yt, missing yt,\n");
	 }
 }


=head2 sub zr 


=cut

 sub zr {

	my ( $self,$zr )		= @_;
	if ( $zr ne $empty_string ) {

		$sulcthw->{_zr}		= $zr;
		$sulcthw->{_note}		= $sulcthw->{_note}.' zr='.$sulcthw->{_zr};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' zr='.$sulcthw->{_zr};

	} else { 
		print("sulcthw, zr, missing zr,\n");
	 }
 }


=head2 sub zt 


=cut

 sub zt {

	my ( $self,$zt )		= @_;
	if ( $zt ne $empty_string ) {

		$sulcthw->{_zt}		= $zt;
		$sulcthw->{_note}		= $sulcthw->{_note}.' zt='.$sulcthw->{_zt};
		$sulcthw->{_Step}		= $sulcthw->{_Step}.' zt='.$sulcthw->{_zt};

	} else { 
		print("sulcthw, zt, missing zt,\n");
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
