use strict;
use warnings;
use Test::More;

use lib qw(t/lib);
use DBIO::Test;

plan tests => 6;

my $warnings;
eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Namespace;
    use base qw/DBIO::Schema/;
    __PACKAGE__->load_namespaces( default_resultset_class => 'RSBase' );
};
ok(!$@) or diag $@;
like($warnings, qr/load_namespaces found ResultSet class 'DBIO::Test::Namespace::ResultSet::C' with no corresponding Result class/);

my $source_a = DBIO::Test::Namespace->source('A');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBIO::Test::Namespace->resultset('A');
isa_ok($rset_a, 'DBIO::Test::Namespace::ResultSet::A');

my $source_b = DBIO::Test::Namespace->source('B');
isa_ok($source_b, 'DBIO::ResultSource::Table');
my $rset_b   = DBIO::Test::Namespace->resultset('B');
isa_ok($rset_b, 'DBIO::Test::Namespace::RSBase');
