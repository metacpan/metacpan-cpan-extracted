package App::SeismicUnixGui::developer::code::sunix::sunix_package_tail;
use Moose;
our $VERSION = '0.0.1';

=head2 Default perl lines for the end of a package 


=cut
my @lines;

$lines[0]  = "\n" . '=head2 sub get_max_index' . "\n\n";
$lines[1]  = 'max index = number of input variables -1' . "\n";
$lines[2]  = ' ' . "\n";
$lines[3]  = '=cut' . "\n";
$lines[4]  = ' ' . "\n";
$lines[5]  = 'sub get_max_index {' . "\n";
$lines[6]  = ' 	  my ($self) = @_;' . "\n";
$lines[7]  = '    my $max_index = 36;' . "\n";
$lines[8]  = '' . "\n";
$lines[9]  = '    return($max_index);' . "\n";
$lines[10] = '}' . "\n";
$lines[11] = ' ' . "\n";
$lines[12] = ' ' . "\n";

$lines[13] = ("1;");

sub section {
	my ($self) = @_;
	return ( \@lines );
}

1;
