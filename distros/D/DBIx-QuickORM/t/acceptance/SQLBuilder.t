# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Source::Query;
use DBIx::QuickORM::Source::Table;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE nums (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(10))");
    $dbh->do("INSERT INTO nums (id, name) VALUES ($_, 'n$_')") for 1 .. 5;

    my $orm     = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $conn    = $orm->connection;
    my $dialect = $conn->dialect;
    my $b       = $orm->sql_builder;
    my $nums    = DBIx::QuickORM::Source::Table->new(table => 'nums', db_map => $orm->db_map);

    my $ids = sub { [map { $_->{id} } @{$conn->select($_[0], $b->select($_[0], $dialect, @_[1 .. $#_]))}] };
    my $run = sub {
        my ($sql, $binds) = @_;
        $dbh->do($sql, undef, map { $_->[1] } @$binds);
    };

    is($ids->($nums, order_by => 'id'),                                                [1 .. 5], "select with an order");
    is($ids->($nums, order_by => {-desc => 'id'}, limit => 2),                         [5, 4],   "limit");
    is($ids->($nums, order_by => 'id', limit => 2, offset => 1),                       [2, 3],   "limit and offset");
    is($ids->($nums, order_by => 'id', offset => 3),                                   [4, 5],   "an offset alone works on every backend");
    is($ids->($nums, where => {id => {'>' => 3}}, order_by => 'id', fields => ['id']), [4, 5],   "where and fields");

    my $query = DBIx::QuickORM::Source::Query->new(sql => 'SELECT id FROM nums WHERE id < ? ORDER BY id DESC', binds => [3]);
    is($ids->($query),                     [2, 1], "A query source runs as written");
    is($ids->($query, where => {id => 1}), [1],    "or as a subquery");

    my ($count) = values %{$conn->select($nums, $b->count($nums, $dialect, where => {id => {'<' => 3}}))->[0]};
    is($count, 2, "count");

    $run->($b->update($nums, $dialect, {name => 'big'}, where => {id => {'>' => 3}}));
    is($dbh->selectcol_arrayref("SELECT id FROM nums WHERE name = 'big' ORDER BY id"), [4, 5], "update");
    $run->($b->delete($nums, $dialect, where => {name => 'big'}));
    is($dbh->selectcol_arrayref("SELECT id FROM nums ORDER BY id"), [1, 2, 3], "delete");
};

done_testing;
