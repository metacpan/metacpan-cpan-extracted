use Test2::V0;
use open qw[:std :encoding(UTF-8)];
#
use lib '../lib', 'lib';
use Acme::Free::Advice qw[:all];
#
imported_ok qw[advice flavors];
#
ok my @flavors = flavors(), 'flavors() returns a list';
ok +advice(),               'advice()';
subtest 'flavors' => sub {
    ok advice($_), 'advice(' . $_ . ')' for sort @flavors;
};
#
done_testing;
