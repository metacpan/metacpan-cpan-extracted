package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sustack;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PROGRAM NAME: sustack 
 AUTHOR: Juan Lorenzo
 DATE:  July 31, 2013
 DESCRIPTION  horizontal summation across
              a file based on a header word
 Version 0.0.1

=head2 USE

=head3 SUNIX NOTES

SUSTACK - stack adjacent traces having the same key header word

     sustack <stdin >stdout [Optional parameters]		

 Required parameters:						
 	none							

 Optional parameters: 						
 	key=cdp		header key word to stack on		
 	normpow=1.0	each sample is divided by the		
			normpow'th number of non-zero values	
			stacked (normpow=0 selects no division)	
	repeat=0	=1 repeats the stack trace nrepeat times
	nrepeat=10	repeats stack trace nrepeat times in	
	          	output file				
 	verbose=0	verbose = 1 echos information		

 Notes:							
 ------							
 The offset field is set to zero on the output traces, unless	
 the user is stacking with key=offset. In that case, the value 
 of the offset field is left unchanged. 		        

 Sushw can be used afterwards if this is not acceptable.	

 For VSP users:						
 The stack trace appears ten times in the output file when	
 setting repeat=1 and nrepeat=10. Corridor stacking can be	
 achieved by properly muting the upgoing data with SUMUTE	
 before stacking.						


 Credits:
	SEP: Einar Kjartansson
	CWP: Jack K. Cohen, Dave Hale
	CENPET: Werner M. Heigl - added repeat trace functionality

 Note:
	The "valxxx" subroutines are in su/lib/valpkge.c.  In particular,
      "valcmp" shares the annoying attribute of "strcmp" that
		if (valcmp(type, val, valnew) {
			...
		}
	will be performed when val and valnew are different.

 Trace header fields accessed: ns
 Trace header fields modified: nhs, tracl, offset



=head4 Examples

Usage 1:
To stack an array of trace 

Example:
       $sustack ->clear();
       $sustack->headerword('cdp');
       $sustack[1] = $sustack->Step();

=head3 SEISMIC UNIX NOTES

 SUSTACK - stack adjacent traces having the same key header word

     sustack <stdin >stdout [Optional parameters]		

 Required parameters:						
 	none							

 Optional parameters: 						
 	key=cdp		header key word to stack on		
 	normpow=1.0	each sample is divided by the		
			normpow'th number of non-zero values	
			stacked (normpow=0 selects no division)	
	repeat=0	=1 repeats the stack trace nrepeat times
	nrepeat=10	repeats stack trace nrepeat times in	
	          	output file				
 	verbose=0	verbose = 1 echos information		

 Notes:							
 ------							
 The offset field is set to zero on the output traces, unless	
 the user is stacking with key=offset. In that case, the value 
 of the offset field is left unchanged. 		        

 Sushw can be used afterwards if this is not acceptable.	

 For VSP users:						
 The stack trace appears ten times in the output file when	
 setting repeat=1 and nrepeat=10. Corridor stacking can be	
 achieved by properly muting the upgoing data with SUMUTE	
 before stacking.						


 Credits:
	SEP: Einar Kjartansson
	CWP: Jack K. Cohen, Dave Hale
	CENPET: Werner M. Heigl - added repeat trace functionality

 Note:
	The "valxxx" subroutines are in su/lib/valpkge.c.  In particular,
      "valcmp" shares the annoying attribute of "strcmp" that
		if (valcmp(type, val, valnew) {
			...
		}
	will be performed when val and valnew are different.

 Trace header fields accessed: ns
 Trace header fields modified: nhs, tracl, offset

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sustack = {
    _key     => '',
    _normpow => '',
    _nrepeat => '',
    _repeat  => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sustack->{_Step} = 'sustack' . $sustack->{_Step};
    return ( $sustack->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sustack->{_note} = 'sustack' . $sustack->{_note};
    return ( $sustack->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sustack->{_key}     = '';
    $sustack->{_normpow} = '';
    $sustack->{_nrepeat} = '';
    $sustack->{_repeat}  = '';
    $sustack->{_verbose} = '';
    $sustack->{_Step}    = '';
    $sustack->{_note}    = '';
}

=head2 sub headerword 

 key or headerword (legacy)
 
=cut

sub headerword {

    my ( $self, $key ) = @_;
    if ($key) {

        $sustack->{_key}  = $key;
        $sustack->{_note} = $sustack->{_note} . ' key=' . $sustack->{_key};
        $sustack->{_Step} = $sustack->{_Step} . ' key=' . $sustack->{_key};

    }
    else {
        print("sustack, headerword, missing headerword,\n");
    }
}

=head2 sub header_word 

 key or header_word
 
=cut

sub header_word {

    my ( $self, $key ) = @_;
    if ($key) {

        $sustack->{_key}  = $key;
        $sustack->{_note} = $sustack->{_note} . ' key=' . $sustack->{_key};
        $sustack->{_Step} = $sustack->{_Step} . ' key=' . $sustack->{_key};

    }
    else {
        print("sustack, header_word, missing header_word,\n");
    }
}

=head2 sub key

 key or header_word

=cut

sub key {

    my ( $self, $key ) = @_;
    if ($key) {

        $sustack->{_key}  = $key;
        $sustack->{_note} = $sustack->{_note} . ' key=' . $sustack->{_key};
        $sustack->{_Step} = $sustack->{_Step} . ' key=' . $sustack->{_key};

    }
    else {
        print("sustack, key, missing key,\n");
    }
}

=head2 sub normpow 


=cut

sub normpow {

    my ( $self, $normpow ) = @_;
    if ( $normpow ne $empty_string ) {

        $sustack->{_normpow} = $normpow;
        $sustack->{_note} =
          $sustack->{_note} . ' normpow=' . $sustack->{_normpow};
        $sustack->{_Step} =
          $sustack->{_Step} . ' normpow=' . $sustack->{_normpow};

    }
    else {
        print("sustack, normpow, missing normpow,\n");
    }
}

=head2 sub nrepeat 


=cut

sub nrepeat {

    my ( $self, $nrepeat ) = @_;
    if ( $nrepeat ne $empty_string ) {

        $sustack->{_nrepeat} = $nrepeat;
        $sustack->{_note} =
          $sustack->{_note} . ' nrepeat=' . $sustack->{_nrepeat};
        $sustack->{_Step} =
          $sustack->{_Step} . ' nrepeat=' . $sustack->{_nrepeat};

    }
    else {
        print("sustack, nrepeat, missing nrepeat,\n");
    }
}

=head2 sub repeat 


=cut

sub repeat {

    my ( $self, $repeat ) = @_;
    if ( $repeat ne $empty_string ) {

        $sustack->{_repeat} = $repeat;
        $sustack->{_note} =
          $sustack->{_note} . ' repeat=' . $sustack->{_repeat};
        $sustack->{_Step} =
          $sustack->{_Step} . ' repeat=' . $sustack->{_repeat};

    }
    else {
        print("sustack, repeat, missing repeat,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sustack->{_verbose} = $verbose;
        $sustack->{_note} =
          $sustack->{_note} . ' verbose=' . $sustack->{_verbose};
        $sustack->{_Step} =
          $sustack->{_Step} . ' verbose=' . $sustack->{_verbose};

    }
    else {
        print("sustack, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 4;

    return ($max_index);
}

1;
