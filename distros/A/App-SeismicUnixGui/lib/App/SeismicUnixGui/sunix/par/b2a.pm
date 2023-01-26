package App::SeismicUnixGui::sunix::par::b2a;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  B2A - convert binary floats to ascii				
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 B2A - convert binary floats to ascii				

 b2a <stdin >stdout 						

 Required parameters:						
 	none							

 Optional parameters:						
 	n1=2		floats per line in output file 		
       format=0	scientific notation	 		
 			=1 long decimal float form		

 	outpar=/dev/tty output parameter file, contains the	
			number of lines (n=)			
                       other choices for outpar are: /dev/tty, 
                       /dev/stderr, or a name of a disk file   

 Note: 							
 Parameter:							", 
  format=0 uses printf("%15.10e ", x[i1])			
  format=1 uses printf("%15.15f ", x[i1])			

 Credits:
	CWP: Jack K. Cohen

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

my $b2a = {
    _format => '',
    _n1     => '',
    _outpar => '',
    _Step   => '',
    _note   => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $b2a->{_Step} = 'b2a' . $b2a->{_Step};
    return ( $b2a->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $b2a->{_note} = 'b2a' . $b2a->{_note};
    return ( $b2a->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $b2a->{_format} = '';
    $b2a->{_n1}     = '';
    $b2a->{_outpar} = '';
    $b2a->{_Step}   = '';
    $b2a->{_note}   = '';
}

=head2 sub format 


=cut

sub format {

    my ( $self, $format ) = @_;
    if ($format) {

        $b2a->{_format} = $format;
        $b2a->{_note}   = $b2a->{_note} . ' format=' . $b2a->{_format};
        $b2a->{_Step}   = $b2a->{_Step} . ' format=' . $b2a->{_format};

    }
    else {
        print("b2a, format, missing format,\n");
    }
}

=head2 sub n1 


=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ($n1) {

        $b2a->{_n1}   = $n1;
        $b2a->{_note} = $b2a->{_note} . ' n1=' . $b2a->{_n1};
        $b2a->{_Step} = $b2a->{_Step} . ' n1=' . $b2a->{_n1};

    }
    else {
        print("b2a, n1, missing n1,\n");
    }
}

=head2 sub outpar 


=cut

sub outpar {

    my ( $self, $outpar ) = @_;
    if ($outpar) {

        $b2a->{_outpar} = $outpar;
        $b2a->{_note}   = $b2a->{_note} . ' outpar=' . $b2a->{_outpar};
        $b2a->{_Step}   = $b2a->{_Step} . ' outpar=' . $b2a->{_outpar};

    }
    else {
        print("b2a, outpar, missing outpar,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=2
    my $max_index = 2;

    return ($max_index);
}

1;
