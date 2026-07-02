use Test2::V0 '!meta', '!pass';

# Autofill hook behavior, exercised directly through Autofill->hook. Every
# callback registered for a hook receives the running value under the hook's
# seed key, and its return value feeds the next callback, so multiple hooks
# compose instead of the last one blindly winning.

use DBIx::QuickORM::Schema::Autofill;

subtest pipeline_composes => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        hooks => {
            field_accessor => [
                sub { my %p = @_; return "get_$p{name}" },
                sub { my %p = @_; return uc($p{name}) },
            ],
        },
    );

    my $out = $autofill->hook(field_accessor => {table => undef, name => 'foo', field => 'foo', column => undef}, 'foo');
    is($out, 'GET_FOO', "both field_accessor hooks applied, in registration order");
};

subtest single_hook_unchanged => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        hooks => {
            field_accessor => [sub { my %p = @_; return "get_$p{name}" }],
        },
    );

    my $out = $autofill->hook(field_accessor => {table => undef, name => 'foo', field => 'foo', column => undef}, 'foo');
    is($out, 'get_foo', "single hook behaves as before");
};

subtest seed_defaults_from_args => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        hooks => {
            primary_key => [sub { my %p = @_; return [@{$p{primary_key}}, 'extra'] }],
        },
    );

    my $out = $autofill->hook(primary_key => {primary_key => ['id'], table_name => 'foo'});
    is($out, ['id', 'extra'], "seed taken from the hook's seed key in the args when not passed explicitly");
};

subtest no_hooks_returns_seed => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(hooks => {});
    is($autofill->hook(field_accessor => {name => 'foo'}, 'foo'), 'foo', "explicit seed returned untouched");
    is($autofill->hook(table => {table => {name => 'foo'}}), {name => 'foo'}, "arg-derived seed returned untouched");
};

subtest invalid_hook_croaks => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(hooks => {});
    like(
        dies { $autofill->hook(bogus => {}) },
        qr/'bogus' is not a valid hook/,
        "unknown hook name croaks",
    );
};

subtest skip_falsy_names => sub {
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        skip => {table => {0 => 1}, column => {0 => {c => 1}}},
    );

    ok($autofill->skip(table => '0'), "a table named '0' can be skipped");
    ok($autofill->skip(column => ('0', 'c')), "a column on a table named '0' can be skipped");
    ok(!$autofill->skip(table => 'other'), "non-skipped table is not skipped");
};

subtest tables_hook => sub {
    ok(DBIx::QuickORM::Schema::Autofill->new->is_valid_hook('tables'), "'tables' is a registered hook");

    my %seen;
    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        hooks => {
            tables => [
                sub {
                    my %p = @_;
                    %seen = %p;
                    return $p{tables};
                },
            ],
        },
    );

    my $tables = {foo => {name => 'foo'}, bar => {name => 'bar'}};
    $autofill->hook(tables => {tables => $tables});

    ref_is($seen{tables}, $tables, "callback received the tables hashref under the 'tables' key");
    ref_is($seen{autofill}, $autofill, "callback received the autofill object");
};

done_testing;
