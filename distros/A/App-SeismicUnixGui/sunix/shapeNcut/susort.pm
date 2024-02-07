package App::SeismicUnixGui::sunix::shapeNcut::susort;

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
 SUSORT - sort on any segy header keywords	

 		



 susort <stdin >stdout [[+-]key1 [+-]key2 ...]			



 Susort supports any number of (secondary) keys with either	

 ascending (+, the default) or descending (-) directions for 	

 each.  The default sort key is cdp.				



 Note:	Only the following types of input/output are supported	

	Disk input --> any output				

	Pipe input --> Disk output				



 Caveat:  On some Linux systems Pipe input and or output often 

		fails						

	Disk input ---> Disk output is recommended		



 Note: If the the CWP_TMPDIR environment variable is set use	

	its value for the path; else use tmpfile()		



 Example:							

 To sort traces by cdp gather and within each gather		

 by offset with both sorts in ascending order:	

 

 key1 = cdp

 key2 = offset		



 	susort <INDATA >OUTDATA cdp offset			



 Caveat: In the case of Pipe input a temporary file is made	

	to hold the ENTIRE data set.  This temporary is		

	either an actual disk file (usually in /tmp) or in some	

	implementations, a memory buffer.  It is left to the	

	user to be SENSIBLE about how big a file to pipe into	

	susort relative to the user's computer.			





 Credits:

	SEP: Einar Kjartansson , Stew Levin

	CWP: Shuki Ronen,  Jack K. Cohen



 Caveats:

	Since the algorithm depends on sign reversal of the key value

	to obtain a descending sort, the most significant figure may

	be lost for unsigned data types.  The old SEP support for tape

	input was removed in version 1.16---version 1.15 is in the

	Portability directory for those who may want to input SU data

	stored on tape.



 Trace header fields modified: tracl, tracr



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
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';


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

my $susort			= {
	_header_word            => '',   
	_key1					=> '',
	_key2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susort->{_Step}     = 'susort'.$susort->{_Step};
	return ( $susort->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susort->{_note}     = 'susort'.$susort->{_note};
	return ( $susort->{_note} );

 }


=head2 sub clear

=cut

 sub clear {
		$susort->{_header_word}	    = '';
		$susort->{_key1}			= '';
		$susort->{_key2}			= '';
		$susort->{_Step}			= '';
		$susort->{_note}			= '';
 }


=head2 sub header_word 


=cut

sub header_word {

    my ( $self, $old_header_word ) = @_;

    if ( $old_header_word ne $empty_string ) {

        my ( $new_header_word, $header_no_commas );
        
        my $control = control->new();

        $control->set_commas2space($old_header_word);
        $header_no_commas = $control->get_commas2space();

        $control->set_back_slashBgone($header_no_commas);
        $new_header_word = $control->get_back_slashBgone($header_no_commas);

        # print("susort, new_header_words, $new_header_word  \n");

        $susort->{_header_word} = $new_header_word;

        $susort->{_note} = $susort->{_note} . ' ' . $susort->{_header_word};
        $susort->{_Step} = $susort->{_Step} . ' ' . $susort->{_header_word};

    }
    else {
        print("susort, header_words, missing header_word,\n");
    }
}

=head2 sub headerword 

 legacy Nov 2 2018
    selects which headerword on which to sort in the order provided
  multiple calls to this subroutine
  will work

=cut

sub headerword {

    my ( $self, $header_word ) = @_;
    if ($header_word) {

        $susort->{_header_word} = $header_word;
        $susort->{_note} = $susort->{_note} . ' ' . $susort->{_header_word};
        $susort->{_Step} = $susort->{_Step} . ' ' . $susort->{_header_word};

    }
    else {
        print("susort, headerword, missing headerword,\n");
    }
}



=head2 sub key1 


=cut

 sub key1 {

	my ( $self,$key1 )		= @_;
	if ( $key1 ne $empty_string ) {

		$susort->{_key1}		= $key1;
		$susort->{_note}		= $susort->{_note}.' key1='.$susort->{_key1};
		$susort->{_Step}		= $susort->{_Step}.' key1='.$susort->{_key1};

	} else { 
		print("susort, key1, missing key1,\n");
	 }
 }


=head2 sub key2 


=cut

 sub key2 {

	my ( $self,$key2 )		= @_;
	if ( $key2 ne $empty_string ) {

		$susort->{_key2}		= $key2;
		$susort->{_note}		= $susort->{_note}.' key2='.$susort->{_key2};
		$susort->{_Step}		= $susort->{_Step}.' key2='.$susort->{_key2};

	} else { 
		print("susort, key2, missing key2,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 0;

    return($max_index);
}
 
 
1;
