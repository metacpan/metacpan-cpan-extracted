use Test2::V0 '!meta', '!pass';

# Redefining a named table/schema/db within the same registry must croak
# rather than silently replacing the earlier definition (last-wins). Legitimate
# re-declaration paths (alt/variant frames, and the same name in a different
# schema) must be unaffected.

{
    package My::Redef::Table;
    use DBIx::QuickORM;
}

{
    package My::Redef::Schema;
    use DBIx::QuickORM;
}

{
    package My::Redef::OK;
    use DBIx::QuickORM;
}

my $b_table = My::Redef::Table->builder;

like(
    dies {
        $b_table->schema(dup_tables => sub {
            $b_table->table(foo => sub { $b_table->column(id => sub { $b_table->affinity('numeric') }) });
            $b_table->table(foo => sub { $b_table->column(id => sub { $b_table->affinity('numeric') }) });
        });
    },
    qr/'foo' has already been defined/,
    "defining the same table name twice in one schema croaks",
);

my $b_schema = My::Redef::Schema->builder;

like(
    dies {
        $b_schema->schema(dup_schema => sub { 1 });
        $b_schema->schema(dup_schema => sub { 1 });
    },
    qr/'dup_schema' has already been defined/,
    "defining the same schema name twice croaks",
);

my $b_ok = My::Redef::OK->builder;

ok(
    lives {
        $b_ok->schema(schema_a => sub {
            $b_ok->table(shared => sub { $b_ok->column(id => sub { $b_ok->affinity('numeric') }) });
        });
        $b_ok->schema(schema_b => sub {
            $b_ok->table(shared => sub { $b_ok->column(id => sub { $b_ok->affinity('numeric') }) });
        });
    },
    "same table name in two different schemas is fine (separate registries)",
);

ok(
    lives {
        $b_ok->schema(with_alt => sub {
            $b_ok->table(t => sub {
                $b_ok->column(x => sub { $b_ok->affinity('string') });
                $b_ok->alt(v1 => sub { 1 });
                $b_ok->alt(v1 => sub { 1 });
            });
        });
    },
    "re-opening the same alt frame does not trip the redefine croak",
);

done_testing;
