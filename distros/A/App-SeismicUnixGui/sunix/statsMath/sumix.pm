package App::SeismicUnixGui::sunix::statsMath::sumix;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUMIX - compute weighted moving average (trace MIX) on a panel	
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUMIX - compute weighted moving average (trace MIX) on a panel	
	  of seismic data						

 sumix <stdin >sdout 							
 mix=.6,1,1,1,.6	array of weights for weighted average		


 Note: 								
 The number of values defined by mix=val1,val2,... determines the number
 of traces to be averaged, the values determine the weights.		

 Examples: 								
 sumix <stdin mix=.6,1,1,1,.6 >sdout 	(default) mix over 5 traces weights
 sumix <stdin mix=1,1,1 >sdout 	simple 3 trace moving average	


 Author:
	CWP: John Stockwell, Oct 1995

 Trace header fields accessed: ns

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sumix = {
    _mix  => '',
    _Step => '',
    _note => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sumix->{_Step} = 'sumix' . $sumix->{_Step};
    return ( $sumix->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sumix->{_note} = 'sumix' . $sumix->{_note};
    return ( $sumix->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sumix->{_mix}  = '';
    $sumix->{_Step} = '';
    $sumix->{_note} = '';
}

=head2 sub mix 


=cut

sub mix {

    my ( $self, $mix ) = @_;
    if ( $mix ne $empty_string ) {

        $sumix->{_mix}  = $mix;
        $sumix->{_note} = $sumix->{_note} . ' mix=' . $sumix->{_mix};
        $sumix->{_Step} = $sumix->{_Step} . ' mix=' . $sumix->{_mix};

    }
    else {
        print("sumix, mix, missing mix,\n");
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
