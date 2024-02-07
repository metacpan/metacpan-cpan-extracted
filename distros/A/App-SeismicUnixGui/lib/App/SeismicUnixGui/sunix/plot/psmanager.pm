package App::SeismicUnixGui::sunix::plot::psmanager;

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
 PSMANAGER - printer MANAGER for HP 4MV and HP 5Si Mx Laserjet 

                PostScript printing				



   psmanager < stdin  [optional parameters] > stdout 		



 Required Parameters:						

  none 							

 Optional Parameters:						

 papersize=0	paper size  (US Letter default)			

 		=1       US Legal				

 		=2	 A4					

 		=3     	 11x17					



 orient=0	paper orientation (Portrait default)		

  		=1   	Landscape				



 tray=3        printing tray (Bottom tray default)		

  		=1	tray 1 (multipurpose slot)		

  		=2	tray 2 					



 manual=0	no manual feed 					

  		=1     (Manual Feed)				



 media=0	regular paper					

  		=1     Transparency				

  		=2     Letterhead				

  		=3     Card Stock				

  		=4     Bond					

  		=5     Labels					

  		=6     Prepunched				

  		=7     Recyled					

  		=8     Preprinted				

  		=9     Color (printing on colored paper)	



 Notes: 							

 The option manual=1 implies tray=1. The media options apply	

 only to the HP LaserJet 5Si MX model printer.			



 Examples: 							

   overheads:							

    psmanager <  postscript_file manual=1 media=1 | lpr	

   labels:							

    psmanager <  postscript_file manual=1 media=5 | lpr	







 Notes:  This code was reverse engineered using output from

         the NeXTStep  printer manager.

 

 Author:  John Stockwell, June 1995, October 1997

 

 Reference:   

		PostScript Printer Description File Format Specification,

		version 4.2, Adobe Systems Incorporated



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

my $psmanager			= {
	_manual					=> '',
	_media					=> '',
	_orient					=> '',
	_papersize					=> '',
	_tray					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$psmanager->{_Step}     = 'psmanager'.$psmanager->{_Step};
	return ( $psmanager->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$psmanager->{_note}     = 'psmanager'.$psmanager->{_note};
	return ( $psmanager->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$psmanager->{_manual}			= '';
		$psmanager->{_media}			= '';
		$psmanager->{_orient}			= '';
		$psmanager->{_papersize}			= '';
		$psmanager->{_tray}			= '';
		$psmanager->{_Step}			= '';
		$psmanager->{_note}			= '';
 }


=head2 sub manual 


=cut

 sub manual {

	my ( $self,$manual )		= @_;
	if ( $manual ne $empty_string ) {

		$psmanager->{_manual}		= $manual;
		$psmanager->{_note}		= $psmanager->{_note}.' manual='.$psmanager->{_manual};
		$psmanager->{_Step}		= $psmanager->{_Step}.' manual='.$psmanager->{_manual};

	} else { 
		print("psmanager, manual, missing manual,\n");
	 }
 }


=head2 sub media 


=cut

 sub media {

	my ( $self,$media )		= @_;
	if ( $media ne $empty_string ) {

		$psmanager->{_media}		= $media;
		$psmanager->{_note}		= $psmanager->{_note}.' media='.$psmanager->{_media};
		$psmanager->{_Step}		= $psmanager->{_Step}.' media='.$psmanager->{_media};

	} else { 
		print("psmanager, media, missing media,\n");
	 }
 }


=head2 sub orient 


=cut

 sub orient {

	my ( $self,$orient )		= @_;
	if ( $orient ne $empty_string ) {

		$psmanager->{_orient}		= $orient;
		$psmanager->{_note}		= $psmanager->{_note}.' orient='.$psmanager->{_orient};
		$psmanager->{_Step}		= $psmanager->{_Step}.' orient='.$psmanager->{_orient};

	} else { 
		print("psmanager, orient, missing orient,\n");
	 }
 }


=head2 sub papersize 


=cut

 sub papersize {

	my ( $self,$papersize )		= @_;
	if ( $papersize ne $empty_string ) {

		$psmanager->{_papersize}		= $papersize;
		$psmanager->{_note}		= $psmanager->{_note}.' papersize='.$psmanager->{_papersize};
		$psmanager->{_Step}		= $psmanager->{_Step}.' papersize='.$psmanager->{_papersize};

	} else { 
		print("psmanager, papersize, missing papersize,\n");
	 }
 }


=head2 sub tray 


=cut

 sub tray {

	my ( $self,$tray )		= @_;
	if ( $tray ne $empty_string ) {

		$psmanager->{_tray}		= $tray;
		$psmanager->{_note}		= $psmanager->{_note}.' tray='.$psmanager->{_tray};
		$psmanager->{_Step}		= $psmanager->{_Step}.' tray='.$psmanager->{_tray};

	} else { 
		print("psmanager, tray, missing tray,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 4;

    return($max_index);
}
 
 
1;
