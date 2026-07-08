use Test2::V0 '!meta', '!pass';

# Regression (adversarial review of the audit integration): Schema::_rekey_tables
# must not silently collapse two DIFFERENT physical tables when a declared
# db_name alias re-keys an introspected table onto the name of another real
# introspected table. It now croaks on the genuine name conflict instead of
# dropping one table (hash-order dependent).

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;

my $C = 'DBIx::QuickORM::Schema::Table::Column';
sub col { $C->new(name => 'id', order => 1, affinity => 'numeric') }
sub tbl { my ($name, %e) = @_; DBIx::QuickORM::Schema::Table->new(name => $name, columns => {id => col()}, %e) }

subtest collision_croaks => sub {
    # Introspected DB has real tables foo and bar; the declaration renames
    # physical foo to the ORM name 'bar', which already names a real table.
    my $intro = DBIx::QuickORM::Schema->new(name => 'i', tables => {foo => tbl('foo'), bar => tbl('bar')});
    my $decl  = DBIx::QuickORM::Schema->new(name => 'd', tables => {bar => tbl('bar', db_name => 'foo')});

    like(
        dies { $intro->merge($decl) },
        qr/already belongs to another introspected table|Cannot map declared table/,
        "a db_name alias colliding with another physical table croaks instead of silently dropping one",
    );
};

subtest clean_alias_still_works => sub {
    # A db_name alias with no collision (physical foo, declared ORM-name widget)
    # collapses to one source under the declared name without complaint.
    my $intro = DBIx::QuickORM::Schema->new(name => 'i', tables => {foo => tbl('foo')});
    my $decl  = DBIx::QuickORM::Schema->new(name => 'd', tables => {widget => tbl('widget', db_name => 'foo')});

    my $merged;
    ok(lives { $merged = $intro->merge($decl) }, "a non-colliding db_name alias merges cleanly") or note $@;
    ok($merged->maybe_table('widget'), "the physical table is reachable under the declared ORM name");
    ok(!$merged->maybe_table('foo'),   "and not left behind under its database name");
};

done_testing;
