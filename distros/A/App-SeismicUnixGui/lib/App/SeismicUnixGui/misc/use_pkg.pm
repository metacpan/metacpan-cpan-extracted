package App::SeismicUnixGui::misc::use_pkg;

use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for start of instantiation
       of imported packages 

=cut

my @use;
$use[0] = "\t" . 'use Moose;' . "\n";
$use[1] = "\t"
	. 'use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);'
	. "\n";
$use[2] = "\t" . 'use aliased \'App::SeismicUnixGui::configs::big_streams::Project_config\';' . "\n\n";
$use[3] = "\t" . 'use aliased \'App::SeismicUnixGui::misc::message\';' . "\n";
$use[4] = "\t" . 'use aliased \'App::SeismicUnixGui::misc::flow\';' . "\n";
$use[5] = "\t" . 'my $Project'. "\t\t" . '= Project_config->new();' . "\n";
$use[6] =
	"\t" . 'my $DATA_SEISMIC_SU' . "\t" . '= $Project->DATA_SEISMIC_SU;' . "\n";
$use[7] = "\t"
	. 'my $DATA_SEISMIC_BIN' . "\t"
	. '= $Project->DATA_SEISMIC_BIN;' . "\n\n";

sub section {
	return ( \@use );
}

1;
