# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::LookupTable;
use DBIx::QuickORM::Map;

my $MAP = DBIx::QuickORM::Map->new(tables => {users => {pk => ['id']}, pairs => {pk => ['a', 'b']}, nopk => {pk => undef}});

sub lookup {
    DBIx::QuickORM::LookupTable->new(db_map => $MAP, @_);
}

subtest construction => sub {
    like(dies { DBIx::QuickORM::LookupTable->new }, qr/^'db_map' is required/, "db_map is required");
    my $lt = lookup();
    is($lt->stack,  [{}], "Starts with one empty level");
    is($lt->in_txn, 0,    "Not in a transaction");
};

subtest keys => sub {
    my $lt = lookup(retain => 1);

    my $row = $lt->store(users => {id => 1, name => 'bob'});
    ref_is($lt->lookup(users => {id => 1}),                  $row, "Keys are the key-field hash");
    ref_is($lt->lookup(users => {id => '1'}),                $row, "Stringified pk matches");
    ref_is($lt->lookup(users => {id => 1, name => 'other'}), $row, "The hash may hold other fields, so row data works");
    is($lt->lookup(users => {id => 2}), undef, "Miss");

    my $p1 = $lt->store(pairs => {a => 'x:', b => 'y'});
    my $p2 = $lt->store(pairs => {a => 'x',  b => ':y'});
    ref_is($lt->lookup(pairs => {a => 'x:', b => 'y'}),  $p1, "Compound key");
    ref_is($lt->lookup(pairs => {a => 'x',  b => ':y'}), $p2, "Length prefix keeps similar keys apart");
    is([sort keys %{$lt->stack->[0]->{pairs}}], ['1:x2::y', '2:x:1:y'], "Compound key format");

    like(dies { $lt->store(users => {id => bless({}, 'Some::Value')}) }, qr/^The primary key field 'id' of the table 'users' has no type, so its value cannot be a reference/, "A reference on an untyped key field croaks");

    like(dies { $lt->lookup(nopk => {id => 1}) },      qr/^The table 'nopk' has no primary key/,                                     "No pk croaks");
    like(dies { $lt->lookup(users => {id => undef}) }, qr/^The primary key field 'id' of the table 'users' is missing or undefined/, "Undef croaks");
    like(dies { $lt->lookup(users => {name => 'x'}) }, qr/^The primary key field 'id' of the table 'users' is missing/,              "Missing field croaks");
    like(dies { $lt->is_canon(pairs => {a => 1}) },    qr/^The primary key field 'b' of the table 'pairs' is missing/,               "is_canon croaks without pk");
    like(dies { $lt->clear(nopk => {}) },              qr/^The table 'nopk' has no primary key/,                                     "Clearing a row croaks without a pk");
};

{

    package My::Key::Type;
    our @CALLS;
    sub canonical_key_value { my ($class, $value, $field, $conn) = @_; push @CALLS => [$value, $field, $conn]; lc $value }
}

subtest typed_keys => sub {
    my $map = DBIx::QuickORM::Map->new(
        tables => {
            tags  => {pk => ['name'],     pk_types => ['My::Key::Type'], fields => {name => {type => 'text'}}},
            links => {pk => ['tag', 'n'], pk_types => ['My::Key::Type', undef], fields => {tag => {type => 'text'}, n => {type => 'int'}}},
            plain => {pk => ['id'], fields => {id => {}, note => {orm_type => 'My::Key::Type'}}},
        },
    );
    my $conn = bless {}, 'Some::Connection';
    my $lt   = DBIx::QuickORM::LookupTable->new(db_map => $map, connection => $conn, retain => 1);

    my $tag = $lt->store(tags => {name => 'Perl'});
    ref_is($lt->lookup(tags => {name => 'PERL'}), $tag, "A typed key field is keyed by its type's canonical_key_value");
    is([keys %{$lt->stack->[0]->{tags}}], ['perl'],                                     "which gives the key string");
    is($My::Key::Type::CALLS[0],          ['Perl', $map->field(tags => 'name'), $conn], "The type gets the value, the field record, and the connection");

    my $link = $lt->store(links => {tag => 'Perl', n => 1});
    ref_is($lt->lookup(links => {tag => 'perl', n => 1}), $link, "In a compound key only the typed field goes through the type");

    @My::Key::Type::CALLS = ();
    my $row = $lt->store(plain => {id => 1, note => 'X'});
    ref_is($lt->lookup(plain => {id => 1}), $row, "An untyped key works as before");
    is(\@My::Key::Type::CALLS, [], "without calling any type, even one on another field");
};

