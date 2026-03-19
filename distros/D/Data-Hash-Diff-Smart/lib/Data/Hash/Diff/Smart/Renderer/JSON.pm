package Data::Hash::Diff::Smart::Renderer::JSON;

use strict;
use warnings;

use JSON::MaybeXS;

sub render {
    my ($changes) = @_;

    # Encode with canonical ordering for stable test output
    my $json = JSON::MaybeXS->new(
        utf8       => 1,
        canonical  => 1,
        pretty     => 0,
    );

    return $json->encode($changes);
}

1;
