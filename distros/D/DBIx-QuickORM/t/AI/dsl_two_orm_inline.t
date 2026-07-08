use Test2::V0 '!meta', '!pass';

# Regression (adversarial review of the audit integration): the same-name
# redefinition croak must NOT fire when two ORMs in one package each declare a
# same-named inline db and schema (the documented synopsis pattern). An
# ORM-inline db/schema is captured by reference in the ORM's own meta and is
# never re-fetched by name, so it must not register into the package-shared
# registry.

ok(
    lives {
        package My::Test::TwoOrm;
        use DBIx::QuickORM;

        orm dev => sub {
            db mydb => sub {
                dialect 'SQLite';
                db_name 'main';
            };
            schema my_schema => sub {
                table t => sub {
                    column id => sub { primary_key; affinity 'numeric' };
                };
            };
        };

        orm prod => sub {
            db mydb => sub {
                dialect 'SQLite';
                db_name 'main';
            };
            schema my_schema => sub {
                table t => sub {
                    column id => sub { primary_key; affinity 'numeric' };
                };
            };
        };
    },
    "two ORMs each declaring a same-named inline db and schema do not croak",
) or note $@;

# A genuine top-level double definition of the same name still croaks.
like(
    dies {
        package My::Test::DoubleTable;
        use DBIx::QuickORM;
        schema dup => sub {
            table t => sub { column id => sub { primary_key; affinity 'numeric' } };
            table t => sub { column id => sub { primary_key; affinity 'numeric' } };
        };
    },
    qr/already (defined|been defined)/i,
    "a genuine same-name table redefinition in one schema still croaks",
);

done_testing;
