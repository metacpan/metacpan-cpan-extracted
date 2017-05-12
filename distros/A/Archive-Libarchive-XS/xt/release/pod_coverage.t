use strict;
use warnings;
use Test::More;
use File::Spec;
BEGIN {
  plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
    unless eval qq{ use Test::Pod::Coverage; 1 };
}
plan tests => 1;

my $config = {
  trustme => [ qr{^(ARCHIVE|AE)_} ],
  pod_from => File::Spec->catfile(qw( lib Archive Libarchive XS.xs )),
};

pod_coverage_ok 'Archive::Libarchive::XS', $config, 'coverage';