subtest canon => sub {
    my $lt  = lookup(retain => 1);
    my $row = $lt->store(users => {id => 1});
    ok($lt->is_canon(users  => $row), "Same ref is canon");
    ok(!$lt->is_canon(users => {id => 1}), "Equal copy is not canon");
    ok(!$lt->is_canon(users => {id => 2}), "No entry is not canon");
};

subtest differ => sub {
    my $LT = 'DBIx::QuickORM::LookupTable';
    ok(!$LT->differ(undef, undef), "NULL equals NULL");
    ok($LT->differ(undef,  ''),    "NULL differs from an empty string");
    ok($LT->differ('0',    undef), "A value differs from NULL");
    ok(!$LT->differ(1,     '1'),   "Equal as strings do not differ");
    ok($LT->differ('1.0',  1),     "Values unequal as strings differ, even when numerically equal");
    ok($LT->differ('a',    'b'),   "Different strings differ");
    ok(!lookup()->differ('x', 'x'), "Callable on an instance");
};

subtest ingest => sub {
    my $lt = lookup(retain => 1);

    my $first = {id => 1, name => 'bob', age => undef};
    ref_is($lt->ingest(users => $first), $first, "No entry stores the given hash");
    ref_is($lt->ingest(users => $first), $first, "Ingesting canon returns it");

    my $got = $lt->ingest(users => {id => '1', email => 'b@x', age => undef});
    ref_is($got, $first, "No difference keeps the canon hash");
    is($first, {id => 1, name => 'bob', age => undef, email => 'b@x'}, "New fields added in place");

    my $new = {id => 1, name => 'robert'};
    ref_is($lt->ingest(users => $new), $new, "A difference replaces the entry");
    is($new, {id => 1, name => 'robert'}, "Replacement holds only fetched fields");
    ok(!$lt->is_canon(users => $first), "Old hash is no longer canon");

    my $null = {id => 1, name => undef};
    ref_is($lt->ingest(users => $null), $null, "NULL differs from a value");
    my $val = {id => 1, name => ''};
    ref_is($lt->ingest(users => $val), $val, "A value differs from NULL");
};

subtest writes => sub {
    my $lt  = lookup(retain => 1);
    my $old = $lt->store(users => {id => 1, name => 'a'});
    my $new = $lt->store(users => {id => 1, name => 'a'});
    ok($lt->is_canon(users => $new) && !$lt->is_canon(users => $old), "store replaces without comparing");

    $lt->clear(users => {id => 1});
    $new->{id} = 2;
    $lt->store(users => $new);
    is($lt->lookup(users => {id => 1}), undef, "Old key gone after re-key");
    ref_is($lt->lookup(users => {id => 2}), $new, "New key holds the row");

    $lt->clear(users => {id => 2});
    is($lt->lookup(users => {id => 2}), undef, "Clearing a row deletes the entry");
    ok(lives { $lt->clear(pairs => {a => 1, b => 1}) }, "Clearing a row in a table with no entries is a no-op");

    my $pair = $lt->store(pairs => {a => 1, b => 2});
    $lt->clear(pairs => {a => 1, b => 2});
    is($lt->lookup(pairs => {a => 1, b => 2}), undef, "clear takes a compound key");
    $lt->store(pairs => $pair);
    $lt->forget(pairs => {a => 1, b => 2});
    is($lt->lookup(pairs => {a => 1, b => 2}), undef, "and so does forget");
};

subtest weak_outside => sub {
    my $lt = lookup();
    {
        my $row = $lt->store(users => {id => 1});
        ref_is($lt->lookup(users => {id => 1}), $row, "Held while referenced");
    }
    ok(exists $lt->stack->[0]->{users}->{1}, "Freed slot still present");
    is($lt->lookup(users => {id => 1}), undef, "Freed slot reads as a miss");
    ok(!exists $lt->stack->[0]->{users}->{1}, "Freed slot deleted when met");

    my $lr = lookup(retain => 1);
    $lr->store(users => {id => 1});
    is($lr->lookup(users => {id => 1}), {id => 1}, "retain keeps unreferenced rows");
};

