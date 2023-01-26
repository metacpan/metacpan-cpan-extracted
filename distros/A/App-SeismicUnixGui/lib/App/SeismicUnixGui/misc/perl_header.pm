package App::SeismicUnixGui::misc::perl_header;
use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for the headers of the file

 _first_entry_num is normally 1
 _max_entry_num is defaulted to 14

=cut

my @head;

$head[0] = ("use Moose;");
$head[1] =
  'use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);';
$head[2] = 'use System_Variables;' . "\n";

sub section {
    return ( \@head );
}

1;
