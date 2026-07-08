use Test2::V0 '!meta', '!pass';

# Schema::Table->new / init validation:
#  - primary_key must be an arrayref (used to die on a raw @$pk deref);
#  - unique-constraint and index column lists must reference real columns;
#  - link entries must be DBIx::QuickORM::Link instances;
#  - expression / undefined index key-parts (surfaced by some dialects during
#    introspection) are skipped rather than rejected;
#  - generated field lists are ordered by column position, not hash order.

use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;

my $C = 'DBIx::QuickORM::Schema::Table::Column';
sub col { $C->new(name => $_[0], order => $_[1], affinity => 'numeric') }

sub base_columns {
    return {
        id  => $C->new(name => 'id',  order => 1, type => \'integer'),
        val => $C->new(name => 'val', order => 2, type => \'text'),
    };
}

sub table {
    my %extra = @_;
    return DBIx::QuickORM::Schema::Table->new(name => 't', columns => base_columns(), %extra);
}

subtest primary_key_arrayref => sub {
    like(
        dies {
            DBIx::QuickORM::Schema::Table->new(
                name        => 't',
                columns     => {id => col('id', 1)},
                primary_key => 'id',    # scalar, not an arrayref
            );
        },
        qr/primary_key.*must be an arrayref/,
        "a scalar primary_key croaks cleanly instead of dereferencing a non-arrayref",
    );

    ok(
        lives {
            DBIx::QuickORM::Schema::Table->new(
                name        => 't',
                columns     => {id => col('id', 1)},
                primary_key => ['id'],
            );
        },
        "an arrayref primary_key still works",
    );
};

subtest unique_index_link_validation => sub {
    like(
        dies { table(unique => {bad => ['nope']}) },
        qr/Unique constraint 'bad' references column 'nope'/,
        "a unique constraint referencing an unknown column croaks",
    );

    like(
        dies { table(indexes => [{name => 'bad_idx', columns => ['nope']}]) },
        qr/Index 'bad_idx' references column 'nope'/,
        "an index referencing an unknown column croaks",
    );

    like(
        dies { table(indexes => [['nope']]) },
        qr/references column 'nope'/,
        "an arrayref-form index referencing an unknown column croaks",
    );

    like(
        dies { table(links => ['not-a-link']) },
        qr/Links must be 'DBIx::QuickORM::Link' instances/,
        "a links entry of the wrong type croaks",
    );

    ok(
        lives {
            table(
                unique  => {v => ['val']},
                indexes => [{name => 'ok_idx', columns => ['id', 'val']}],
            );
        },
        "valid unique/index column lists initialize cleanly",
    ) or note $@;

    ok(
        lives {
            table(indexes => [{name => 'expr_idx', columns => [undef, 'id']}, [\'lower(val)']]);
        },
        "expression / undefined index key-parts are skipped, not rejected",
    ) or note $@;

    ok(
        lives {
            table(links => [DBIx::QuickORM::Link->new(
                local_table   => 't',
                local_columns => ['id'],
                other_table   => 'other',
                other_columns => ['id'],
                unique        => 0,
            )]);
        },
        "a proper Link instance is accepted",
    ) or note $@;
};

subtest deterministic_field_order => sub {
    # Column order slots are deliberately out of both hash and alphabetical
    # order so the assertion can only pass if the field lists sort by order.
    my $t = DBIx::QuickORM::Schema::Table->new(
        name    => 't',
        columns => {
            zeta  => col('zeta',  1),
            alpha => col('alpha', 2),
            mid   => col('mid',   3),
            beta  => col('beta',  4),
        },
        primary_key => ['zeta'],
    );

    is($t->fields_list_all, ['zeta', 'alpha', 'mid', 'beta'], "fields_list_all follows column order, not hash/name order");
    is($t->fields_to_fetch, ['zeta', 'alpha', 'mid', 'beta'], "fields_to_fetch follows column order");
};

done_testing;
