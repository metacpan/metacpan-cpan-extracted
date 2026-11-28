# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Value qw/raw inflated binary sql/;

for my $kind (qw/raw inflated binary/) {
    my $m = __PACKAGE__->can($kind)->([1]);
    isa_ok($m, ['DBIx::QuickORM::Value'], "$kind() makes a marker");
    is($m->kind,  $kind, "of kind $kind");
    is($m->value, [1],   "holding the value");
    like(dies { __PACKAGE__->can($kind)->(1, 2) }, qr/^$kind\(\) takes exactly one value/, "$kind() takes one value");
}

my $sql = sql('lower(?) || ?', 'A', 'b');
is([$sql->kind, $sql->value, $sql->binds], ['sql', 'lower(?) || ?', ['A', 'b']], "sql() holds the SQL and its binds");
is(sql('NOW()')->binds,                    [],                                   "binds default to none");
like(dies { sql(' ') },  qr/^sql\(\) needs the SQL as a string/, "Blank SQL croaks");
like(dies { sql(\'x') }, qr/^sql\(\) needs the SQL as a string/, "and so does a reference");

ok(!__PACKAGE__->can('nope'), "Only the four are exported");

done_testing;
