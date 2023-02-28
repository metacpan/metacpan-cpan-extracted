package App::SeismicUnixGui::sunix::header::segyclean;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SEGYCLEAN - zero out unassigned portion of header		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SEGYCLEAN - zero out unassigned portion of header		

 segyclean <stdin >stdout 					

 Since "foreign" SEG-Y tapes may use the unassigned portion	
 of the trace headers and since SU now uses it too, this	
 program zeros out the fields meaningful to SU.		

  Example:							
  	segyread trmax=200 | segyclean | suximage		



 Credits:
	CWP: Jack Cohen


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $segyclean = {
    _trmax => '',
    _Step  => '',
    _note  => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $segyclean->{_Step} = 'segyclean' . $segyclean->{_Step};
    return ( $segyclean->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $segyclean->{_note} = 'segyclean' . $segyclean->{_note};
    return ( $segyclean->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $segyclean->{_trmax} = '';
    $segyclean->{_Step}  = '';
    $segyclean->{_note}  = '';
}

=head2 sub trmax 

maximum number of traces that are expected in the file

=cut

sub trmax {

    my ( $self, $trmax ) = @_;
    if ( $trmax ne $empty_string ) {

        $segyclean->{_trmax} = $trmax;
        $segyclean->{_note} =
          $segyclean->{_note} . ' trmax=' . $segyclean->{_trmax};
        $segyclean->{_Step} =
          $segyclean->{_Step} . ' trmax=' . $segyclean->{_trmax};

    }
    else {
        print("segyclean, trmax, missing trmax,\n");
    }
}

=head2 sub get_max_index
   max index = number of input variables - 1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 0;

    return ($max_index);
}

1;
