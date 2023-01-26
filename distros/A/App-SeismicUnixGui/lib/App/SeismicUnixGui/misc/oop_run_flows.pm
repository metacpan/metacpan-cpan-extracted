package App::SeismicUnixGui::misc::oop_run_flows;
use Moose;
our $VERSION = '0.0.1';

=head2 Default 

run	flows  

=cut

my @run_flows;

$run_flows[0] =

  "\t" . '$run->flow(\$flow[1]);' . "\n\n";

sub section {
    my ($self) = @_;
    return ( \@run_flows );
}

1;
