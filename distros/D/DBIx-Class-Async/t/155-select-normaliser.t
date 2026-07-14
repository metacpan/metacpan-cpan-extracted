#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('DBIx::Class::Async::SelectNormaliser')
    or BAIL_OUT('Module failed to load -- cannot continue');

my $SN = 'DBIx::Class::Async::SelectNormaliser';

# _is_ident_hashref -- internal classifier
#
# Design note: _is_ident_hashref is private but is tested directly because
# it is the classification pivot for the entire normalisation pass. An error
# here silently misclassifies every item in every select list. Keeping it
# tested as a unit makes failures easy to locate without having to trace
# through the full normalise() logic.

subtest '_is_ident_hashref identifies -ident hashrefs correctly' => sub {

    # Positive cases
    ok( $SN->_is_ident_hashref({ '-ident' => 'me.col' }),
        'bare -ident hashref' );
    ok( $SN->_is_ident_hashref({ '-ident' => 'me.col', '-as' => 'alias' }),
        '-ident hashref with -as' );
    ok( $SN->_is_ident_hashref({ '-ident' => 'me.col', extra_key => 1 }),
        '-ident hashref with extra keys' );

    # Negative cases -- must all return false
    ok( !$SN->_is_ident_hashref('me.col'),
        'bare string is not an ident hashref' );
    ok( !$SN->_is_ident_hashref({ count => 'me.id', '-as' => 'total' }),
        'function hashref is not an ident hashref' );
    ok( !$SN->_is_ident_hashref({ max => 'me.amount' }),
        'function hashref without -as is not an ident hashref' );
    ok( !$SN->_is_ident_hashref(\[ 'COALESCE(me.col, ?)', 0 ]),
        'literal SQL ref is not an ident hashref' );
    ok( !$SN->_is_ident_hashref([]),
        'arrayref is not an ident hashref' );
    ok( !$SN->_is_ident_hashref(undef),
        'undef is not an ident hashref' );
    ok( !$SN->_is_ident_hashref({}),
        'empty hashref is not an ident hashref' );
};

# normalise() -- array-level transformation

subtest 'normalise() - bare strings pass through unchanged' => sub {
    my ($sel, $as) = $SN->normalise(
        select => [ 'me.id', 'me.name', 'me.email'  ],
        as     => [ 'id',    'name',    'email'     ],
    );

    is_deeply( $sel, [ 'me.id', 'me.name', 'me.email'  ], 'select unchanged' );
    is_deeply( $as,  [ 'id',    'name',    'email'     ], 'as unchanged'     );
};

subtest 'normalise() - { -ident } without -as rewrites select, leaves as undef' => sub {

    # Design note: when -as is absent and the caller's as[] slot is also undef,
    # the output as slot is undef. DBIC omits undef alias entries, so the
    # column appears in the result without an alias -- the same behaviour as
    # passing a bare string with no corresponding as entry.

    my ($sel, $as) = $SN->normalise(
        select => [ { '-ident' => 'me.status' } ],
        as     => [],
    );

    is_deeply( $sel, [ 'me.status' ], 'ident rewritten to bare string' );
    is( $as->[0], undef, 'as slot is undef when -as absent and as[] empty' );
};

subtest 'normalise() - { -ident, -as } rewrites select and populates as' => sub {

    my ($sel, $as) = $SN->normalise(
        select => [ { '-ident' => 'me.status', '-as' => 'current_status' } ],
        as     => [],
    );

    is_deeply( $sel, [ 'me.status'      ], 'ident rewritten to bare string' );
    is_deeply( $as,  [ 'current_status' ], 'alias populated from -as'       );
};

