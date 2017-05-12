use lib './t';
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

use Mock::Basic;
use Mock::BasicPlus;

my $basic = Mock::Basic->new;
$basic->setup_test_db;
my $plus  = Mock::BasicPlus->new;
$plus->setup_test_db;

subtest 'using multiple proxy_table instance ' => sub {
    eval "use DateTime";
    plan skip_all => 'this test require DateTime' if $@;
    ok($basic->proxy_table != $plus->proxy_table, "ProxyTable instance should be different");
    my $dt = DateTime->new(year => 2010, month => 1, day => 1);
    my $rule_basic = $basic->proxy_table->rule('access_log', $dt);
    $rule_basic->copy_table;
    is($rule_basic->table_name, 'access_log_201001', 'strftime ok');

    my $rule_plus = $plus->proxy_table->rule('used_log', $dt);
    $rule_plus->copy_table;
    is($rule_plus->table_name, 'used_log_201001', 'strftime ok');
    done_testing();
};

done_testing();
