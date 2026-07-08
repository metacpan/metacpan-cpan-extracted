use Test2::V0 '!meta', '!pass';

# Regression: resolving links against a Join.
#  B2: Join::links mixes links from every component table. Two components that
#      link to the same third table via same-named local columns used to
#      collide in the link-cache build and croak "Links do not have the same
#      'local' table", breaking *every* resolve_link on that join.
#  B3: a self-join lists the same table's links twice; merging them duplicated
#      the alias list, so resolve_link on the alias croaked "Ambiguous".

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;

my $C = 'DBIx::QuickORM::Schema::Table::Column';
sub col { $C->new(name => $_[0], order => $_[1], affinity => 'numeric') }
sub L { DBIx::QuickORM::Link->new(@_) }

subtest cross_table_same_column_links => sub {
    my $addresses = DBIx::QuickORM::Schema::Table->new(name => 'addresses', columns => {id => col('id', 1)}, primary_key => ['id']);
    my $companies = DBIx::QuickORM::Schema::Table->new(
        name => 'companies', columns => {id => col('id', 1), address_id => col('address_id', 2)}, primary_key => ['id'],
        links => [L(local_table => 'companies', other_table => 'addresses', local_columns => ['address_id'], other_columns => ['id'], unique => 1)],
    );
    my $user_comp = L(local_table => 'users', other_table => 'companies', local_columns => ['company_id'], other_columns => ['id'], unique => 1);
    my $users = DBIx::QuickORM::Schema::Table->new(
        name => 'users', columns => {id => col('id', 1), company_id => col('company_id', 2), address_id => col('address_id', 3)}, primary_key => ['id'],
        links => [$user_comp, L(local_table => 'users', other_table => 'addresses', local_columns => ['address_id'], other_columns => ['id'], unique => 1)],
    );
    my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {users => $users, companies => $companies, addresses => $addresses});
    my $join = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $users)->left_join($user_comp);

    my $got;
    ok(lives { $got = $join->resolve_link(table => 'companies') }, "resolve_link no longer croaks on the local-table collision") or diag $@;
    is($got->other_table, 'companies', "and it resolves the unambiguous link");

    # The two addresses links (from users and from companies) are distinct, so
    # asking for 'addresses' without disambiguation is a clean ambiguity error,
    # not the old cross-local-table merge crash.
    like(
        dies { $join->resolve_link(table => 'addresses') },
        qr/Ambiguous/,
        "two distinct links to the same table report a clean ambiguity",
    );
};

subtest self_join_alias_not_duplicated => sub {
    my $mgr = L(local_table => 'emp', other_table => 'emp', local_columns => ['manager_id'], other_columns => ['id'], unique => 1, aliases => ['manager']);
    my $emp = DBIx::QuickORM::Schema::Table->new(
        name => 'emp', columns => {id => col('id', 1), manager_id => col('manager_id', 2)}, primary_key => ['id'],
        links => [$mgr],
    );
    my $schema = DBIx::QuickORM::Schema->new(name => 's2', tables => {emp => $emp});
    my $sj = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $emp)->left_join($mgr);

    my $got;
    ok(lives { $got = $sj->resolve_link('manager') }, "resolve_link on a self-join alias no longer croaks Ambiguous") or diag $@;
    is($got->other_table, 'emp',        "resolved the self-referential link");
    is($got->aliases, ['manager'],      "the merged link's alias list is de-duplicated");
};

subtest hashref_spec_without_local_table_on_a_join => sub {
    my $users = DBIx::QuickORM::Schema::Table->new(name => 'users', columns => {id => col('id', 1)}, primary_key => ['id']);
    my $posts = DBIx::QuickORM::Schema::Table->new(name => 'posts', columns => {id => col('id', 1), user_id => col('user_id', 2)}, primary_key => ['id']);
    my $link  = L(local_table => 'users', other_table => 'posts', local_columns => ['id'], other_columns => ['user_id'], unique => 0);
    my $sc    = DBIx::QuickORM::Schema->new(name => 's3', tables => {users => $users, posts => $posts});
    my $join  = DBIx::QuickORM::Join->new(schema => $sc, primary_source => $users)->left_join($link);

    # A Join has no single local table (no name()), so a hashref spec without
    # local_table must give a clear message, not die on a missing method.
    like(
        dies { $join->resolve_link({other_table => 'posts', local => ['id'], other => ['user_id'], unique => 0}) },
        qr/Cannot infer local_table/,
        "a hashref spec without local_table on a join croaks cleanly",
    );
};

done_testing;