subtest levels => sub {
    my $lt      = lookup();
    my $outside = $lt->store(users => {id => 9});
    $lt->begin_root;
    is($lt->lookup(users => {id => 9}), undef, "Rows from before the root are not canon inside it");
    $lt->rollback_level;

    $lt->begin_root;
    ok($lt->in_txn, "In a transaction");
    is(scalar @{$lt->stack}, 2,  "Root begin pushes a level above the outside one");
    is($lt->stack->[-1],     {}, "The root level starts empty");
    like(dies { $lt->begin_root }, qr/^A transaction is already open/, "No nested root");

    $lt->store(users => {id => 1});
    is($lt->lookup(users => {id => 1}), {id => 1}, "Strong inside a transaction");
    my $one = $lt->lookup(users => {id => 1});

    $lt->push_level;
    is(scalar @{$lt->stack}, 3, "Savepoint pushes a level");
    ref_is($lt->lookup(users => {id => 1}), $one, "Parent's canon rows are canon in the child");
    $lt->store(users => {id => 2});
    $lt->clear(users => {id => 1});
    $lt->rollback_level;
    ref_is($lt->lookup(users => {id => 1}), $one, "Rollback restores a cleared entry");
    is($lt->lookup(users => {id => 2}), undef, "Rollback drops the child's entries");

    $lt->push_level;
    $lt->store(users => {id => 3});
    $lt->clear;
    $lt->store(users => {id => 4});
    $lt->commit_level;
    is(scalar @{$lt->stack}, 2, "Savepoint commit pops");
    is($lt->lookup(users => {id => 1}), undef,     "Commit keeps the child's clear");
    is($lt->lookup(users => {id => 4}), {id => 4}, "Commit keeps the child's entries");

    my $held = $lt->lookup(users => {id => 4});
    $lt->commit_level;
    ok(!$lt->in_txn, "Root commit ends the transaction");
    is(scalar @{$lt->stack}, 1, "Root commit pops");
    ref_is($lt->lookup(users => {id => 4}), $held, "Root commit merges its level outside");
    $held = undef;
    is($lt->lookup(users => {id => 4}), undef, "Root commit weakens what it merges");

    $lt->begin_root;
    $lt->store(users => {id => 5});
    $lt->rollback_level;
    ok(!$lt->in_txn, "Root rollback ends the transaction");
    is(scalar @{$lt->stack},            1,     "Root rollback pops");
    is($lt->lookup(users => {id => 5}), undef, "Root rollback drops the transaction's entries");

    like(dies { $lt->commit_level },   qr/^No transaction is open/, "commit outside a transaction croaks");
    like(dies { $lt->rollback_level }, qr/^No transaction is open/, "rollback outside a transaction croaks");
    like(dies { $lt->push_level },     qr/^No transaction is open/, "push outside a transaction croaks");

    my $lr = lookup(retain => 1);
    $lr->begin_root;
    $lr->store(users => {id => 1});
    $lr->commit_level;
    is($lr->lookup(users => {id => 1}), {id => 1}, "retain keeps the committed level strong");
};

subtest clear => sub {
    my $lt = lookup(retain => 1);
    $lt->store(users => {id => $_}) for 1 .. 3;
    $lt->store(pairs => {a  => 1, b => 2});

    $lt->clear(users => {id => 1});
    is($lt->lookup(users => {id => 1}), undef, "Clear one row");
    $lt->clear(users => {id => 2});
    is($lt->lookup(users => {id => 2}), undef, "Clear one row by hash");
    ok($lt->lookup(users => {id => 3}), "Other rows stay");

    $lt->clear('users');
    is($lt->lookup(users => {id => 3}), undef, "Clear one table");
    ok($lt->lookup(pairs => {a  => 1, b => 2}), "Other tables stay");

    $lt->clear;
    is($lt->stack, [{}], "Clear everything");

    $lt->begin_root;
    $lt->store(users => {id => 1});
    $lt->push_level;
    $lt->clear;
    is($lt->lookup(users => {id => 1}), undef, "Clear inside a savepoint empties the top");
    $lt->rollback_level;
    is($lt->lookup(users => {id => 1}), {id => 1}, "Rollback restores the parent's entries");
};

