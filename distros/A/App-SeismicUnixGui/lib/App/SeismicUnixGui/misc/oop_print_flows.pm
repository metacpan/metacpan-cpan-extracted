package App::SeismicUnixGui::misc::oop_print_flows;
use Moose;
our $VERSION = '0.0.1';

=head2 Default 

	print flow lines  

=cut

my @print_flows;

$print_flows[0] =

  ("\t\$log->screen(\$flow[1]);\n");

sub section {
    my ($self) = @_;
    return ( \@print_flows );
}

1;
