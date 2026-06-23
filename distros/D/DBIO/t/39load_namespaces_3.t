use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use lib qw(t/lib);
use DBIO::Test;

lives_ok (sub {
  warnings_exist ( sub {
      package DBIO::Test::Namespace::Other;
      use base qw/DBIO::Schema/;
      __PACKAGE__->load_namespaces(
          result_namespace => [ '+TestDBIO::Broken::Rslt', '+DBIO::Test::Namespace::OtherRslt' ],
          resultset_namespace => '+DBIO::Test::Namespace::RSet',
      );
    },
    qr/load_namespaces found ResultSet class 'DBIO::Test::Namespace::RSet::C' with no corresponding Result class/,
  );
});

my $source_a = DBIO::Test::Namespace::Other->source('A');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBIO::Test::Namespace::Other->resultset('A');
isa_ok($rset_a, 'DBIO::Test::Namespace::RSet::A');

my $source_b = DBIO::Test::Namespace::Other->source('B');
isa_ok($source_b, 'DBIO::ResultSource::Table');
my $rset_b   = DBIO::Test::Namespace::Other->resultset('B');
isa_ok($rset_b, 'DBIO::ResultSet');

my $source_d = DBIO::Test::Namespace::Other->source('D');
isa_ok($source_d, 'DBIO::ResultSource::Table');

done_testing;
