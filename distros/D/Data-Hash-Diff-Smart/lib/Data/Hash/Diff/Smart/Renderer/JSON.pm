package Data::Hash::Diff::Smart::Renderer::JSON;

use strict;
use warnings;

sub render {
	my $changes = $_[0];

	require JSON::MaybeXS;
	JSON::MaybeXS->import();

	# Encode with canonical ordering for stable test output
	my $json = JSON::MaybeXS->new(
		utf8	   => 1,
		canonical  => 1,
		pretty	 => 0,
	);

	return $json->encode($changes);
}

1;