subtest layering => sub {
    my $lt   = lookup();
    my $kept = $lt->store(users => {id => 1, name => 'a'});

    $lt->begin_root;
    ok(!$lt->is_canon(users => $kept), "A pre-transaction row is not canon inside it");
    $lt->store(users => {id => 2});
    $lt->commit_level;
    ok($lt->is_canon(users => $kept), "An untouched pre-transaction row is canon again after commit");

    $lt->begin_root;
    $lt->store(users => {id => 3});
    $lt->rollback_level;
    ok($lt->is_canon(users => $kept), "and after rollback");
    is($lt->lookup(users => {id => 3}), undef, "Rollback drops the transaction's rows");
};

subtest touch => sub {
    my $lt  = lookup(retain => 1);
    my $old = $lt->store(users => {id => 1, name => 'a'});
    $lt->store(users => {id => $_}) for 2 .. 4;
    $lt->store(pairs => {a  => 1, b => 2});
    my $outside = $lt->stack->[0];

    $lt->begin_root;
    my $new = $lt->store(users => {id => 1, name => 'b'});
    ok(!exists $outside->{users}->{1}, "A store inside a transaction removes the key from the outside level");
    $lt->forget(users => {id => 2});
    ok(!exists $outside->{users}->{2}, "So does forgetting a row");
    $lt->clear(users => {id => 3});
    ok(exists $outside->{users}->{3}, "A plain clear leaves the outside level alone");
    $lt->clear;
    ok(exists $outside->{users}->{4}, "even of everything");
    $lt->forget('pairs');
    ok(!exists $outside->{pairs}, "Forgetting a table removes it from the outside level");

    $lt->push_level;
    $lt->store(users => {id => 4});
    ok(!exists $outside->{users}->{4}, "A store in a savepoint touches the outside level too");
    $lt->rollback_level;

    $lt->store(users => $new);
    $lt->commit_level;
    ok(!$lt->is_canon(users => $old), "The old object of a row updated in the transaction is not canon after commit");
    ref_is($lt->lookup(users => {id => 1}), $new, "The transaction's row replaces it");
    is($lt->lookup(users => {id => 4}), undef, "A key touched only in a rolled back savepoint stays removed");

    $lt->begin_root;
    $lt->forget;
    is($lt->stack, [{}, {}], "Forgetting everything inside a transaction empties the outside level too");
    $lt->commit_level;
    is($lt->stack, [{}], "and the commit brings nothing back");

    my $lo = lookup();
    $lo->store(users => {id => 1});
    $lo->forget(users => {id => 1});
    is($lo->lookup(users => {id => 1}), undef, "Outside a transaction forget clears the row");
};

subtest verified_reuse => sub {
    my $lt  = lookup();
    my $pre = $lt->store(users => {id => 1, name => 'a'});
    my $chg = $lt->store(users => {id => 2, name => 'a'});

    $lt->begin_root;
    ref_is($lt->ingest(users => {id => 1, name => 'a', age => 5}), $pre, "Reading identical data inside the transaction reuses the outside hash");
    is($pre, {id => 1, name => 'a', age => 5}, "adding the new fields in place");
    ok($lt->is_canon(users => $pre), "The pre-transaction row is canon inside it");
    ref_is($lt->stack->[0]->{users}->{1}, $pre, "and the outside level keeps it");

    my $got = {id => 2, name => 'b'};
    ref_is($lt->ingest(users => $got), $got, "Reading different data stores a new hash");
    ok(!$lt->is_canon(users => $chg),         "the old one is not canon");
    ok(!exists $lt->stack->[0]->{users}->{2}, "and the outside entry is removed");

    $lt->commit_level;
    ok($lt->is_canon(users => $pre), "The reused row is canon after commit");

    $lt->begin_root;
    $lt->ingest(users => {id => 1, name => 'a'});
    $lt->rollback_level;
    ok($lt->is_canon(users => $pre), "and after a rollback");

    my $deep = $lt->store(users => {id => 3, name => 'c'});
    $lt->begin_root;
    $lt->push_level;
    ref_is($lt->ingest(users => {id => 3, name => 'c'}), $deep, "Reading inside a savepoint compares against the outside level");
    $lt->rollback_level;
    $lt->rollback_level;
};

