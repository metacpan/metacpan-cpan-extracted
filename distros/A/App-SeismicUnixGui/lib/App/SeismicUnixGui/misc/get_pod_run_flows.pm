package App::SeismicUnixGui::misc::pod_run_flows;
use Moose;
our $VERSION = '0.0.1';

=head2 Default pod lines for   

 running flows 

=cut

my @pod;

$pod[0] = '

=head2 RUN FLOW(s) 


=cut' . "\n";

sub section {
    my ($self) = @_;
    return ( \@pod );
}

1;