subtest 'normalise() - function hashrefs pass through unchanged' => sub {

    # Design note: function hashrefs { func => $col, -as => $alias } must not
    # be touched. DBIC handles -as inside function hashrefs itself via a
    # separate code path. Extracting -as from them would corrupt the SQL
    # because DBIC would then look for the alias in the as[] array at the
    # wrong position while also having it inline in the hashref.

    my ($sel, $as) = $SN->normalise(
        select => [ { count => 'me.id', '-as' => 'total' } ],
        as     => [ 'cnt' ],
    );

    is_deeply( $sel->[0], { count => 'me.id', '-as' => 'total' },
        'function hashref is unchanged' );
    is( $as->[0], 'cnt', 'as entry preserved' );
};

subtest 'normalise() - literal SQL refs pass through unchanged' => sub {

    my $literal = \[ 'COALESCE(me.col, ?)', 0 ];
    my ($sel, $as) = $SN->normalise(
        select => [ $literal ],
        as     => [ 'coalesced' ],
    );

    is( $sel->[0], $literal,    'literal SQL ref is the same reference' );
    is( $as->[0],  'coalesced', 'as entry preserved'                    );
};

subtest 'normalise() - mixed list with all forms' => sub {

    # This is the most representative real-world use case:
    # a select list containing bare strings, -ident items, function hashrefs,
    # and literal SQL all in one call.

    my $literal = \[ 'NOW()' ];

    my ($sel, $as) = $SN->normalise(
        select => [
            'me.id',                                                # bare string
            { '-ident' => 'me.status', '-as' => 'current_status' }, # -ident with -as
            { '-ident' => 'me.created' },                           # -ident without -as
            { count    => 'me.id',     '-as' => 'total' },          # function hashref
            $literal,                                               # literal SQL ref
        ],
        as => [ 'id', undef, 'created_at', 'total', 'now' ],
    );

    # select
    is( $sel->[0], 'me.id',     'slot 0: bare string preserved'       );
    is( $sel->[1], 'me.status', 'slot 1: -ident rewritten'            );
    is( $sel->[2], 'me.created','slot 2: -ident (no -as) rewritten'   );
    is_deeply( $sel->[3], { count => 'me.id', '-as' => 'total' },
                            'slot 3: function hashref unchanged'      );
    is( $sel->[4], $literal,    'slot 4: literal SQL ref unchanged'   );

    # as
    is( $as->[0], 'id',             'slot 0: id from as array'               );
    is( $as->[1], 'current_status', 'slot 1: alias from -as (as[] was undef)');
    is( $as->[2], 'created_at',     'slot 2: alias from as array'            );
    is( $as->[3], 'total',          'slot 3: as array entry preserved'       );
    is( $as->[4], 'now',            'slot 4: as array entry preserved'       );
};

subtest 'normalise() - caller as[] takes priority over -as in -ident hashref' => sub {

    # Design note: the caller may specify the alias both inline (-as) and in
    # the as[] array. The as[] array always wins because:
    #
    #   1. It reflects explicit caller intent -- the caller chose to use
    #      the as[] form, which is the canonical DBIC way.
    #   2. It matches the behaviour of all other select forms: for bare strings
    #      the alias always comes from as[], so -ident should behave the same
    #      way when as[] is populated.
    #   3. It makes composability predictable: if you build the select list
    #      programmatically and separately build the as list, there is no
    #      surprise conflict.

    my ($sel, $as) = $SN->normalise(
        select => [ { '-ident' => 'me.col', '-as' => 'from_ident' } ],
        as     => [ 'from_as_array' ],
    );

    is( $sel->[0], 'me.col',        'ident rewritten correctly'     );
    is( $as->[0],  'from_as_array', 'as[] wins over inline -as'     );
};

subtest 'normalise() - as[] longer than select - extra entries preserved' => sub {

    # Extra as[] entries beyond the length of select are an unusual but valid
    # state (they would be silently ignored by DBIC). We preserve them rather
    # than truncating, so the caller gets back exactly what they passed in beyond
    # the select length.

    my ($sel, $as) = $SN->normalise(
        select => [ 'me.id' ],
        as     => [ 'id', 'orphaned_alias' ],
    );

    is( scalar @$sel, 1,                'select has 1 entry'           );
    is( $as->[0],     'id',             'first as entry preserved'     );
    is( $as->[1],     'orphaned_alias', 'extra as entry preserved'     );
};

