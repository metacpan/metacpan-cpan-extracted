package App::SeismicUnixGui::sunix::header::suaddhead;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUADDHEAD - put headers on bare traces and set the tracl and ns fields
 AUTHOR: Juan Lorenzo
 DATE: June 7 2013 
 REQUIRES:  Seismic Unix modules (CSM)
 DESCRIPTION suaddhead 
 Version 0.0.1

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUADDHEAD - put headers on bare traces and set the tracl and ns fields

 suaddhead <stdin >stdout ns= ftn=0					

 Required parameter:							
 	ns=the number of samples per trace				

 Optional parameter:							
ifdef SU_LINE_HEADER
	head=           file to read headers in				
                       not supplied --  will generate headers 		
                       given        --  will read in headers and attach
                                        floating point arrays to form 	
                                        traces 			", 
                       (head can be created via sustrip program)	
endif
 	ftn=0		Fortran flag					
 			0 = data written unformatted from C		
 			1 = data written unformatted from Fortran	
       tsort=3         trace sorting code:				
                                1 = as recorded (no sorting)		
                                2 = CDP ensemble			
                                3 = single fold continuous profile	
                                4 = horizontally stacked		", 
       ntrpr=1         number of data traces per record		
                       if tsort=2, this is the number of traces per cdp", 

 Trace header fields set: ns, tracl					
 Use sushw/suchw to set other needed fields.				

 Caution: An incorrect ns field will munge subsequent processing.	
 Note:    n1 and nt are acceptable aliases for ns.			

 Example:								
 suaddhead ns=1024 <bare_traces | sushw key=dt a=4000 >segy_traces	

 This command line adds headers with ns=1024 samples.  The second part	
 of the pipe sets the trace header field dt to 4 ms.	See also the	
 selfdocs of related programs  sustrip and supaste.			
 See:   sudoc supaste							
 Related Programs:  supaste, sustrip 					
=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suaddhead = {
    _ftn   => '',
    _head  => '',
    _ns    => '',
    _ntrpr => '',
    _tsort => '',
    _Step  => '',
    _note  => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suaddhead->{_Step} = 'suaddhead' . $suaddhead->{_Step};
    return ( $suaddhead->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suaddhead->{_note} = 'suaddhead' . $suaddhead->{_note};
    return ( $suaddhead->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suaddhead->{_ftn}   = '';
    $suaddhead->{_head}  = '';
    $suaddhead->{_ns}    = '';
    $suaddhead->{_ntrpr} = '';
    $suaddhead->{_tsort} = '';
    $suaddhead->{_Step}  = '';
    $suaddhead->{_note}  = '';
}

=head2 sub ftn 


=cut

sub ftn {

    my ( $self, $ftn ) = @_;
    if ( $ftn ne $empty_string ) {

        $suaddhead->{_ftn} = $ftn;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' ftn=' . $suaddhead->{_ftn};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' ftn=' . $suaddhead->{_ftn};

    }
    else {
        print("suaddhead, ftn, missing ftn,\n");
    }
}

=head2 sub head 


=cut

sub head {

    my ( $self, $head ) = @_;
    if ( $head ne $empty_string ) {

        $suaddhead->{_head} = $head;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' head=' . $suaddhead->{_head};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' head=' . $suaddhead->{_head};

    }
    else {
        print("suaddhead, head, missing head,\n");
    }
}

=head2 sub number_samples 


=cut

sub number_samples {

    my ( $self, $ns ) = @_;
    if ( $ns ne $empty_string ) {

        $suaddhead->{_ns} = $ns;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' ns=' . $suaddhead->{_ns};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' ns=' . $suaddhead->{_ns};

    }
    else {
        print("suaddhead, number_samples, missing ns,\n");
    }
}

=head2 sub ns 


=cut

sub ns {

    my ( $self, $ns ) = @_;
    if ( $ns ne $empty_string ) {

        $suaddhead->{_ns} = $ns;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' ns=' . $suaddhead->{_ns};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' ns=' . $suaddhead->{_ns};

    }
    else {
        print("suaddhead, ns, missing ns,\n");
    }
}

=head2 sub ntrpr 


=cut

sub ntrpr {

    my ( $self, $ntrpr ) = @_;
    if ( $ntrpr ne $empty_string ) {

        $suaddhead->{_ntrpr} = $ntrpr;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' ntrpr=' . $suaddhead->{_ntrpr};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' ntrpr=' . $suaddhead->{_ntrpr};

    }
    else {
        print("suaddhead, ntrpr, missing ntrpr,\n");
    }
}

=head2 sub tsort 


=cut

sub tsort {

    my ( $self, $tsort ) = @_;
    if ( $tsort ne $empty_string ) {

        $suaddhead->{_tsort} = $tsort;
        $suaddhead->{_note} =
          $suaddhead->{_note} . ' tsort=' . $suaddhead->{_tsort};
        $suaddhead->{_Step} =
          $suaddhead->{_Step} . ' tsort=' . $suaddhead->{_tsort};

    }
    else {
        print("suaddhead, tsort, missing tsort,\n");
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