subtest forget_in_savepoint => sub {
    for my $end (qw/commit rollback/) {
        my $lt  = lookup();
        my $pre = $lt->store(users => {id => 1, name => 'a'});
        $lt->begin_root;
        $lt->ingest(users => {id => 1, name => 'a'});
        $lt->push_level;
        $lt->forget(users => {id => 1});
        $lt->rollback_level;
        ok($lt->is_canon(users => $pre), "A savepoint rollback restores a re-read row forgotten in it ($end)");

        if ($end eq 'commit') {
            $lt->commit_level;
            ok($lt->is_canon(users => $pre), "and the root commit merges it back outside");
        }
        else {
            $lt->rollback_level;
            ok(!$lt->is_canon(users => $pre), "but a root rollback does not bring it back outside");
        }
    }
};

subtest clear_txn_levels => sub {
    my $lt   = lookup();
    my $kept = $lt->store(users => {id => 1});
    $lt->begin_root;
    my $in = $lt->store(users => {id => 2});
    $lt->push_level;
    $lt->clear_txn_levels;
    is(scalar @{$lt->stack},  3,        "Keeps the number of levels");
    is([@{$lt->stack}[1, 2]], [{}, {}], "Empties every transaction level");
    ref_is($lt->stack->[0]->{users}->{1}, $kept, "Keeps the outside level");
};

subtest savepoint_scaling => sub {
    my $lt = lookup();
    $lt->begin_root;
    my @held = map { $lt->store(users => {id => $_}) } 1 .. 10_000;
    my $root = $lt->stack->[1];

    $lt->push_level;
    is($lt->stack->[-1], {}, "A savepoint starts empty, however many rows the transaction holds");
    ref_is($lt->lookup(users => {id => 5000}), $held[4999], "and reads through to the root level");

    my $new = $lt->store(users => {id => 7});
    is($lt->stack->[-1], {users => {7 => $new}}, "A write goes to the savepoint level only");
    ref_is($root->{users}->{7}, $held[6], "leaving the root level as it was");

    $lt->commit_level;
    ref_is($lt->stack->[1],     $root, "A savepoint commit merges into the root level in place");
    ref_is($root->{users}->{7}, $new,  "carrying the savepoint's entries");
    is(scalar(keys %{$root->{users}}), 10_000, "and nothing else");
    $lt->rollback_level;
};

subtest savepoint_marks => sub {
    my $lt = lookup();
    $lt->begin_root;
    my $one = $lt->store(users => {id => 1});
    my $two = $lt->store(users => {id => 2});
    my $p   = $lt->store(pairs => {a  => 1, b => 2});

    $lt->push_level;
    $lt->forget(users => {id => 1});
    is($lt->lookup(users => {id => 1}), undef, "Forgetting a row in a savepoint hides the root's entry");
    ref_is($lt->lookup(users => {id => 2}), $two, "but no other");
    my $again = $lt->store(users => {id => 1});
    ref_is($lt->lookup(users => {id => 1}), $again, "A write after the mark is read before it");

    $lt->push_level;
    $lt->forget('users');
    is($lt->lookup(users => {id => 2}), undef, "Forgetting a table hides it below");
    ref_is($lt->lookup(pairs => {a => 1, b => 2}), $p, "but not other tables");
    $lt->commit_level;
    is($lt->lookup(users => {id => 2}), undef, "A savepoint commit carries the table mark into its savepoint parent");
    $lt->rollback_level;
    ref_is($lt->lookup(users => {id => 1}), $one, "Rolling the parent back shows the root's entries again");
    ref_is($lt->lookup(users => {id => 2}), $two, "for the whole table");

    $lt->push_level;
    $lt->forget;
    is($lt->lookup(pairs => {a => 1, b => 2}), undef, "Forgetting everything hides every table below");
    my $three = $lt->store(users => {id => 3});
    $lt->commit_level;
    is($lt->stack->[1], {users => {3 => $three}}, "A commit into the root level clears what the marks name and adds the entries");
    $lt->rollback_level;

    $lt->begin_root;
    $lt->store(users => {id => 1});
    $lt->push_level;
    $lt->push_level;
    $lt->forget(users => {id => 1});
    $lt->commit_level;
    is($lt->lookup(users => {id => 1}), undef, "A row mark carried into a savepoint parent still hides the root's entry");
    $lt->rollback_level;
    ok($lt->lookup(users => {id => 1}), "until that parent rolls back");
    $lt->rollback_level;
};

