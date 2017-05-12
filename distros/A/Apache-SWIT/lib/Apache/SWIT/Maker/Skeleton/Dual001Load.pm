use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Dual001Load;
use base 'Apache::SWIT::Maker::Skeleton';

sub output_file { return 't/dual/001_load.t'; }
sub template { return <<'ENDS' };
use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;

BEGIN {
	use_ok('T::Test');
	use_ok('[% root_class_v %]::UI::Index');
};

my $t = T::Test->new;
sub is_content_gzipped {
	$t->with_or_without_mech_do(1, sub {
		$t->mech->get($t->mech->uri, 'Accept-Encoding', 'gzip,deflate');
		is($t->mech->response->headers->content_encoding, "gzip")
			or diag($t->mech->response->as_string);
	});
}

$t->ok_ht_index_r(make_url => 1, ht => { first => '' });
is_content_gzipped();
$t->ok_ht_index_r(base_url => '/', ht => { first => '' });
$t->ok_get('www/main.css');
$t->with_or_without_mech_do(1, sub { is($t->mech->ct, 'text/css'); });
$t->content_like(qr/CSS/);
is_content_gzipped();

$t->ok_get('/html-tested-javascript/serializer.js');
is_content_gzipped();
ENDS

1;
