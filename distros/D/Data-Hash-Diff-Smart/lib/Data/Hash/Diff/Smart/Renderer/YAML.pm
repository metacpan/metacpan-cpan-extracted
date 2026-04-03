package Data::Hash::Diff::Smart::Renderer::YAML;

use strict;
use warnings;

sub render {
	my $changes = $_[0];

	require YAML::XS;
	YAML::XS->import();

	# YAML::XS::Dump returns a trailing newline — that’s fine
	return YAML::XS::Dump($changes);
}

1;
