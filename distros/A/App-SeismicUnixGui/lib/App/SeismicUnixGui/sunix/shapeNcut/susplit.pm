package App::SeismicUnixGui::sunix::shapeNcut::susplit;

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
 SUSPLIT - Split traces into different output files by keyword value	

     susplit <stdin >stdout [options]					

 Required Parameters:							

	none								

 Optional Parameters:							

	key=cdp		Key header word to split on (see segy.h)	

	stem=split_	Stem name for output files			

	middle=key	middle of name of output files			

	suffix=.su	Suffix for output files				

	numlength=7	Length of numeric part of filename		

	verbose=0	=1 to echo filenames, etc.			

	close=1		=1 to close files before opening new ones	


 Notes:								

 The most efficient way to use this program is to presort the input data

 into common keyword gathers, prior to using susplit.			"


 Use "suputgthr" to put SU data into SU data directory format.	


 Credits:

	Geocon: Garry Perratt hacked together from various other codes

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 Import packages

=cut

use App::SeismicUnixGui::misc::L_SU_global_constants;
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to 
$suffix_ascii $off $suffix_su $suffix_bin);
use App::SeismicUnixGui::configs::big_streams::Project_config;

=head2 instantiation of packages

=cut

my $get              = App::SeismicUnixGui::misc::L_SU_global_constants->new();
my $Project          = App::SeismicUnixGui::configs::big_streams::Project_config->new();

my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $susplit = {
	_close     => '',
	_key       => '',
	_middle    => '',
	_numlength => '',
	_stem      => '',
	_suffix    => '',
	_verbose   => '',
	_Step      => '',
	_note      => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$susplit->{_Step} = 'susplit' . $susplit->{_Step};
	return ( $susplit->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$susplit->{_note} = 'susplit' . $susplit->{_note};
	return ( $susplit->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$susplit->{_close}     = '';
	$susplit->{_key}       = '';
	$susplit->{_middle}    = '';
	$susplit->{_numlength} = '';
	$susplit->{_stem}      = '';
	$susplit->{_suffix}    = '';
	$susplit->{_verbose}   = '';
	$susplit->{_Step}      = '';
	$susplit->{_note}      = '';
}

=head2 sub close 


=cut

sub close {

	my ( $self, $close ) = @_;
	if ( $close ne $empty_string ) {

		$susplit->{_close} = $close;
		$susplit->{_note}  = $susplit->{_note} . ' close=' . $susplit->{_close};
		$susplit->{_Step}  = $susplit->{_Step} . ' close=' . $susplit->{_close};

	} else {
		print("susplit, close, missing close,\n");
	}
}

=head2 sub key 


=cut

sub key {

	my ( $self, $key ) = @_;
	if ( $key ne $empty_string ) {

		$susplit->{_key}  = $key;
		$susplit->{_note} = $susplit->{_note} . ' key=' . $susplit->{_key};
		$susplit->{_Step} = $susplit->{_Step} . ' key=' . $susplit->{_key};

	} else {
		print("susplit, key, missing key,\n");
	}
}

=head2 sub middle 


=cut

sub middle {

	my ( $self, $middle ) = @_;
	if ( $middle ne $empty_string ) {

		$susplit->{_middle} = $middle;
		$susplit->{_note}   = $susplit->{_note} . ' middle=' . $susplit->{_middle};
		$susplit->{_Step}   = $susplit->{_Step} . ' middle=' . $susplit->{_middle};

	} else {
		print("susplit, middle, missing middle,\n");
	}
}

=head2 sub numlength 


=cut

sub numlength {

	my ( $self, $numlength ) = @_;
	if ( $numlength ne $empty_string ) {

		$susplit->{_numlength} = $numlength;
		$susplit->{_note}      = $susplit->{_note} . ' numlength=' . $susplit->{_numlength};
		$susplit->{_Step}      = $susplit->{_Step} . ' numlength=' . $susplit->{_numlength};

	} else {
		print("susplit, numlength, missing numlength,\n");
	}
}

=head2 sub stem 


=cut

sub stem {

	my ( $self, $stem ) = @_;
	if ( $stem ne $empty_string ) {

		$susplit->{_stem} = $stem;
		$susplit->{_note} = $susplit->{_note} . ' stem=' . $susplit->{_stem};
		$susplit->{_Step} = $susplit->{_Step} . ' stem=' . $susplit->{_stem};

	} else {
		print("susplit, stem, missing stem,\n");
	}
}

=head2 sub suffix 


=cut

sub suffix {

	my ( $self, $suffix ) = @_;
	if ( $suffix ne $empty_string ) {

		$susplit->{_suffix} = $suffix;
		$susplit->{_note}   = $susplit->{_note} . ' suffix=' . $susplit->{_suffix};
		$susplit->{_Step}   = $susplit->{_Step} . ' suffix=' . $susplit->{_suffix};

	} else {
		print("susplit, suffix, missing suffix,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$susplit->{_verbose} = $verbose;
		$susplit->{_note}    = $susplit->{_note} . ' verbose=' . $susplit->{_verbose};
		$susplit->{_Step}    = $susplit->{_Step} . ' verbose=' . $susplit->{_verbose};

	} else {
		print("susplit, verbose, missing verbose,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 3;

	return ($max_index);
}

1;
