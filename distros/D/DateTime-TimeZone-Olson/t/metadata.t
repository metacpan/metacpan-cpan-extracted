use warnings;
use strict;

use Test::More tests => 7;

BEGIN {
	use_ok "DateTime::TimeZone::Olson", qw(
		olson_version
		olson_canonical_names olson_link_names olson_all_names
		olson_links
		olson_country_selection
	);
}

like olson_version(), qr/\A[0-9]{4}[a-z]\z/;
is ref(olson_canonical_names), "HASH";
is ref(olson_link_names), "HASH";
is ref(olson_all_names), "HASH";
is ref(olson_links), "HASH";
is ref(olson_country_selection), "HASH";

1;