subtest 'normalise() - as[] shorter than select - gap filled from -ident -as' => sub {

    my ($sel, $as) = $SN->normalise(
        select => [
            'me.id',
            { '-ident' => 'me.status', '-as' => 'current_status' },
        ],
        as => [ 'id' ],   # only one entry -- slot 1 not set
    );

    is( $as->[0], 'id',             'slot 0 from as array'         );
    is( $as->[1], 'current_status', 'slot 1 filled from -ident -as');
};

subtest 'normalise() - scalar (non-array) select is wrapped in arrayref' => sub {

    # Callers sometimes pass a single column as a scalar rather than a
    # one-element arrayref. normalise() accepts both forms.

    my ($sel, $as) = $SN->normalise(
        select => 'me.name',
        as     => [ 'name' ],
    );

    is_deeply( $sel, [ 'me.name' ], 'scalar wrapped in arrayref' );
    is( $as->[0], 'name', 'as entry preserved' );
};

subtest 'normalise() - hashref (non-array) select is wrapped in arrayref' => sub {

    my ($sel, $as) = $SN->normalise(
        select => { '-ident' => 'me.status', '-as' => 'st' },
        as     => [],
    );

    is_deeply( $sel, [ 'me.status' ], 'hashref wrapped and rewritten' );
    is( $as->[0], 'st', 'alias from -as' );
};

subtest 'normalise() - empty select produces empty arrays' => sub {

    my ($sel, $as) = $SN->normalise( select => [], as => [] );

    is_deeply( $sel, [], 'empty select returns empty arrayref' );
    is_deeply( $as,  [], 'empty as returns empty arrayref'     );
};

# normalise_attrs() -- full attrs hashref transformation

subtest 'normalise_attrs() - no select key returns hashref unchanged' => sub {

    # Design note: we return the same hashref reference rather than a copy when
    # there is no select key, because there is nothing to change and copying
    # would be wasteful. Callers must not rely on getting a different reference
    # back, but they must be able to rely on the content being correct.

    my $attrs = { where => { active => 1 }, order_by => 'me.id' };
    my $result = $SN->normalise_attrs($attrs);

    is( $result, $attrs, 'same reference returned when no select key' );
};

subtest 'normalise_attrs() - rewrites select/as, preserves other keys' => sub {

    my $attrs = {
        select   => [ { '-ident' => 'me.status', '-as' => 'current_status' } ],
        as       => [],
        where    => { active => 1 },
        order_by => 'me.id',
        join     => 'orders',
    };

    my $result = $SN->normalise_attrs($attrs);

    # select and as rewritten
    is_deeply( $result->{select}, [ 'me.status'      ], 'select rewritten' );
    is_deeply( $result->{as},     [ 'current_status' ], 'as populated'     );

    # Other keys untouched
    is_deeply( $result->{where},    { active => 1 }, 'where preserved'    );
    is(        $result->{order_by}, 'me.id',         'order_by preserved' );
    is(        $result->{join},     'orders',        'join preserved'     );
};

subtest 'normalise_attrs() - no as key in attrs - as is populated from -ident items' => sub {

    my $attrs = {
        select => [ { '-ident' => 'me.col', '-as' => 'my_alias' } ],
        # no 'as' key at all
    };

    my $result = $SN->normalise_attrs($attrs);

    is_deeply( $result->{select}, [ 'me.col'   ], 'select rewritten'           );
    is_deeply( $result->{as},     [ 'my_alias' ], 'as created from -ident item' );
};

