use Test2::V0;

# DuckDB generated-column detection parses the stored CREATE TABLE DDL. The
# bridge between a column name and its GENERATED clause must be paren-aware so
# it crosses a type modifier like DECIMAL(10,2) without stopping at the comma
# inside the parentheses, and string literals must be stripped so a DEFAULT
# 'GENERATED ALWAYS AS (...)' literal is not mistaken for a real generated
# column.

BEGIN {
    skip_all "DBD::DuckDB is required for these tests"
        unless eval { require DBD::DuckDB; 1 };
}

require DBIx::QuickORM::Dialect::DuckDB;

my $dialect = bless {}, 'DBIx::QuickORM::Dialect::DuckDB';

subtest comma_bearing_type => sub {
    # DuckDB renders GENERATED as `GENERATED ALWAYS AS((expr))`.
    my $ddl = 'CREATE TABLE t(amount DECIMAL(10,2) NOT NULL, '
        . 'total DECIMAL(10,2) GENERATED ALWAYS AS((amount * 2)))';

    my %gen = $dialect->_parse_generated($ddl);

    ok($gen{total},   "the generated column is detected across DECIMAL(10,2)");
    ok(!$gen{amount}, "the plain column is not flagged");
    ok(!$gen{2},      "the comma-inside-type digit is not mis-detected as a column");
};

subtest string_literal_default => sub {
    my $ddl = q{CREATE TABLE t(note VARCHAR DEFAULT('GENERATED ALWAYS AS (x)'))};

    my %gen = $dialect->_parse_generated($ddl);

    ok(!$gen{note}, "a GENERATED clause inside a string literal is not flagged");
    is([keys %gen], [], "no columns flagged for a DDL with only a string-literal match");
};

done_testing;
