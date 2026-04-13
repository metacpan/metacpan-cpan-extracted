use YAML::XS;

our $VERSION = '0.32';

=head1 VERSION

Version 0.32

=cut

sub export {
    my ($self, $plan, $file) = @_;
    YAML::XS::DumpFile($file, $plan);
}
