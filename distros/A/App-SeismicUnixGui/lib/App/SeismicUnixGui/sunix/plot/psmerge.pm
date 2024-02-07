package App::SeismicUnixGui::sunix::plot::psmerge;

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
 PSMERGE - MERGE PostScript files					



 psmerge in= [optional parameters] >postscriptfile			



 Required Parameters:							

 in=                    postscript file to merge			



 Optional Parameters:							

 origin=0.0,0.0         x,y origin in inches				

 scale=1.0,1.0          x,y scale factors				

 rotate=0.0             rotation angle in degrees			

 translate=0.0,0.0      x,y translation in inches			



 Notes:								

 More than one set of in, origin, scale, rotate, and translate		

 parameters may be specified.  Output x and y coordinates are		

 determined by:							

          x = tx + (x-ox)*sx*cos(d) - (y-oy)*sy*sin(d)			

          y = ty + (x-ox)*sx*sin(d) + (y-oy)*sy*cos(d)			

 where tx,ty are translate coordinates, ox,oy are origin coordinates,	

 sx,sy are scale factors, and d is the rotation angle.  Note that the	

 order of operations is shift (origin), scale, rotate, and translate.	



 If the number of occurrences of a given parameter is less than the number

 of input files, then the last occurrence of that parameter will apply to

 all subsequent files.							



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

my $psmerge			= {
	_in					=> '',
	_origin					=> '',
	_rotate					=> '',
	_scale					=> '',
	_translate					=> '',
	_x					=> '',
	_y					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$psmerge->{_Step}     = 'psmerge'.$psmerge->{_Step};
	return ( $psmerge->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$psmerge->{_note}     = 'psmerge'.$psmerge->{_note};
	return ( $psmerge->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$psmerge->{_in}			= '';
		$psmerge->{_origin}			= '';
		$psmerge->{_rotate}			= '';
		$psmerge->{_scale}			= '';
		$psmerge->{_translate}			= '';
		$psmerge->{_x}			= '';
		$psmerge->{_y}			= '';
		$psmerge->{_Step}			= '';
		$psmerge->{_note}			= '';
 }


=head2 sub in 


=cut

 sub in {

	my ( $self,$in )		= @_;
	if ( $in ne $empty_string ) {

		$psmerge->{_in}		= $in;
		$psmerge->{_note}		= $psmerge->{_note}.' in='.$psmerge->{_in};
		$psmerge->{_Step}		= $psmerge->{_Step}.' in='.$psmerge->{_in};

	} else { 
		print("psmerge, in, missing in,\n");
	 }
 }


=head2 sub origin 


=cut

 sub origin {

	my ( $self,$origin )		= @_;
	if ( $origin ne $empty_string ) {

		$psmerge->{_origin}		= $origin;
		$psmerge->{_note}		= $psmerge->{_note}.' origin='.$psmerge->{_origin};
		$psmerge->{_Step}		= $psmerge->{_Step}.' origin='.$psmerge->{_origin};

	} else { 
		print("psmerge, origin, missing origin,\n");
	 }
 }


=head2 sub rotate 


=cut

 sub rotate {

	my ( $self,$rotate )		= @_;
	if ( $rotate ne $empty_string ) {

		$psmerge->{_rotate}		= $rotate;
		$psmerge->{_note}		= $psmerge->{_note}.' rotate='.$psmerge->{_rotate};
		$psmerge->{_Step}		= $psmerge->{_Step}.' rotate='.$psmerge->{_rotate};

	} else { 
		print("psmerge, rotate, missing rotate,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$psmerge->{_scale}		= $scale;
		$psmerge->{_note}		= $psmerge->{_note}.' scale='.$psmerge->{_scale};
		$psmerge->{_Step}		= $psmerge->{_Step}.' scale='.$psmerge->{_scale};

	} else { 
		print("psmerge, scale, missing scale,\n");
	 }
 }


=head2 sub translate 


=cut

 sub translate {

	my ( $self,$translate )		= @_;
	if ( $translate ne $empty_string ) {

		$psmerge->{_translate}		= $translate;
		$psmerge->{_note}		= $psmerge->{_note}.' translate='.$psmerge->{_translate};
		$psmerge->{_Step}		= $psmerge->{_Step}.' translate='.$psmerge->{_translate};

	} else { 
		print("psmerge, translate, missing translate,\n");
	 }
 }


=head2 sub x 


=cut

 sub x {

	my ( $self,$x )		= @_;
	if ( $x ne $empty_string ) {

		$psmerge->{_x}		= $x;
		$psmerge->{_note}		= $psmerge->{_note}.' x='.$psmerge->{_x};
		$psmerge->{_Step}		= $psmerge->{_Step}.' x='.$psmerge->{_x};

	} else { 
		print("psmerge, x, missing x,\n");
	 }
 }


=head2 sub y 


=cut

 sub y {

	my ( $self,$y )		= @_;
	if ( $y ne $empty_string ) {

		$psmerge->{_y}		= $y;
		$psmerge->{_note}		= $psmerge->{_note}.' y='.$psmerge->{_y};
		$psmerge->{_Step}		= $psmerge->{_Step}.' y='.$psmerge->{_y};

	} else { 
		print("psmerge, y, missing y,\n");
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
