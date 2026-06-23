use strict;
use warnings;
use Test::More;

use DBIO::Test;

my $warnings;
eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Schema;
    use base qw/DBIO::Schema/;
    __PACKAGE__->load_classes;
};
ok(!$@, 'Loaded all loadable classes') or diag $@;
like($warnings, qr/Failed to load DBIO::Test::Schema::NoSuchClass. Can't find source_name method. Is DBIO::Test::Schema::NoSuchClass really a full DBIO result class?/, 'Warned about broken result class');

my $source_a = DBIO::Test::Schema->source('Artist');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBIO::Test::Schema->resultset('Artist');
isa_ok($rset_a, 'DBIO::ResultSet');

done_testing;
