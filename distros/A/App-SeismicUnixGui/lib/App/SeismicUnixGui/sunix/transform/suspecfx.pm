package App::SeismicUnixGui::sunix::transform::suspecfx;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUSPECFX - Fourier SPECtrum (T -> F) of traces 		
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUSPECFX - Fourier SPECtrum (T -> F) of traces 		

 suspecfx <infile >outfile 					

 Note: To facilitate further processing, the sampling interval	
       in frequency and first frequency (0) are set in the	
	output header.						

	NULL=nothing

 Credits:

	CWP: Dave (algorithm), Jack (reformatting for SU)

 Trace header fields accessed: ns, dt
 Trace header fields modified: ns, dt, trid, d1, f1

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suspecfx = {
    _NULL => '',
    _Step => '',
    _note => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suspecfx->{_Step} = 'suspecfx' . $suspecfx->{_Step};
    return ( $suspecfx->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suspecfx->{_note} = 'suspecfx' . $suspecfx->{_note};
    return ( $suspecfx->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suspecfx->{_NULL} = '';
    $suspecfx->{_Step} = '';
    $suspecfx->{_note} = '';
}

=head2 sub NULL 


=cut

sub NULL {

    my ( $self, $NULL ) = @_;
    if ( $NULL ne $empty_string ) {

        $suspecfx->{_NULL} = $NULL;
        $suspecfx->{_note} = $suspecfx->{_note} . ' ' . $suspecfx->{_NULL};
        $suspecfx->{_Step} = $suspecfx->{_Step} . ' ' . $suspecfx->{_NULL};

    }
    else {
        print("suspecfx, NULL, missing NULL,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 0;

    return ($max_index);
}

1;
