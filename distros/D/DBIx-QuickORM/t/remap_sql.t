use Test2::V0;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::SQLBuilder::SQLAbstract;

# Verify the SQL builder emits database column names (never ORM names) for every
# translated surface: where-clauses (including nested logic and operators),
# order_by, select field lists, and insert data.

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $table = DBIx::QuickORM::Schema::Table->new(
    name    => 'example',
    columns => {
        my_id   => $C->new(name => 'my_id',   db_name => 'id',   order => 1, affinity => 'numeric'),
        my_name => $C->new(name => 'my_name', db_name => 'name', order => 2, affinity => 'string'),
    },
    primary_key => ['my_id'],
);

my $b = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;

subtest where => sub {
    my $sql = $b->qorm_where(
        source => $table,
        where  => {-or => [{my_id => {'>' => 5}}, {my_name => 'x'}]},
    );

    like($sql->{statement}, qr/\bid\b/,   "uses database name 'id'");
    like($sql->{statement}, qr/\bname\b/, "uses database name 'name'");
    unlike($sql->{statement}, qr/my_/, "no ORM names leak into the where-clause");
};

subtest select => sub {
    my $sql = $b->qorm_select(
        source   => $table,
        fields   => ['my_id', 'my_name'],
        where    => {my_id => 1},
        order_by => {-desc => 'my_name'},
    );

    like($sql->{statement}, qr/\bid\b/,        "field list / where use database names");
    like($sql->{statement}, qr/name\b.*DESC/i, "order_by uses the database name");
    unlike($sql->{statement}, qr/my_/, "no ORM names leak into the select");
};

subtest insert => sub {
    my $sql = $b->qorm_insert(
        source => $table,
        insert => {my_id => 1, my_name => 'a'},
    );

    like($sql->{statement}, qr/\bid\b/,   "insert column 'id'");
    like($sql->{statement}, qr/\bname\b/, "insert column 'name'");
    unlike($sql->{statement}, qr/my_/, "no ORM names leak into the insert");
};

subtest literal_sql_untouched => sub {
    my $sql = $b->qorm_where(
        source => $table,
        where  => \'my_id = 1',
    );

    like($sql->{statement}, qr/my_id = 1/, "caller's literal SQL is left untouched");
};

done_testing;