subtest root_marks => sub {
    my $lt   = lookup(retain => 1);
    my @rows = map { $lt->store(users => {id => $_}) } 1 .. 3;
    my $p    = $lt->store(pairs => {a => 1, b => 2});

    $lt->begin_root;
    $lt->clear(users => {id => 1});
    $lt->clear('pairs');
    ok($lt->stack->[0]->{users}->{1}, "A clear in the root level leaves the outside level alone at once");
    $lt->commit_level;
    is($lt->lookup(users => {id => 1}),         undef, "A root commit clears the marked row from the outside level");
    is($lt->lookup(pairs => {a  => 1, b => 2}), undef, "and the marked table");
    ok($lt->is_canon(users => $rows[1]), "but nothing else");

    $lt->begin_root;
    $lt->clear(users => {id => 2});
    $lt->clear;
    $lt->rollback_level;
    ok($lt->is_canon(users => $rows[1]), "A root rollback leaves the outside level as it was");
    ok($lt->is_canon(users => $rows[2]), "even after clearing everything");

    $lt->begin_root;
    $lt->clear(users => {id => 2});
    my $again = $lt->store(users => {id => 2});
    $lt->commit_level;
    ref_is($lt->lookup(users => {id => 2}), $again, "A root commit merges its entries after applying its marks");

    $lt->begin_root;
    $lt->push_level;
    $lt->clear(users => {id => 3});
    $lt->commit_level;
    ref_is($lt->stack->[0]->{users}->{3}, $rows[2], "A savepoint's clear carried into the root level does not touch the outside level yet");
    $lt->commit_level;
    is($lt->lookup(users => {id => 3}), undef, "but the root commit clears it there");

    $lt->store(users => {id => 3});
    $lt->begin_root;
    $lt->clear;
    $lt->commit_level;
    is($lt->stack, [{}], "Clearing everything in the root level empties the outside level on commit");
};

subtest row_state => sub {
    my $LT = 'DBIx::QuickORM::LookupTable';
    my $lt = lookup(retain => 1);

    my $viv = {id => 1};
    is($LT->row_state($viv), undef, "A hash starts with no state");
    $LT->mark_vivified($viv);
    is($LT->row_state($viv), 'vivified', "mark_vivified marks it");
    is($viv,                 {id => 1},  "without touching the hash");

    my $one = $lt->store(users => {id => 1});
    $lt->mark_deleted($one);
    is($lt->row_state($one), 'deleted', "mark_deleted outside a transaction");

    my $two   = $lt->store(users => {id => 2});
    my $three = $lt->store(users => {id => 3});
    $lt->begin_root;
    $lt->mark_deleted($two);
    $lt->push_level;
    $lt->mark_deleted($three, $one);
    $lt->rollback_level;
    is($lt->row_state($three), undef,     "A savepoint rollback unmarks what it marked");
    is($lt->row_state($one),   'deleted', "but not a hash marked before it");
    is($lt->row_state($two),   'deleted', "nor one its parent marked");

    $lt->push_level;
    $lt->mark_deleted($three);
    $lt->commit_level;
    is($lt->row_state($three), 'deleted', "A savepoint commit keeps its marks");
    $lt->rollback_level;
    is($lt->row_state($three), undef, "carried into its parent, whose rollback unmarks them");
    is($lt->row_state($two),   undef, "with the parent's own");

    $lt->begin_root;
    $lt->mark_deleted($two);
    $lt->commit_level;
    is($lt->row_state($two), 'deleted', "A root commit keeps them");
};

