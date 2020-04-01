package MongoDBTest;

use strict;
use warnings;

use Exporter 'import';
use Test::More;
use MongoDB;

our @EXPORT_OK = qw(
  test_db_or_skip
);

sub test_db_or_skip {
  my $cfg = shift;

  # source:
  # https://metacpan.org/pod/distribution/MongoDB/lib/MongoDB/Upgrading.pod
  plan skip_all => 'no mongod'
    unless eval {
    MongoDB->connect->db( $cfg->{db} )->run_command( [ ismaster => 1 ] );
    };
}

