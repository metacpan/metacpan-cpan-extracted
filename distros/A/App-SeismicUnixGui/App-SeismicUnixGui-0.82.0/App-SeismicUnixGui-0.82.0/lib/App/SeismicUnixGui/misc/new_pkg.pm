package App::SeismicUnixGui::misc::new_pkg;
use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for instantiation
       of imported packages 

=cut

my @use;

$use[0] = "\n\t" . 'use aliased \'App::SeismicUnixGui::misc::message\';' . 
          "\n\t" . 'use aliased \'App::SeismicUnixGui::misc::flow\';' .
           "\n";

sub section {
    my ($self) = @_;

    # print("perl/new_pkg,@use\n");
    return ( \@use );
}

1;
