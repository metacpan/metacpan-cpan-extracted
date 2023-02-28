package App::SeismicUnixGui::sunix::header::sustrip;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUSTRIP - remove the SEGY headers from the traces		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUSTRIP - remove the SEGY headers from the traces		

 sustrip <stdin >stdout head=/dev/null outpar=/dev/tty ftn=0	

 Required parameters:						
 	none							

 Optional parameters:						
 	head=/dev/null		file to save headers in		

 	outpar=/dev/tty		output parameter file, contains:
 				number of samples (n1=)		
 				number of traces (n2=)		
 				sample rate in seconds (d1=)	

 	ftn=0			Fortran flag			
 				0 = write unformatted for C	
 				1 = ... for Fortran		

 Notes:							
 Invoking head=filename will write the trace headers into filename.
 You may paste the headers back onto the traces with supaste	
 See:  sudoc  supaste 	 for more information 			
 Related programs: supaste, suaddhead				

 Credits:
	SEP: Einar Kjartansson  c. 1985
	CWP: Jack K. Cohen        April 1990

 Trace header fields accessed: ns, dt

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

my $sustrip = {
    _ftn    => '',
    _head   => '',
    _outpar => '',
    _Step   => '',
    _note   => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sustrip->{_Step} = 'sustrip' . $sustrip->{_Step};
    return ( $sustrip->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sustrip->{_note} = 'sustrip' . $sustrip->{_note};
    return ( $sustrip->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sustrip->{_ftn}    = '';
    $sustrip->{_head}   = '';
    $sustrip->{_outpar} = '';
    $sustrip->{_Step}   = '';
    $sustrip->{_note}   = '';
}

=head2 sub ftn 


=cut

sub ftn {

    my ( $self, $ftn ) = @_;
    if (length $ftn) {

        $sustrip->{_ftn}  = $ftn;
        $sustrip->{_note} = $sustrip->{_note} . ' ftn=' . $sustrip->{_ftn};
        $sustrip->{_Step} = $sustrip->{_Step} . ' ftn=' . $sustrip->{_ftn};

    }
    else {
        print("sustrip, ftn, missing ftn,\n");
    }
}

=head2 sub head 


=cut

sub head {

    my ( $self, $head ) = @_;
    if ($head) {

        $sustrip->{_head} = $head;
        $sustrip->{_note} = $sustrip->{_note} . ' head=' . $sustrip->{_head};
        $sustrip->{_Step} = $sustrip->{_Step} . ' head=' . $sustrip->{_head};

    }
    else {
        print("sustrip, head, missing head,\n");
    }
}

=head2 sub header_file_out 


=cut

sub header_file_out {

    my ( $self, $head ) = @_;
    if ($head) {

        $sustrip->{_head} = $head;
        $sustrip->{_note} = $sustrip->{_note} . ' head=' . $sustrip->{_head};
        $sustrip->{_Step} = $sustrip->{_Step} . ' head=' . $sustrip->{_head};

    }
    else {
        print("sustrip, head, missing header_file_out,\n");
    }
}

=head2 sub outpar 


=cut

sub outpar {

    my ( $self, $outpar ) = @_;
    if ($outpar) {

        $sustrip->{_outpar} = $outpar;
        $sustrip->{_note} =
          $sustrip->{_note} . ' outpar=' . $sustrip->{_outpar};
        $sustrip->{_Step} =
          $sustrip->{_Step} . ' outpar=' . $sustrip->{_outpar};

    }
    else {
        print("sustrip, outpar, missing outpar,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # index=2
    my $max_index = 2;

    return ($max_index);
}

1;
