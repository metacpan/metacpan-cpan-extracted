use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;
use Scalar::Util qw/refaddr/;

# Exercises the handle BUILDER (not the terminal fetches covered by
# t/handle/*): immutability of refiners, void-context croaks, the
# argument-shape parsing of $con->handle(...), and the where/and/or,
# order_by, limit, fields, omit, all_fields, and data_only refiners. The
# connection shortcut proxies (all/one/count/by_id/insert/update/delete)
# are also exercised to confirm they build a handle and run it.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/handle_builder.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE people (id INTEGER PRIMARY KEY, surname TEXT, first_name TEXT, bio TEXT)');
    $dbh->do(
        "INSERT INTO people (surname, first_name, bio) VALUES "
        . "('smith', 'al', 'x'), ('jones', 'bob', 'y'), ('smith', 'cy', 'z')"
    );
    $dbh->disconnect;
}

my $con  = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $base = $con->handle('people');

isa_ok($base, ['DBIx::QuickORM::Handle'], "got a handle for the people table");

subtest immutability => sub {
    my $smiths = $base->where({surname => 'smith'});
    my $jones  = $base->where({surname => 'jones'});

    isnt(refaddr($smiths), refaddr($base), "where() returns a new handle, not the original");
    isnt(refaddr($jones),  refaddr($base), "a second where() returns yet another new handle");
    isnt(refaddr($smiths), refaddr($jones), "the two derived handles are distinct objects");

    is($base->where,   undef,                "base handle WHERE is untouched");
    is($smiths->where, {surname => 'smith'},  "first derived handle has its own WHERE");
    is($jones->where,  {surname => 'jones'},  "second derived handle has its own WHERE");

    # Refiners that need a WHERE/row to be present first operate on a
    # handle that already has one.
    my $w = $base->where({});

    isnt(refaddr($w->order_by(['surname'])), refaddr($w), "order_by() returns a new handle");
    isnt(refaddr($w->limit(5)),              refaddr($w), "limit() returns a new handle");
    isnt(refaddr($base->fields(['id'])),     refaddr($base), "fields() returns a new handle");
    isnt(refaddr($base->omit(['bio'])),      refaddr($base), "omit() returns a new handle");
    isnt(refaddr($base->all_fields),         refaddr($base), "all_fields() returns a new handle");
    isnt(refaddr($base->data_only),          refaddr($base), "data_only() returns a new handle");
    isnt(
        refaddr($base->where({surname => 'smith'})->and({first_name => 'al'})),
        refaddr($base), "and() returns a new handle",
    );
    isnt(
        refaddr($base->where({surname => 'smith'})->or({surname => 'jones'})),
        refaddr($base), "or() returns a new handle",
    );

    is($w->order_by, undef, "order_by on the source handle is still unset");
    is($w->limit,    undef, "limit on the source handle is still unset");
};

subtest void_context_croak => sub {
    # Refiners whose entire point is the returned value croak in void context.
    like(dies { $base->where({surname => 'smith'}); 1 },
        qr/Must not be called in void context/, "where() croaks in void context");

    my $w = $base->where({});
    like(dies { $w->order_by(['surname']); 1 },
        qr/Must not be called in void context/, "order_by() croaks in void context");
    like(dies { $w->limit(5); 1 },
        qr/Must not be called in void context/, "limit() croaks in void context");
    like(dies { $base->fields(['id']); 1 },
        qr/Must not be called in void context/, "fields() croaks in void context");
    like(dies { $base->omit(['bio']); 1 },
        qr/Must not be called in void context/, "omit() croaks in void context");
    like(dies { $base->data_only; 1 },
        qr/Must not be called in void context/, "data_only() croaks in void context");
    like(dies { $base->all_fields; 1 },
        qr/Must not be called in void context/, "all_fields() croaks in void context");
    like(dies { $base->sync; 1 },
        qr/Must not be called in void context/, "sync() croaks in void context");
};