subtest mark_inserted => sub {
    my $LT = 'DBIx::QuickORM::LookupTable';
    my $lt = lookup(retain => 1);

    my $out = $lt->store(users => {id => 1});
    $lt->mark_inserted($out);
    $lt->begin_root;
    $lt->rollback_level;
    is($LT->row_state($out), undef, "Nothing is recorded outside a transaction");

    my ($one, $two, $three) = map { {id => $_} } 1 .. 3;
    $lt->begin_root;
    $lt->mark_inserted($one);
    $lt->push_level;
    $lt->mark_inserted($two);
    $lt->rollback_level;
    is($LT->row_state($two), 'vivified', "A savepoint rollback marks what it inserted vivified");
    is($LT->row_state($one), undef,      "but not what its parent inserted");

    $lt->push_level;
    $lt->mark_inserted($three);
    $lt->commit_level;
    is($LT->row_state($three), undef, "A savepoint commit marks nothing");
    $lt->rollback_level;
    is([map { $LT->row_state($_) } $one, $three], ['vivified', 'vivified'], "and carries its inserts to the parent, whose rollback marks them");

    my $gone = {id => 4};
    $lt->begin_root;
    $lt->mark_inserted($gone);
    $lt->mark_deleted($gone);
    my $copy = {%$gone};
    $LT->copy_row_state($gone, $copy);
    $lt->rollback_level;
    is([map { $LT->row_state($_) } $gone, $copy], ['vivified', 'vivified'], "A hash inserted then deleted ends up vivified, and so does its copy");

    my $kept = {id => 5};
    $lt->begin_root;
    $lt->mark_inserted($kept);
    $lt->commit_level;
    is($LT->row_state($kept), undef, "A root commit drops the inserts");
};

subtest carry_inserted => sub {
    my $LT = 'DBIx::QuickORM::LookupTable';
    my $lt = lookup(retain => 1);

    my ($old, $new, $newer, $other) = map { {id => $_} } 1 .. 4;
    $lt->carry_inserted($old, $new);
    $lt->begin_root;
    $lt->mark_inserted($old);
    $lt->push_level;
    $lt->carry_inserted($old,   $new);
    $lt->carry_inserted($other, $newer);
    $lt->rollback_level;
    is($LT->row_state($new), undef, "A savepoint rollback leaves a hash carried to its parent's insert");
    $lt->carry_inserted($new, $newer);
    $lt->rollback_level;
    is([map { $LT->row_state($_) } $old, $new, $newer], ['vivified', 'vivified', 'vivified'], "which marks it and what it was carried to when it rolls back");
    is($LT->row_state($other),                          undef,                                "A hash not inserted carries nothing");

    my ($kept, $then) = map { {id => $_} } 5, 6;
    $lt->begin_root;
    $lt->mark_inserted($kept);
    $lt->carry_inserted($kept, $then);
    $lt->commit_level;
    is($LT->row_state($then), undef, "A root commit drops it");
};

subtest copy_row_state => sub {
    my $LT = 'DBIx::QuickORM::LookupTable';
    my $lt = lookup(retain => 1);

    my $viv = {id => 9};
    $LT->mark_vivified($viv);
    my $vcopy = {%$viv};
    $LT->copy_row_state($viv, $vcopy);
    is($LT->row_state($vcopy), 'vivified', "A vivified hash's copy is vivified");
    my $plain = {id => 8};
    $LT->copy_row_state({id => 8}, $plain);
    is($LT->row_state($plain), undef, "A hash with no state gives none");

    my $old = $lt->store(users => {id => 1});
    $lt->begin_root;
    $lt->mark_deleted($old);
    my $copy  = {%$old};
    my $copy2 = {%$old};
    $LT->copy_row_state($old,  $copy);
    $LT->copy_row_state($copy, $copy2);
    is([map { $LT->row_state($_) } $copy, $copy2], ['deleted', 'deleted'], "Copies of a deleted hash, and copies of those, are deleted");
    $lt->rollback_level;
    is([map { $LT->row_state($_) } $old, $copy, $copy2], [undef, undef, undef], "and unmarked when the delete rolls back");

    $lt->begin_root;
    $lt->mark_deleted($copy);
    is($LT->row_state($copy), 'deleted', "A copy still following an unmarked hash can be marked deleted again");
    $lt->rollback_level;
    is($LT->row_state($copy), undef, "and that mark rolls back too");
};

done_testing;
