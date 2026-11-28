# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::JoinRow;

my $order = {id => 1};
my $jrow  = DBIx::QuickORM::JoinRow->new(aliases => ['orders', 'rep'], rows => {orders => $order, rep => undef}, data => {'orders.id' => 1, 'rep.id' => undef});

is([$jrow->aliases], ['orders', 'rep'], "aliases lists the components in join order");
ref_is($jrow->row('orders'), $order, "row gives a component's row");
is($jrow->row('rep'), undef,                                 "or undef for a left join that matched nothing");
is($jrow->data,       {'orders.id' => 1, 'rep.id' => undef}, "data is the fetched values");
ok(!$jrow->can($_), "no $_ method") for qw/update delete insert/;

like(dies { $jrow->row('nope') },                                   qr/^The join has no component named 'nope'/, "An unknown component croaks");
like(dies { DBIx::QuickORM::JoinRow->new(rows => {}, data => {}) }, qr/^'aliases' must be an arrayref/,          "aliases are required");

done_testing;
