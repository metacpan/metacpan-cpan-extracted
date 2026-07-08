use Test2::V0 '!meta', '!pass';
use File::Temp qw/tempdir/;
use DBI;
use DBIx::QuickORM;

# A handle can be used as the source of another query: it is spliced in as a
# derived table ( <inner query> ) AS <alias>, with its binds threaded into the
# outer statement and its real columns keeping their types.

my $dir    = tempdir(CLEANUP => 1);
my $dbfile = "$dir/sq.db";

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE events (id INTEGER PRIMARY KEY, kind TEXT, ts INTEGER)');
    $dbh->do("INSERT INTO events (id, kind, ts) VALUES (1,'click',10),(2,'view',20),(3,'click',30),(4,'click',40)");
    $dbh->disconnect;
}

db mydb => sub {
    dialect 'SQLite';
    db_name 'main';
    connect sub { DBI->connect("dbi:SQLite:dbname=$dbfile", '', '', {RaiseError => 1, PrintError => 0}) };
};

orm my_orm => sub {
    db 'mydb';
    autofill;
};

my $con = orm('my_orm')->connect;

subtest round_trip_and_bind_order => sub {
    my $sub = $con->handle('events')->where({ts => {'>' => 15}})->subquery_alias('recent');

    isa_ok($sub, ['DBIx::QuickORM::Handle'], "subquery_alias returns a handle");
    ok($sub->DOES('DBIx::QuickORM::Role::Source'), "the handle is usable as a source");

    my $outer = $con->handle($sub)->where({kind => 'click'})->order_by('id');

    my $sql = $outer->sql_builder->qorm_select(%{$outer->_builder_args});
    like($sql->{statement}, qr/FROM \( SELECT .* FROM events WHERE "ts" > \? \) AS recent/,
        "inner query is spliced in as a derived table");
    is(
        [map { $_->{value} } @{$sql->{bind}}],
        [15, 'click'],
        "inner WHERE bind is threaded ahead of the outer WHERE bind",
    );

    my @rows = $outer->all;
    is([map { $_->field('id') } @rows], [3, 4],
        "outer WHERE filters the subquery result (inner ts>15 then outer kind=click)");
};

subtest typed_real_column => sub {
    my $sub  = $con->handle('events')->where({kind => 'click'})->subquery_alias('c');
    my @rows = $con->handle($sub)->order_by('id')->all;

    isa_ok($rows[0], ['DBIx::QuickORM::Row'], "rows from a subquery are Row objects");
    # ts is a real inner column; its value comes through inflated by the inner
    # source's metadata (here a plain integer).
    is($rows[0]->field('ts'), 10, "a real column is fetched through the subquery");
    is([map { $_->field('id') } @rows], [1, 3, 4], "all matching rows returned");
};

subtest computed_column_is_untyped_but_accessible => sub {
    my $sub  = $con->handle('events')->fields(['id', \'ts * 2 AS doubled'])->where({kind => 'click'})->subquery_alias('c');
    my @rows = $con->handle($sub)->order_by('id')->all;

    is($rows[0]->field('id'), 1, "selected real column is accessible");
    is($rows[0]->field('doubled'), 20, "computed column is accessible (untyped, raw value)");
    is($rows[1]->field('doubled'), 60, "computed column for the second row");
};

subtest limit_inside_subquery => sub {
    my $sub  = $con->handle('events')->order_by('id')->limit(2)->subquery_alias('lim');
    my @rows = $con->handle($sub)->order_by('id')->all;
    is([map { $_->field('id') } @rows], [1, 2], "a LIMIT inside the subquery is honored");
};

subtest default_vs_explicit_alias => sub {
    my $def = $con->handle('events')->where({kind => 'view'});
    like(${$def->source_db_moniker}->[0], qr/\) AS subquery$/, "alias defaults to 'subquery'");
    is($def->subquery_alias, undef, "an unset subquery_alias reads back as undef");

    my $named = $con->handle('events')->where({kind => 'view'})->subquery_alias('vee');
    like(${$named->source_db_moniker}->[0], qr/\) AS vee$/, "explicit alias is used");
    is($named->subquery_alias, 'vee', "subquery_alias() reads back the explicit alias");
};

subtest nested_subquery => sub {
    my $inner = $con->handle('events')->where({ts => {'>' => 15}})->subquery_alias('a');
    my $mid   = $con->handle($inner)->where({kind => 'click'})->subquery_alias('b');
    my @rows  = $con->handle($mid)->order_by('id')->all;
    is([map { $_->field('id') } @rows], [3, 4], "a subquery can itself wrap another subquery");
};

subtest plain_handle_is_used_as_source => sub {
    # A handle passed to handle() is spliced in as a subquery source even
    # without naming it; the derived-table alias defaults to 'subquery'.
    my $h     = $con->handle('events')->where({kind => 'click'});
    my $outer = $con->handle($h);

    ref_is_not($outer, $h, "passing a handle to handle() builds a new handle around it, not the same object");

    my $sql = $outer->sql_builder->qorm_select(%{$outer->_builder_args});
    like($sql->{statement}, qr/FROM \( SELECT .* FROM events WHERE "kind" = \? \) AS subquery/,
        "an unmarked handle is wrapped as a derived table aliased 'subquery'");

    is([map { $_->field('id') } $outer->order_by('id')->all], [1, 3, 4],
        "the wrapped handle queries through the subquery");
};

subtest handle_with_where_filters_the_subquery => sub {
    # handle($h, where => X) wraps $h as a subquery and applies X as an OUTER
    # filter; it does NOT refine $h's own WHERE.
    my $inner = $con->handle('events')->where({ts => {'>' => 15}});

    my @rows = $con->handle($inner, where => {kind => 'click'})->order_by('id')->all;
    is([map { $_->field('id') } @rows], [3, 4],
        "the where filters the subquery result (inner ts>15 then outer kind=click)");

    # Refining without wrapping is done on the handle directly, and is
    # non-mutating: it returns a clone and leaves the original alone.
    my $refined = $inner->where({kind => 'click'});
    ref_is_not($refined, $inner, "where() returns a refined clone, not the same object");

    my $rsql = $refined->sql_builder->qorm_select(%{$refined->_builder_args});
    unlike($rsql->{statement}, qr/FROM \(/, "a refined handle queries the table directly, not a subquery");

    is([map { $_->field('id') } $refined->order_by('id')->all], [1, 3, 4],
        "the refined clone's WHERE replaced the original's (kind=click, no ts filter)");
    is([map { $_->field('id') } $inner->order_by('id')->all], [2, 3, 4],
        "the original handle is unchanged (still ts>15)");
};

done_testing;
