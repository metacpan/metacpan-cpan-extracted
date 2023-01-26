package App::SeismicUnixGui::misc::perl_use_pkg;
use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for instantiation
       of imported packages 

=cut

my @use;

$use[0] = ' use aliased \'App::SeismicUnixGui::misc::message\';
 use aliased \'App::SeismicUnixGui::misc::flow\';
 ';

sub section {
    return ( \@use );
}

1;
