use YAML::XS;

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=cut

sub export {
	my ($self, $plan, $file) = @_;
	YAML::XS::DumpFile($file, $plan);
}