subtest 'normalise_attrs() - input hashref is not modified in place' => sub {

    # Design note: normalise_attrs() must be side-effect-free on its input.
    # The caller may hold a reference to the original attrs and pass them to
    # multiple searches, chain them, or inspect them after the call. Mutating
    # the input would produce subtle, hard-to-debug corruption.

    my $original_select = [ { '-ident' => 'me.status', '-as' => 'st' } ];
    my $original_as     = [];

    my $attrs  = {
        select => $original_select,
        as     => $original_as,
    };

    my $result = $SN->normalise_attrs($attrs);

    # The result is a different hashref
    isnt( $result, $attrs, 'returns a different hashref' );

    # The original select arrayref is unchanged
    is_deeply( $attrs->{select}, [ { '-ident' => 'me.status', '-as' => 'st' } ],
        'original select not modified' );
    is_deeply( $attrs->{as}, [], 'original as not modified' );

    # And the result is correct
    is_deeply( $result->{select}, [ 'me.status' ], 'result select is correct' );
    is_deeply( $result->{as},     [ 'st'        ], 'result as is correct'     );
};

# Structural proof: the normalised output has the right shape to be
#    passed directly to DBIC without triggering the broken -IDENT() path.
#
# We prove three things without touching SQL::Abstract internals:
#
#   a. Every item that was a { -ident } hashref is now a bare string.
#      A bare string in select[] is rendered by SQL::Abstract as a column
#      reference, never as a function call.
#
#   b. Every item that was a function hashref is still a hashref.
#      Its -as key is still inside the hashref, not in as[], because
#      DBIC expects function aliases inline.
#
#   c. Every item that was a bare string is still a bare string.
#
# This is the complete correctness proof for the normalisation: if all
# -ident items become bare strings, all function items stay hashrefs, and
# all bare strings stay bare strings, then SQL::Abstract will produce
# correct SQL from the output because bare strings in select[] map directly
# to column references in the generated SQL.

subtest 'structural proof - normalised output has correct types for SQL generation' => sub {

    my $literal = \[ 'NOW()' ];

    my ($sel, $as) = $SN->normalise(
        select => [
            'me.id',                                                 # bare string
            { '-ident' => 'me.status',  '-as' => 'current_status' }, # -ident with -as
            { '-ident' => 'me.created', '-as' => 'created_at'     }, # -ident with -as
            { count    => 'me.id',      '-as' => 'total'          }, # function hashref
            $literal,                                                # literal SQL ref
        ],
        as => [],
    );

    # select[] types

    # Slot 0: bare string in, bare string out
    ok( !ref($sel->[0]), 'slot 0 (bare string): still a non-ref scalar' );
    is( $sel->[0], 'me.id', 'slot 0: value unchanged' );

    # Slot 1: { -ident } hashref in, bare string out
    # This is the core of the fix: SQL::Abstract renders a bare string as a
    # column reference.  A hashref with key '-ident' would have been rendered
    # as the function -IDENT(), which is invalid SQL.
    ok( !ref($sel->[1]), 'slot 1 (-ident): rewritten to non-ref scalar' );
    is( $sel->[1], 'me.status', 'slot 1: correct column name' );

    # Slot 2: same
    ok( !ref($sel->[2]), 'slot 2 (-ident): rewritten to non-ref scalar' );
    is( $sel->[2], 'me.created', 'slot 2: correct column name' );

    # Slot 3: function hashref in, function hashref out (with -as intact inside it)
    ok( ref($sel->[3]) eq 'HASH',   'slot 3 (function): still a hashref'    );
    ok( exists $sel->[3]{'-as'},    'slot 3: -as key preserved inside hash' );
    is( $sel->[3]{'-as'}, 'total',  'slot 3: -as value unchanged'           );
    ok( exists $sel->[3]{'count'},  'slot 3: function key preserved'        );

    # Slot 4: literal SQL ref in, same ref out
    ok( ref($sel->[4]) eq 'REF' || ref($sel->[4]) eq 'SCALAR' || ref(\$sel->[4]) eq 'REF',
        'slot 4 (literal): still a reference' );
    is( $sel->[4], $literal, 'slot 4: same reference identity' );

    # as[] values

    is( $as->[0], undef,            'as[0]: no alias for bare string'     );
    is( $as->[1], 'current_status', 'as[1]: alias populated from -as'     );
    is( $as->[2], 'created_at',     'as[2]: alias populated from -as'     );
    is( $as->[3], undef,            'as[3]: function alias stays in hash'  );
    is( $as->[4], undef,            'as[4]: no alias for literal SQL'      );

    # absence of -ident keys in output
    # Belt-and-braces check: none of the output select items should be a
    # hashref with a -ident key.  If any are, the normaliser missed one.
    my @ident_leftovers = grep { ref $_ eq 'HASH' && exists $_->{'-ident'} } @$sel;
    is( scalar @ident_leftovers, 0, 'no -ident hashrefs remain in normalised select' );
};

