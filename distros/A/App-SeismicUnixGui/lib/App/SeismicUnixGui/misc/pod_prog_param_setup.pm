package App::SeismicUnixGui::misc::pod_prog_param_setup;
use Moose;
our $VERSION = '0.0.1';

=head2 Default pod lines for   

 set-up of individual programs
 setting parameter values
 
=cut

my @pod;

$pod[0] = "\n" . '=head2 Set up' . "\n";

$pod[1] = "\n" . '=cut' . "\n\n";

sub section {
    return ( \@pod );
}

1;
