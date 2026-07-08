use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# A scalar-ref write value (\'NOW()') or an arrayref whose first element is a
# scalar ref ([\'col + ?', $n]) is intentional SQL: it must be emitted as SQL,
# stored as the computed value, and reflected on the cached row -- never bound
# as a ref (which silently stored "SCALAR(0x...)") and never interpreted as an
# operator. Any other value shape stays a bound data value.

subtest formatter => sub {
    require DBIx::QuickORM::SQLBuilder::SQLAbstract;
    my $b = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;

    my $out = $b->_format_insert_and_update_data({
        plain  => 5,
        nul    => undef,
        op     => {'>' => 5},          # NEGATIVE: must NOT become an operator
        arr    => [1, 2, 3],           # NEGATIVE: plain arrayref is data
        lit    => \'NOW()',            # literal SQL
        litbnd => [\'x + ?', 7],       # literal SQL with a bind
    });

    is($out->{plain}, {-value => 5},        "plain scalar wrapped as bind value");
    is($out->{nul},   {-value => undef},    "undef wrapped as bind value");
    is($out->{op},    {-value => {'>' => 5}}, "operator-looking hashref stays a bound value (injection guard)");
    is($out->{arr},   {-value => [1, 2, 3]},  "plain arrayref stays a bound value (injection guard)");

    is(ref($out->{lit}), 'SCALAR',          "scalar-ref literal passed through");
    is(${$out->{lit}},   'NOW()',           "scalar-ref literal text preserved");

    is(ref($out->{litbnd}),    'REF',        "literal-with-bind became a ref");
    is(ref(${$out->{litbnd}}), 'ARRAY',      "literal-with-bind inner is an arrayref");
    is(${$out->{litbnd}}->[0], 'x + ?',      "literal-with-bind sql preserved");
    is(${$out->{litbnd}}->[1], ['litbnd' => 7], "literal-with-bind value tagged with its column");
};

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm myorm => sub {
        db 'mydb';
        autofill sub { autotype 'UUID' };
        schema myschema => sub {
            table widgets => sub {
                # perl_default returning a scalar-ref: a set-on-create literal.
                column stamp => sub { default sub { \'10 + 5' } };
            };
        };
    };

    my $con = orm('myorm')->connect;
    note "dialect: " . $con->dialect->dialect_name;
    my $h = $con->handle('widgets');

    my $fresh  = sub { my ($id, $f) = @_; $con->handle('widgets', where => {widget_id => $id})->data_only->one->{$f} };
    my $no_ref = sub { my ($v, $name) = @_; ok(!ref($v), "$name is not a ref") or diag("got ref: " . ref($v)); };

    # insert with a scalar-ref literal
    my $r = $h->insert({n => \'3 * 4', ver => 0});
    my $id = $r->field('widget_id');
    is($r->field('n'), 12, "insert scalar-ref literal: cached n = 12");
    $no_ref->($r->field('n'), "cached n");
    is($fresh->($id, 'n'), 12, "insert scalar-ref literal: DB n = 12");

    # perl_default returning a scalar-ref (set-on-create literal)
    is($r->field('stamp'), 15, "perl_default scalar-ref: stamp computed to 15");
    $no_ref->($r->field('stamp'), "cached stamp");
    is($fresh->($id, 'stamp'), 15, "perl_default scalar-ref: DB stamp = 15");

    # update with a scalar-ref literal
    $r->update({n => \'5 + 5'});
    is($r->field('n'), 10, "update scalar-ref literal: cached n = 10");
    $no_ref->($r->field('n'), "cached n after update");
    is($fresh->($id, 'n'), 10, "update scalar-ref literal: DB n = 10");

    # update with a literal-with-bind value (one typed literal + one bind so
    # Postgres can resolve the operand types; "? + ?" would be ambiguous there)
    $r->update({n => [\'100 + ?', 23]});
    is($r->field('n'), 123, "literal-with-bind update: cached n = 123");
    is($fresh->($id, 'n'), 123, "literal-with-bind update: DB n = 123");

    # upsert conflict-SET literal (row already exists). Upsert is built on
    # ON CONFLICT, which PostgreSQL gained in 9.5.
    unless (pg_older_than('9.5')) {
        my $u = $h->upsert({widget_id => $id, n => \'200 + 1', ver => 0});
        is($u->field('n'), 201, "upsert conflict-SET literal: cached n = 201");
        is($fresh->($id, 'n'), 201, "upsert conflict-SET literal: DB n = 201");
    }

    # cas WIN with literal guard advance + literal value (the cas POD example shape)
    my $c = $con->insert(widgets => {n => 5, ver => 1});
    my $cid = $c->field('widget_id');
    my $win = $con->handle($c)->cas(['ver'], {ver => \'ver + 1', n => \'7 * 6'});
    ok($win, "cas win");
    is($c->field('n'),   42, "cas win: cached n = 42 (computed literal)");
    is($c->field('ver'), 2,  "cas win: cached ver advanced to 2");
    $no_ref->($c->field('n'), "cas cached n");
    is($fresh->($cid, 'n'),   42, "cas win: DB n = 42");
    is($fresh->($cid, 'ver'), 2,  "cas win: DB ver = 2");

    # cas LOSS leaves everything untouched
    my $lose = $con->handle($c)->cas({ver => 999}, {ver => \'ver + 1', n => \'1 + 1'});
    ok(!$lose, "cas loss");
    is($c->field('n'),   42, "cas loss: cached n unchanged");
    is($fresh->($cid, 'n'), 42, "cas loss: DB n unchanged");

    # nothing ever surfaces a stringified scalar ref
    unlike("" . $r->field('n'), qr/SCALAR\(0x/, "value never stringifies to a SCALAR ref");
};

done_testing;
