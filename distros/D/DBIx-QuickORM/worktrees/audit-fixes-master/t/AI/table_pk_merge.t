use Test2::V0 '!meta', '!pass';

# Table merge primary-key conflict handling: when both the introspected table
# and the user declaration define a primary key, differing column sets
# (compared in ORM-name space) croak unless the declaration is flagged as an
# intentional override via primary_key_override.

use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;

my $C = 'DBIx::QuickORM::Schema::Table::Column';

sub make_table {
    my %params = @_;
    my $cols = delete $params{cols};

    my $order   = 1;
    my %columns = map { $_ => $C->new(name => $_, order => $order++) } @$cols;

    return DBIx::QuickORM::Schema::Table->new(name => 'example', columns => \%columns, %params);
}

subtest both_sides_identical => sub {
    my $db   = make_table(cols => ['id', 'name'], primary_key => ['id']);
    my $user = make_table(cols => ['id', 'name'], primary_key => ['id']);

    my $merged;
    ok(lives { $merged = $db->merge($user) }, "identical primary keys merge without complaint");
    is($merged->primary_key, ['id'], "merged primary key intact");
};

subtest identical_after_alias_translation => sub {
    my $db   = make_table(cols => ['id'], primary_key => ['id']);
    my $user = DBIx::QuickORM::Schema::Table->new(
        name        => 'example',
        columns     => {my_id => $C->new(name => 'my_id', db_name => 'id', order => 1)},
        primary_key => ['my_id'],
    );

    my $merged;
    ok(lives { $merged = $db->merge($user) }, "keys identical in ORM-name space merge without complaint");
    is($merged->primary_key, ['my_id'], "merged primary key uses ORM names");
};

subtest conflict_croaks => sub {
    my $db   = make_table(cols => ['id', 'alt'], primary_key => ['id']);
    my $user = make_table(cols => ['id', 'alt'], primary_key => ['alt']);

    my $err = dies { $db->merge($user) };
    ok($err, "conflicting primary keys croak");
    like($err, qr/Table 'example' has conflicting primary keys/, "message names the table");
    like($err, qr/database defines \(id\)/, "message includes the database key");
    like($err, qr/declaration defines \(alt\)/, "message includes the declared key");
    like($err, qr/primary_key 'override' option/, "message points at the override remedy");
};

subtest override_wins => sub {
    my $db   = make_table(cols => ['id', 'alt'], primary_key => ['id']);
    my $user = make_table(cols => ['id', 'alt'], primary_key => ['alt'], primary_key_override => 1);

    my $merged;
    ok(lives { $merged = $db->merge($user) }, "override flag silences the conflict");
    is($merged->primary_key, ['alt'], "the declared (override) key wins");
};

subtest single_side_wins => sub {
    my $db_only = make_table(cols => ['id'], primary_key => ['id'])->merge(make_table(cols => ['id']));
    is($db_only->primary_key, ['id'], "database-only primary key wins");

    my $user_only = make_table(cols => ['id'])->merge(make_table(cols => ['id'], primary_key => ['id']));
    is($user_only->primary_key, ['id'], "declaration-only primary key wins");
};

done_testing;
