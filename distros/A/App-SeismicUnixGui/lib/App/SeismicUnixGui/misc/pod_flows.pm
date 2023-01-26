package App::SeismicUnixGui::misc::pod_flows;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: pod_flows
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017 

 DESCRIPTION 
     object-oriented perl lines of text
		2018 V 0.0.1

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

use Moose;
our $VERSION = '0.0.1';

=head2 Default pod lines for   

 flows 

=cut

my @pod;

$pod[0] = '

=head2 DEFINE FLOW(s) 


=cut' . "\n";

sub section {
    my ($self) = @_;
    return ( \@pod );
}

1;
