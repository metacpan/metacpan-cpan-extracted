package App::Test::Generator::Exporter::YAML;

use strict;
use warnings;
use Params::Validate::Strict 0.30;
use YAML::XS;

our $VERSION = '0.40';

=head1 NAME

App::Test::Generator::Exporter::YAML - Serialise a test plan to YAML

=head1 VERSION

Version 0.40

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

	my %args;
	$args{plan} = $plan if defined $plan;
	$args{file} = $file if defined $file;

	my $params = Params::Validate::Strict::validate_strict({
		args => \%args,
		schema => {
			plan => { type => 'hashref' },
			file => { type => 'string', min => 1 },
		}
	});

	YAML::XS::DumpFile($params->{file}, $params->{plan});

	return;
}

1;
