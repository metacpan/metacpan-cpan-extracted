use YAML::XS;

our $VERSION = '0.39';

=head1 VERSION

Version 0.39

=cut

=head2 export

Serialise a plan hashref to a YAML file on disk.

=head3 Arguments

=over 4

=item * C<$plan>

A hashref representing the test plan to serialise.

=item * C<$file>

A string. The path to the output YAML file.

=back

=head3 Returns

Nothing.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT },
        plan => { type => HASHREF },
        file => { type => 'string' },
    }

=head4 output

    { type => UNDEF }

=cut

sub export {
	my ($self, $plan, $file) = @_;
	YAML::XS::DumpFile($file, $plan);
}
