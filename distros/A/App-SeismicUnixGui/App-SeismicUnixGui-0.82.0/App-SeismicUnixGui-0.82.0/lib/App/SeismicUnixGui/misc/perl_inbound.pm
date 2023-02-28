package App::SeismicUnixGui::misc::perl_inbound;
use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for the inbound files


=cut

my @inbound;
my $file_name = '';

$inbound[1] = ' $sufile_in[1]		    = $file_in[1].$suffix_su;';
$inbound[2] =
  ' $inbound[1]		    = $DATA_SEISMIC_SU.' . "'/'." . '$sufile_in[1];' . "\n";

sub section {
    my $self;
    ( $self, $file_name ) = @_;
    $inbound[0] = ' $file_in[1] 		    = ' . "'$file_name';\n";
    return ( \@inbound );
}

1;
