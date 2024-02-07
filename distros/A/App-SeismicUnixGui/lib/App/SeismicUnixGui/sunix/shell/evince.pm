package App::SeismicUnixGui::sunix::shell::evince;

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
Usage:

  evince [OPTION…] [FILE…] GNOME Document Viewer



Help Options:

  -h, --help                  Show help options

  --help-all                  Show all help options

  --help-gtk                  Show GTK+ Options



Application Options:

  -p, --page-label=PAGE       The page label of the document to display.

  -i, --page-index=NUMBER     The page number of the document to display.

  -n, --named-dest=DEST       Named destination to display.

  -f, --fullscreen            Run evince in fullscreen mode

  -s, --presentation          Run evince in presentation mode

  -w, --preview               Run evince as a previewer

  -l, --find=STRING           The word or phrase to find in the document

  --display=DISPLAY           X display to use



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

my $evince			= {
	_help					=> '',
	_page					=> '',
	_named					=> '',
	_fullscreen					=> '',
	_presentation					=> '',
	_preview					=> '',
	_find					=> '',
	_display					=> '',
	_Step					=> '',
	_note					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$evince->{_Step}     = 'evince '.$evince->{_Step};
	return ( $evince->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$evince->{_note}     = 'evince'.$evince->{_note};
	return ( $evince->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$evince->{_help}			= '';
		$evince->{_page}			= '';
		$evince->{_named}			= '';
		$evince->{_fullscreen}			= '';
		$evince->{_presentation}			= '';
		$evince->{_preview}			= '';
		$evince->{_find}			= '';
		$evince->{_display}			= '';
		$evince->{_Step}			= '';
		$evince->{_note}			= '';
		$evince->{_Step}			= '';
		$evince->{_note}			= '';
 }


=head2 sub help 


=cut

 sub help {

	my ( $self,$help )		= @_;
	if ( $help ne $empty_string ) {

		$evince->{_help}		= $help;
		$evince->{_note}		= $evince->{_note}.' help='.$evince->{_help};
		$evince->{_Step}		= $evince->{_Step}.' help='.$evince->{_help};

	} else { 
		print("evince, help, missing help,\n");
	 }
 }


=head2 sub page 


=cut

 sub page {

	my ( $self,$page )		= @_;
	if ( $page ne $empty_string ) {

		$evince->{_page}		= $page;
		$evince->{_note}		= $evince->{_note}.' page='.$evince->{_page};
		$evince->{_Step}		= $evince->{_Step}.' page='.$evince->{_page};

	} else { 
		print("evince, page, missing page,\n");
	 }
 }


=head2 sub named 


=cut

 sub named {

	my ( $self,$named )		= @_;
	if ( $named ne $empty_string ) {

		$evince->{_named}		= $named;
		$evince->{_note}		= $evince->{_note}.' named='.$evince->{_named};
		$evince->{_Step}		= $evince->{_Step}.' named='.$evince->{_named};

	} else { 
		print("evince, named, missing named,\n");
	 }
 }


=head2 sub fullscreen 


=cut

 sub fullscreen {

	my ( $self,$fullscreen )		= @_;
	if ( $fullscreen ne $empty_string ) {

		$evince->{_fullscreen}		= $fullscreen;
		$evince->{_note}		= $evince->{_note}.' fullscreen='.$evince->{_fullscreen};
		$evince->{_Step}		= $evince->{_Step}.' fullscreen='.$evince->{_fullscreen};

	} else { 
		print("evince, fullscreen, missing fullscreen,\n");
	 }
 }


=head2 sub presentation 


=cut

 sub presentation {

	my ( $self,$presentation )		= @_;
	if ( $presentation ne $empty_string ) {

		$evince->{_presentation}		= $presentation;
		$evince->{_note}		= $evince->{_note}.' presentation='.$evince->{_presentation};
		$evince->{_Step}		= $evince->{_Step}.' presentation='.$evince->{_presentation};

	} else { 
		print("evince, presentation, missing presentation,\n");
	 }
 }


=head2 sub preview 


=cut

 sub preview {

	my ( $self,$preview )		= @_;
	if ( $preview ne $empty_string ) {

		$evince->{_preview}		= $preview;
		$evince->{_note}		= $evince->{_note}.' preview='.$evince->{_preview};
		$evince->{_Step}		= $evince->{_Step}.' preview='.$evince->{_preview};

	} else { 
		print("evince, preview, missing preview,\n");
	 }
 }


=head2 sub find 


=cut

 sub find {

	my ( $self,$find )		= @_;
	if ( $find ne $empty_string ) {

		$evince->{_find}		= $find;
		$evince->{_note}		= $evince->{_note}.' find='.$evince->{_find};
		$evince->{_Step}		= $evince->{_Step}.' find='.$evince->{_find};

	} else { 
		print("evince, find, missing find,\n");
	 }
 }


=head2 sub display 


=cut

 sub display {

	my ( $self,$display )		= @_;
	if ( $display ne $empty_string ) {

		$evince->{_display}		= $display;
		$evince->{_note}		= $evince->{_note}.' display='.$evince->{_display};
		$evince->{_Step}		= $evince->{_Step}.' display='.$evince->{_display};

	} else { 
		print("evince, display, missing display,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 7;

    return($max_index);
}
 
 
1; 
