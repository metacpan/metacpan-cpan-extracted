use lib './t';
use Test::More;
use Test::Exception;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

use Mock::Basic;

my $skinny = Mock::Basic->new;
$skinny->setup_test_db;

ok($skinny->can('proxy_table'), 'proxy_table can call');
isa_ok($skinny->proxy_table, 'DBIx::Skinny::ProxyTable');

my $table = "access_log_200901";
$skinny->proxy_table->copy_table('access_log' => $table);

dies_ok {
    $skinny->search($table, {});
};

$skinny->proxy_table->set('access_log', $table);
ok($skinny->schema->schema_info->{$table}, 'schema_info should be exist ');
is($skinny->schema->schema_info->{$table}, $skinny->schema->schema_info->{'access_log'}, 'row class map should be exist');

lives_ok {
    $skinny->search($table, {});
};

my $iter = $skinny->search($table);
isa_ok($iter, "DBIx::Skinny::Iterator");

dies_ok {
    $skinny->proxy_table->set('access_log', 'access_log.fuga');
};

dies_ok {
    $skinny->proxy_table->set('access_log', 'access_log; fuga');
};

done_testing();