subtest argument_shape_parsing => sub {
    # Bare string => source name.
    my $by_name = $con->handle('people');
    is($by_name->source->source_db_moniker, 'people', "bare string is treated as a source name");

    # Hashref => where.
    my $by_hash = $con->handle('people', {surname => 'smith'});
    is($by_hash->where, {surname => 'smith'}, "hashref argument becomes the WHERE clause");

    # A table name BEFORE the connection still resolves (resolution is
    # deferred until all arguments are consumed).
    require DBIx::QuickORM::Handle;
    my $reversed = DBIx::QuickORM::Handle->new('people', $con);
    is($reversed->source->source_db_moniker, 'people', "table-name positional before the connection resolves");

    like(
        dies { DBIx::QuickORM::Handle->new('people') },
        qr/Cannot resolve 'people' as a table name without a connection/,
        "a table name with no connection croaks cleanly"
    );

    like(
        dies { $con->handle('people', undef) },
        qr/Received an undefined argument/,
        "an undef argument croaks instead of silently ending argument parsing"
    );

    # A falsy-but-defined argument ('0') does not end argument parsing.
    my $zero = $con->handle('people', 0, {surname => 'smith'});
    is($zero->limit, 0, "a falsy integer argument is still parsed (limit 0)");
    is($zero->where, {surname => 'smith'}, "arguments after a falsy argument are still parsed");

    # Arrayref => order_by.
    my $by_array = $con->handle('people', {}, ['first_name']);
    is($by_array->order_by, ['first_name'], "arrayref argument becomes the ORDER BY");

    # Integer => limit.
    my $by_int = $con->handle('people', {}, 10);
    is($by_int->limit, 10, "integer argument becomes the LIMIT");

    # Equivalence shown in the manual: positional args vs chained refiners.
    # order_by('first_name') stores a scalar while the positional arrayref
    # form stores ['first_name']; both are accepted shapes, so chain with the
    # matching arrayref to compare the stored state directly.
    my $positional = $con->handle('people', {surname => 'smith'}, ['first_name'], 10);
    my $chained    = $con->handle('people')->where({surname => 'smith'})->order_by(['first_name'])->limit(10);

    is($positional->where,    $chained->where,    "positional WHERE matches chained WHERE");
    is($positional->order_by, $chained->order_by, "positional ORDER BY matches chained ORDER BY");
    is($positional->limit,    $chained->limit,    "positional LIMIT matches chained LIMIT");

    # The scalar and arrayref order_by forms produce the same ordered result.
    my @scalar_order = map { $_->{first_name} }
        $con->handle('people', {})->order_by('first_name')->data_only->all;
    my @array_order = map { $_->{first_name} }
        $con->handle('people', {})->order_by(['first_name'])->data_only->all;
    is(\@scalar_order, \@array_order, "scalar and arrayref order_by yield the same ordering");
};

subtest where_and_or => sub {
    my $smiths = $base->where({surname => 'smith'});

    my $and = $smiths->and({first_name => 'al'});
    is(
        $and->where,
        {-and => [{surname => 'smith'}, {first_name => 'al'}]},
        "and() combines the existing WHERE with the new condition under -and",
    );

    my $or = $smiths->or({surname => 'jones'});
    is(
        $or->where,
        {-or => [{surname => 'smith'}, {surname => 'jones'}]},
        "or() combines the existing WHERE with the new condition under -or",
    );

    # Combined clauses actually filter the right rows when run.
    is($smiths->count, 2, "two smiths match the base WHERE");
    is($and->count,    1, "the AND-combined handle narrows to one row");
    is($or->count,     3, "the OR-combined handle matches all three rows");
};

subtest order_by_shapes => sub {
    my $w = $base->where({});

    is($w->order_by('surname')->order_by, 'surname', "order_by accepts a single scalar");
    is($w->order_by('surname', 'first_name')->order_by, ['surname', 'first_name'],
        "order_by accepts a list and wraps it in an arrayref");
    is($w->order_by(['surname', 'first_name'])->order_by, ['surname', 'first_name'],
        "order_by accepts an arrayref verbatim");

    # Plain SELECT ... ORDER BY (no WHERE) is legal.
    is(
        [map { $_->{first_name} } $base->order_by('first_name')->data_only->all],
        ['al', 'bob', 'cy'],
        "order_by without a WHERE sorts the whole table"
    );
};

subtest limit => sub {
    my $w = $base->where({});
    is($w->limit(2)->limit, 2, "limit stores the integer");
    is(scalar($w->limit(2)->data_only->all), 2, "limit actually caps the row count");

    # Plain SELECT ... LIMIT (no WHERE) is legal, alone and with ORDER BY.
    is(scalar($base->limit(2)->data_only->all), 2, "limit without a WHERE caps the row count");

    # LIMIT 0 is a real limit, not "no limit".
    is($base->limit(0)->limit, 0, "limit(0) is stored");
    is([$base->limit(0)->data_only->all], [], "limit(0) returns zero rows");
    is(
        [map { $_->{first_name} } $base->order_by('first_name')->limit(2)->data_only->all],
        ['al', 'bob'],
        "order_by + limit without a WHERE work together"
    );
};

subtest fields => sub {
    # fields(\@) replaces the field set wholesale.
    is($base->fields(['id', 'surname'])->fields, ['id', 'surname'],
        "fields(\\\@) replaces the field list");

    # The bare-list form is additive: it appends to the current set.
    my $default = $base->fields;
    my $added   = $base->fields('first_name')->fields;
    is(scalar(@$added), scalar(@$default) + 1, "bare-list fields() appends to the existing set");
    ok((grep { $_ eq 'first_name' } @$added), "the appended field is present");
};

