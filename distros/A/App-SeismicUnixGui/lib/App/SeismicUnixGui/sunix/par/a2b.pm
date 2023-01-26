package App::SeismicUnixGui::sunix::par::a2b;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  A2B - convert ascii floats to binary 				
 AUTHOR: Juan Lorenzo
 
 DESCRIPTION: 
 Version: 0.0.4
 Package used for interactive velocity analysis
 
 DATE:   Nov 1 2012,
         sept. 13 2013
         oct. 21 2013
         July 15 2015 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 A2B - convert ascii floats to binary 				

 a2b <stdin >stdout outpar=/dev/null 				

 Required parameters:						
 	none							

 Optional parameters:						
 	n1=2		floats per line in input file		

 	outpar=/dev/null output parameter file, contains the	
			number of lines (n=)			
 			other choices for outpar are: /dev/tty,	
 			/dev/stderr, or a name of a disk file	

 Credits:
	CWP: Jack K. Cohen, Dave Hale
	Hans Ecke 2002: Replaced line-wise file reading via gets() with 
			float-wise reading via fscanf(). This makes it 
			much more robust: it does not impose a specific 
			structure on the input file.


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.4';

my $a2b = {
    _floats_per_line => '',
    _n1              => '',
    _outpar          => '',
    _Step            => '',
    _note            => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $a2b->{_Step} = 'a2b' . $a2b->{_Step};
    return ( $a2b->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $a2b->{_note} = 'a2b' . $a2b->{_note};
    return ( $a2b->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $a2b->{_floats_per_line} = '';
    $a2b->{_n1}              = '';
    $a2b->{_outpar}          = '';
    $a2b->{_Step}            = '';
    $a2b->{_note}            = '';
}

=head2 subroutine  floats_per_line

  you need to know how many numbers per line
  will be in the output file 

=cut

sub floats_per_line {

    my ( $self, $n1 ) = @_;
    if ($n1) {

        $a2b->{_n1}   = $n1;
        $a2b->{_note} = $a2b->{_note} . ' n1=' . $a2b->{_n1};
        $a2b->{_Step} = $a2b->{_Step} . ' n1=' . $a2b->{_n1};

    }
    else {
        print("a2b, floats_per_line, missing floats_per_line,\n");
    }
}

=head2 sub n1 

  you need to know how many numbers per line
  will be in the output file 

=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ($n1) {

        $a2b->{_n1}   = $n1;
        $a2b->{_note} = $a2b->{_note} . ' n1=' . $a2b->{_n1};
        $a2b->{_Step} = $a2b->{_Step} . ' n1=' . $a2b->{_n1};

    }
    else {
        print("a2b, n1, missing n1,\n");
    }
}

=head2 sub outpar 

  sets  how to redirect metadata
  to either screen, a file, stderr, or 
  to be lost.
  
  Internally, determine whether we have a string or a reference to an array

=cut

sub outpar {

    my ( $self, $outpar ) = @_;
    if ($outpar) {

        if ( ref($outpar) eq "SCALAR" ) {

            #  print("success\n\n") ;
            $a2b->{_outpar} = $$outpar;
            $a2b->{_note}   = $a2b->{_note} . ' outpar =' . $a2b->{_outpar};
            $a2b->{_Step}   = $a2b->{_Step} . ' outpar=' . $a2b->{_outpar};
        }
        elsif ( ref($outpar) ne "SCALAR" ) {

            # not a scalar reference to an array
            $a2b->{_outpar} = $outpar;
            $a2b->{_note}   = $a2b->{_note} . ' outpar =' . $a2b->{_outpar};
            $a2b->{_Step}   = $a2b->{_Step} . ' outpar=' . $a2b->{_outpar};

        }
        else {
            print("a2b, outpar, missing outpar,\n");
        }
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # index=1
    my $max_index = 1;

    return ($max_index);
}

1;
