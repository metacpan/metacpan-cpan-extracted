package App::SeismicUnixGui::sunix::header::sugethw;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUGETHW - sugethw writes the values of the selected key words		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUGETHW - sugethw writes the values of the selected key words		

   sugethw key=key1,... [output=] <infile [>outfile]			

 Required parameters:							
 key=key1,...		At least one key word.				

 Optional parameters:							
 output=ascii		output written as ascii for display		
 			=binary for output as binary floats		
 			=geom   ascii output for geometry setting	
 verbose=0 		quiet						
 			=1 chatty					

 Output is written in the order of the keys on the command		
 line for each trace in the data set.					

 Example:								
 	sugethw <stdin key=sx,gx					
 writes sx, gx values as ascii trace by trace to the terminal.		

 Comment: 								
 Users wishing to edit one or more header field (as in geometry setting)
 may do this via the following sequence:				
     sugethw < sudata output=geom key=key1,key2,... > hdrfile 		
 Now edit the ASCII file hdrfile with any editor, setting the fields	
 appropriately. Convert hdrfile to a binary format via:		
     a2b < hdrfile n1=nfields > binary_file				
 Then set the header fields via:					
     sushw < sudata infile=binary_file key=key1,key2,... > sudata.edited


 Credits:

	SEP: Shuki Ronen
	CWP: Jack K. Cohen
    CWP: John Stockwell, added geom stuff, and getparstringarray

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $sugethw = {
    _key     => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sugethw->{_Step} = 'sugethw' . $sugethw->{_Step};
    return ( $sugethw->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sugethw->{_note} = 'sugethw' . $sugethw->{_note};
    return ( $sugethw->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sugethw->{_infile}  = '';
    $sugethw->{_key}     = '';
    $sugethw->{_n1}      = '';
    $sugethw->{_output}  = '';
    $sugethw->{_verbose} = '';
    $sugethw->{_Step}    = '';
    $sugethw->{_note}    = '';
}

=head2 sub header_word 


=cut

sub header_word {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $sugethw->{_key}  = $key;
        $sugethw->{_note} = $sugethw->{_note} . ' key=' . $sugethw->{_key};
        $sugethw->{_Step} = $sugethw->{_Step} . ' key=' . $sugethw->{_key};

    }
    else {
        print("sugethw, header_word, missing header_word,\n");
    }
}

=head2 sub infile 


=cut

sub infile {

    my ( $self, $infile ) = @_;
    if ( $infile ne $empty_string ) {

        $sugethw->{_infile} = $infile;
        $sugethw->{_note} =
          $sugethw->{_note} . ' infile=' . $sugethw->{_infile};
        $sugethw->{_Step} =
          $sugethw->{_Step} . ' infile=' . $sugethw->{_infile};

    }
    else {
        print("sugethw, infile, missing infile,\n");
    }
}

=head2 sub key 


=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $sugethw->{_key}  = $key;
        $sugethw->{_note} = $sugethw->{_note} . ' key=' . $sugethw->{_key};
        $sugethw->{_Step} = $sugethw->{_Step} . ' key=' . $sugethw->{_key};

    }
    else {
        print("sugethw, key, missing key,\n");
    }
}

=head2 sub output 


=cut

sub output {

    my ( $self, $output ) = @_;
    if ( $output ne $empty_string ) {

        $sugethw->{_output} = $output;
        $sugethw->{_note} =
          $sugethw->{_note} . ' output=' . $sugethw->{_output};
        $sugethw->{_Step} =
          $sugethw->{_Step} . ' output=' . $sugethw->{_output};

    }
    else {
        print("sugethw, output, missing output,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sugethw->{_verbose} = $verbose;
        $sugethw->{_note} =
          $sugethw->{_note} . ' verbose=' . $sugethw->{_verbose};
        $sugethw->{_Step} =
          $sugethw->{_Step} . ' verbose=' . $sugethw->{_verbose};

    }
    else {
        print("sugethw, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 2;

    return ($max_index);
}

1;