subtest omit => sub {
    my $omitted = $base->omit(['bio']);

    is($omitted->omit, {bio => 1}, "omit normalizes an arrayref to a seen-hash");
    ok(!(grep { $_ eq 'bio' } @{$omitted->fields}), "the omitted field is dropped from fields");
    ok((grep { $_ eq 'id' } @{$omitted->fields}), "the primary key is still fetched");

    my $appended = $omitted->omit('first_name');
    is($appended->omit, {bio => 1, first_name => 1}, "additive omit() appends to an already-normalized omit set");
    ok(!(grep { $_ eq 'first_name' } @{$appended->fields}), "the appended omit field is dropped from fields");

    # Primary key fields cannot be omitted.
    like(dies { my $h = $base->omit(['id']) },
        qr/Cannot omit primary key field 'id'/,
        "omitting a primary key field croaks");
};

subtest all_fields => sub {
    is(
        [sort @{$base->all_fields->fields}],
        [sort @{$con->handle('people')->source->fields_list_all}],
        "all_fields selects the source's full field list",
    );

    my $full = $base->omit(['bio'])->all_fields;
    is($full->omit, undef, "all_fields clears an existing omit set");
    ok((grep { $_ eq 'bio' } @{$full->fields}), "all_fields restores an omitted field");
};

subtest data_only => sub {
    my @rows = $base->data_only->all;
    is(scalar(@rows), 3, "data_only handle still fetches every row");
    ref_ok($rows[0], 'HASH', "data_only yields plain hashrefs, not blessed rows");
};

subtest by_id_errors => sub {
    like(
        dies { $base->where({surname => 'smith'})->by_id(1) },
        qr/Cannot call by_id\(\) on a handle with a where clause/,
        "by_id() error message names by_id, not by_ids"
    );

    my ($db_dir) = tempdir(CLEANUP => 1);
    my $nopk_dsn = "dbi:SQLite:dbname=$db_dir/nopk.sqlite";
    {
        my $dbh = DBI->connect($nopk_dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE nopk (name TEXT)');
        $dbh->disconnect;
    }
    my $nopk_con = DBIx::QuickORM->quick(credentials => {dsn => $nopk_dsn});

    like(
        dies { $nopk_con->handle('nopk')->by_id(1) },
        qr/Cannot call by_id\(\) on a source that has no primary key/,
        "by_id() on a pk-less source croaks instead of dereferencing undef"
    );
};

subtest internal_transactions => sub {
    ok($base->using_internal_transactions, "internal transactions default to on");

    my $off = $base->no_internal_txns;
    isnt(refaddr($off), refaddr($base), "no_internal_txns() returns a new handle");
    ok(!$off->using_internal_transactions, "internal transactions are off on the new handle");
    ok($base->using_internal_transactions, "the original handle is unchanged");

    my $on = $off->internal_txns;
    isnt(refaddr($on), refaddr($off), "internal_txns() returns a new handle");
    ok($on->using_internal_transactions, "internal transactions are on again on the new handle");
    ok(!$off->using_internal_transactions, "the intermediate handle is unchanged");

    ok(!$base->internal_transactions(0)->using_internal_transactions, "internal_transactions(0) turns them off");
    ok($off->no_internal_transactions(0)->using_internal_transactions, "no_internal_transactions(0) turns them on");

    like(dies { $base->internal_txns; 1 },
        qr/Must not be called in void context/, "internal_txns() croaks in void context");
    like(dies { $base->no_internal_txns; 1 },
        qr/Must not be called in void context/, "no_internal_txns() croaks in void context");
};

subtest connection_shortcuts => sub {
    # Each shortcut is just $con->handle(@args)->METHOD(...).
    is(scalar($con->all('people')), 3, "all() proxies through a handle");
    is($con->count('people'), 3, "count() proxies through a handle");
    is($con->count('people' => {surname => 'smith'}), 2, "count() honors an inline WHERE");

    my $one = $con->one('people' => {first_name => 'al'});
    is($one->field('surname'), 'smith', "one() proxies and returns the matching row");

    my $by_id = $con->by_id('people' => 1);
    is($by_id->field('id'), 1, "by_id() proxies and fetches by primary key");

    my $new = $con->insert('people' => {surname => 'doe', first_name => 'di'});
    ok($new->field('id'), "insert() proxies and returns a row with a generated id");
    is($con->count('people'), 4, "insert() actually wrote a row");

    $con->update('people' => {first_name => 'di'} => {bio => 'updated'});
    is($con->one('people' => {first_name => 'di'})->field('bio'), 'updated',
        "update() proxies and applies the changes");

    $con->delete('people' => {first_name => 'di'});
    is($con->count('people'), 3, "delete() proxies and removes the row");
};

done_testing;
