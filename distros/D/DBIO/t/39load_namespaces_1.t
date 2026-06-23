use strict;
use warnings;
use Test::More;

use lib qw(t/lib);
use DBIO::Test;

my $warnings;
eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Namespace;
    use base qw/DBIO::Schema/;
    __PACKAGE__->load_namespaces(
      resultset_namespace => [ 'ResultSet', '+TestDBIO::Broken::ResultSet' ],
    );
};
ok(!$@, 'load_namespaces doesnt die') or diag $@;
like($warnings, qr/load_namespaces found ResultSet class 'DBIO::Test::Namespace::ResultSet::C' with no corresponding Result class/, 'Found warning about extra ResultSet classes');

like($warnings, qr/load_namespaces found ResultSet class 'TestDBIO::Broken::ResultSet::D' that does not subclass DBIO::ResultSet/, 'Found warning about ResultSets with incorrect subclass');

my $source_a = DBIO::Test::Namespace->source('A');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBIO::Test::Namespace->resultset('A');
isa_ok($rset_a, 'DBIO::Test::Namespace::ResultSet::A');

my $source_b = DBIO::Test::Namespace->source('B');
isa_ok($source_b, 'DBIO::ResultSource::Table');
my $rset_b   = DBIO::Test::Namespace->resultset('B');
isa_ok($rset_b, 'DBIO::ResultSet');

for my $moniker (qw/A B/) {
  my $class = "DBIO::Test::Namespace::Result::$moniker";
  ok(!defined($class->result_source_instance->source_name), "Source name of $moniker not defined");
}

done_testing;