# Integration Test
#
# These subtests require a live schema. If the required modules are not
# available, the section is skipped cleanly so the unit tests above still
# pass in minimal environments.

INTEGRATION: {

    # Guard: skip the whole section if any required module is missing
    for my $mod (qw(
        File::Temp
        IO::Async::Loop
        DBIx::Class::Async::Schema
        DBIx::Class::Async::ResultSet
    )) {
        eval "require $mod";
        if ($@) {
            note "Skipping Section B (live schema integration): $mod not available";
            last INTEGRATION;
        }
    }

    # Also need TestSchema from t/lib
    eval { require TestSchema };
    if ($@) {
        note "Skipping Section B: TestSchema not available (not running from project root?)";
        last INTEGRATION;
    }

    my $loop           = IO::Async::Loop->new;
    my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 0,
        },
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    # Seed one user so queries return something
    my $seq = 0;
    my $user = $schema->await(
        $schema->resultset('User')->create({
            name   => 'Integration User',
            email  => 'int' . (++$seq) . '@test.example',
            active => 1,
        })
    );

    # search() stores normalised attrs on the new ResultSet
    #
    # Design note: this subtest checks the integration point directly --
    # that $rs->{_attrs} contains bare strings after a search() with
    # -ident items, without needing to execute any SQL. This is the
    # minimum proof that the patch is in place.

    subtest 'search() stores normalised attrs on the ResultSet (no -ident left in _attrs)' => sub {

        my $rs = $schema->resultset('User')->search(
            {},
            {
                select => [
                    { '-ident' => 'me.id',     '-as' => 'user_id'   },
                    { '-ident' => 'me.name',   '-as' => 'user_name' },
                    { '-ident' => 'me.active', '-as' => 'is_active' },
                ],
                as => [],
            }
        );

        # The stored _attrs must have no -ident hashrefs in select
        my $stored_select = $rs->{_attrs}{select};
        ok( ref $stored_select eq 'ARRAY', 'stored select is an arrayref' );

        my @ident_leftovers = grep {
            ref $_ eq 'HASH' && exists $_->{'-ident'}
        } @$stored_select;

        is( scalar @ident_leftovers, 0,
            'no -ident hashrefs remain in stored _attrs after search()' );

        # All three items must now be bare strings
        ok( !ref($stored_select->[0]), 'slot 0 is a bare string' );
        ok( !ref($stored_select->[1]), 'slot 1 is a bare string' );
        ok( !ref($stored_select->[2]), 'slot 2 is a bare string' );

        is( $stored_select->[0], 'me.id',     'slot 0: correct column' );
        is( $stored_select->[1], 'me.name',   'slot 1: correct column' );
        is( $stored_select->[2], 'me.active', 'slot 2: correct column' );

        # as[] must be populated from -as
        my $stored_as = $rs->{_attrs}{as};
        is( $stored_as->[0], 'user_id',   'as[0]: user_id'   );
        is( $stored_as->[1], 'user_name', 'as[1]: user_name' );
        is( $stored_as->[2], 'is_active', 'as[2]: is_active' );
    };

    # -ident select via search() returns correct column data
    #
    # Design note: this is the end-to-end proof that the normalised attrs
    # produce valid SQL and that the right data comes back. Without the
    # normalisation, DBIC would generate SELECT -IDENT(me.name) AS user_name
    # which is a syntax error on SQLite.

    subtest '-ident select via search() returns correct column data' => sub {

        my $rs = $schema->resultset('User')->search(
            { 'me.id' => $user->id },
            {
                select => [ { '-ident' => 'me.name', '-as' => 'user_name' } ],
                as     => [ 'user_name' ],
            }
        );

        my $rows;
        lives_ok(
            sub { $rows = $schema->await($rs->all) },
            'search() with -ident does not die'
        );

        is( scalar @$rows, 1, 'one row returned' );
        is( $rows->[0]->get_column('user_name'), 'Integration User',
            'column data correct via -ident alias' );
    };

    # Mixed -ident + function hashref via search() works end-to-end
    #
    # Design note: function hashrefs must be left untouched while -ident
    # items are rewritten. This subtest verifies both in the same query.

    subtest 'mixed -ident and function hashref in search() works end-to-end' => sub {

        my $rs = $schema->resultset('User')->search(
            {},
            {
                select => [
                    { '-ident' => 'me.active', '-as' => 'is_active' },
                    { count    => 'me.id',     '-as' => 'total'     },
                ],
                as       => [ 'is_active', 'total' ],
                group_by => [ 'me.active' ],
            }
        );

        # Structural check: function hashref must still be a hashref in _attrs
        my $stored = $rs->{_attrs}{select};
        ok( !ref($stored->[0]),           'slot 0 (-ident) is bare string' );
        ok( ref($stored->[1]) eq 'HASH',  'slot 1 (function) is still a hashref' );
        ok( exists $stored->[1]{count},   'function key preserved'         );
        ok( exists $stored->[1]{'-as'},   '-as preserved inside function'  );

        # Execution check
        my $rows;
        lives_ok(
            sub { $rows = $schema->await($rs->all) },
            'mixed -ident + function search() does not die'
        );

        ok( scalar @$rows >= 1, 'at least one group returned' );
    };

    # Chained search() calls preserve normalisation
    #
    # Design note: when search() is chained ($rs->search(A)->search(B)),
    # the second call merges $self->{_attrs} (already normalised from the
    # first call) with the new attrs. This subtest confirms that the result
    # of the chain is also clean -- no -ident items survive either pass.

    subtest 'chained search() calls produce fully normalised attrs' => sub {

        my $rs1 = $schema->resultset('User')->search(
            {},
            {
                select => [ { '-ident' => 'me.name', '-as' => 'user_name' } ],
                as     => [],
            }
        );

        # Second search adds another -ident column
        my $rs2 = $rs1->search(
            { 'me.active' => 1 },
            {
                select => [ { '-ident' => 'me.active', '-as' => 'is_active' } ],
                as     => [],
            }
        );

        my $stored = $rs2->{_attrs}{select};

        my @ident_leftovers = grep {
            ref $_ eq 'HASH' && exists $_->{'-ident'}
        } @$stored;

        is( scalar @ident_leftovers, 0,
            'no -ident hashrefs in chained search() result' );

        # Both columns should be bare strings
        my @bare = grep { !ref $_ } @$stored;
        ok( scalar @bare >= 1, 'at least one bare string in merged select' );
    };

    # search_rs() also normalises (it delegates to search())
    #
    # Design note: search_rs() is a one-liner that calls search(). This
    # subtest confirms the delegation is real and the normalisation applies.

    subtest 'search_rs() also produces normalised attrs' => sub {

        my $rs = $schema->resultset('User')->search_rs(
            {},
            {
                select => [ { '-ident' => 'me.name', '-as' => 'user_name' } ],
                as     => [],
            }
        );

        my $stored = $rs->{_attrs}{select};

        my @ident_leftovers = grep {
            ref $_ eq 'HASH' && exists $_->{'-ident'}
        } @$stored;

        is( scalar @ident_leftovers, 0,
            'no -ident hashrefs in search_rs() result' );

        ok( !ref($stored->[0]),         'column is a bare string' );
        is( $stored->[0], 'me.name',    'correct column name'     );
        is( $rs->{_attrs}{as}[0], 'user_name', 'alias populated'  );
    };
}

done_testing;
