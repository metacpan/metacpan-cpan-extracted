package App::SeismicUnixGui::sunix::plot::pslabel;

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
 PSLABEL - output PostScript file consisting of a single TEXT string	

          on a specified background. (Use with psmerge to label plots.)



 pslabel t= [t=] [optional parameters] > epsfile			



Required Parameters (can have multiple specifications to mix fonts):	

  t=                 text string to write to output			



Optional Parameters:							

  f=Times-Bold       font for text string				

                      (multiple specifications for each t)		

  size=30            size of characters in points (72 points/inch)	

  tcolor=black       color of text string				

  bcolor=white       color of background box				

  nsub=0             number of characters to subtract when		

                     computing size of background box (not all		

                     characters are the same size so the		

                     background box may be too big at times.)		



 Example:								

 pslabel t="(a) " f=Times-Bold t="h" f=Symbol t="=0.04" nsub=3 > epsfile



 This example yields the PostScript equivalent of the string		

  (written here in LaTeX notation) $ (a)\\; \\eta=0.04 $		



 Notes:								

 This program produces a (color if desired) PostScript text string that

 can be positioned and pasted on a PostScript plot using   psmerge 	

     see selfdoc of   psmerge for further information.			



 Possible fonts:   Helvetica, Helvetica-Oblique, Helvetica-Bold,	

  Helvetica-BoldOblique,Times-Roman,Times-Italic,Times-Bold,		

  Times-BoldItalic,Courier,Courier-Bold,Courier-Oblique,		

  Courier-BoldOblique,Symbol						



 Possible colors:  greenyellow,yellow,goldenrod,dandelion,apricot,	

  peach,melon,yelloworange,orange,burntorange,bittersweet,redorange,	

  mahogany,maroon,brickred,red,orangered,rubinered,wildstrawberry,	

  salmon,carnationpink,magenta,violetred,rhodamine,mulberry,redviolet,	

  fuchsia,lavender,thistle,orchid,darkorchid,purple,plum,violet,royalpurple,

  blueviolet,periwinkle,cadetblue,cornflowerblue,midnightblue,naveblue,

  royalblue,blue,cerulean,cyan,processblue,skyblue,turquoise,tealblue,	

  aquamarine,bluegreen,emerald,junglegreen,seagreen,green,forestgreen,	

  pinegreen,limegreen,yellowgreen,springgreen,olivegreen,rawsienna,sepia,

  brown,tan,white,black,gray						



 All color specifications may also be made in X Window style Hex format

 example:   tcolor=#255						



 Legal font names are:							

 AvantGarde-Book AvantGarde-BookOblique AvantGarde-Demi AvantGarde-DemiOblique"

 Bookman-Demi Bookman-DemiItalic Bookman-Light Bookman-LightItalic 

 Courier Courier-Bold Courier-BoldOblique Courier-Oblique 

 Helvetica Helvetica-Bold Helvetica-BoldOblique Helvetica-Oblique 

 Helvetica-Narrow Helvetica-Narrow-Bold Helvetica-Narrow-BoldOblique 

 Helvetica-Narrow-Oblique NewCentrySchlbk-Bold"

 NewCenturySchlbk-BoldItalic NewCenturySchlbk-Roman Palatino-Bold  

 Palatino-BoldItalic Palatino-Italics Palatino-Roman 

 SanSerif-Bold SanSerif-BoldItalic SanSerif-Roman 

 Symbol Times-Bold Times-BoldItalic 

 Times-Roman Times-Italic ZapfChancery-MediumItalic 









 Author:  John E. Anderson, Visiting Scientist from Mobil, 1994



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

my $pslabel			= {
	_bcolor					=> '',
	_eta					=> '',
	_f					=> '',
	_nsub					=> '',
	_size					=> '',
	_t					=> '',
	_tcolor					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$pslabel->{_Step}     = 'pslabel'.$pslabel->{_Step};
	return ( $pslabel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$pslabel->{_note}     = 'pslabel'.$pslabel->{_note};
	return ( $pslabel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$pslabel->{_bcolor}			= '';
		$pslabel->{_eta}			= '';
		$pslabel->{_f}			= '';
		$pslabel->{_nsub}			= '';
		$pslabel->{_size}			= '';
		$pslabel->{_t}			= '';
		$pslabel->{_tcolor}			= '';
		$pslabel->{_Step}			= '';
		$pslabel->{_note}			= '';
 }


=head2 sub bcolor 


=cut

 sub bcolor {

	my ( $self,$bcolor )		= @_;
	if ( $bcolor ne $empty_string ) {

		$pslabel->{_bcolor}		= $bcolor;
		$pslabel->{_note}		= $pslabel->{_note}.' bcolor='.$pslabel->{_bcolor};
		$pslabel->{_Step}		= $pslabel->{_Step}.' bcolor='.$pslabel->{_bcolor};

	} else { 
		print("pslabel, bcolor, missing bcolor,\n");
	 }
 }


=head2 sub eta 


=cut

 sub eta {

	my ( $self,$eta )		= @_;
	if ( $eta ne $empty_string ) {

		$pslabel->{_eta}		= $eta;
		$pslabel->{_note}		= $pslabel->{_note}.' eta='.$pslabel->{_eta};
		$pslabel->{_Step}		= $pslabel->{_Step}.' eta='.$pslabel->{_eta};

	} else { 
		print("pslabel, eta, missing eta,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$pslabel->{_f}		= $f;
		$pslabel->{_note}		= $pslabel->{_note}.' f='.$pslabel->{_f};
		$pslabel->{_Step}		= $pslabel->{_Step}.' f='.$pslabel->{_f};

	} else { 
		print("pslabel, f, missing f,\n");
	 }
 }


=head2 sub nsub 


=cut

 sub nsub {

	my ( $self,$nsub )		= @_;
	if ( $nsub ne $empty_string ) {

		$pslabel->{_nsub}		= $nsub;
		$pslabel->{_note}		= $pslabel->{_note}.' nsub='.$pslabel->{_nsub};
		$pslabel->{_Step}		= $pslabel->{_Step}.' nsub='.$pslabel->{_nsub};

	} else { 
		print("pslabel, nsub, missing nsub,\n");
	 }
 }


=head2 sub size 


=cut

 sub size {

	my ( $self,$size )		= @_;
	if ( $size ne $empty_string ) {

		$pslabel->{_size}		= $size;
		$pslabel->{_note}		= $pslabel->{_note}.' size='.$pslabel->{_size};
		$pslabel->{_Step}		= $pslabel->{_Step}.' size='.$pslabel->{_size};

	} else { 
		print("pslabel, size, missing size,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$pslabel->{_t}		= $t;
		$pslabel->{_note}		= $pslabel->{_note}.' t='.$pslabel->{_t};
		$pslabel->{_Step}		= $pslabel->{_Step}.' t='.$pslabel->{_t};

	} else { 
		print("pslabel, t, missing t,\n");
	 }
 }


=head2 sub tcolor 


=cut

 sub tcolor {

	my ( $self,$tcolor )		= @_;
	if ( $tcolor ne $empty_string ) {

		$pslabel->{_tcolor}		= $tcolor;
		$pslabel->{_note}		= $pslabel->{_note}.' tcolor='.$pslabel->{_tcolor};
		$pslabel->{_Step}		= $pslabel->{_Step}.' tcolor='.$pslabel->{_tcolor};

	} else { 
		print("pslabel, tcolor, missing tcolor,\n");
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
