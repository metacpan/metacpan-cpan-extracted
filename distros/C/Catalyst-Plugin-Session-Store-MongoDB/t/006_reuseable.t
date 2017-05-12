use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qw|$Bin/lib t/lib|;

use Test::More;
use Fixture;

# f as in fixture
my ($f);

BEGIN {
  $f = Fixture->new();

  my $reason = $f->setup();
  plan skip_all => $reason if $reason;
}

use Catalyst::Plugin::Session::Test::Store (
  backend => 'MongoDB',
  config => {
    hostname => $ENV{MONGODB_HOST},
    port => $ENV{MONGODB_PORT},
    dbname => $ENV{TEST_DB},
    collectionname => $ENV{TEST_COLLECTION},
  },
#  extra_tests => 1,
);

done_testing();

END {
  $f->teardown();
}
