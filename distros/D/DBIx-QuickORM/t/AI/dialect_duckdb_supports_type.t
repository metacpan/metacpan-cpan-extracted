use Test2::V0;

# DuckDB's supports_type must report native names for text and varchar so the
# documented supports_type('text') // 'TEXT' fallback that type modules rely on
# resolves to a real native type rather than undef.

BEGIN {
    skip_all "DBD::DuckDB is required for these tests"
        unless eval { require DBD::DuckDB; 1 };
}

require DBIx::QuickORM::Dialect::DuckDB;

my $dialect = bless {}, 'DBIx::QuickORM::Dialect::DuckDB';

is($dialect->supports_type('text'),    'TEXT',    "text maps to TEXT");
is($dialect->supports_type('varchar'), 'VARCHAR', "varchar maps to VARCHAR");
is($dialect->supports_type('TEXT'),    'TEXT',    "lookup is case-insensitive");

# Existing supported types still resolve.
is($dialect->supports_type('uuid'), 'UUID', "uuid still maps to UUID");
is($dialect->supports_type('nope'), undef,  "unknown type still returns undef");

done_testing;
