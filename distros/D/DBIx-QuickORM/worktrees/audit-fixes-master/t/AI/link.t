use Test2::V0 '!meta', '!pass';
use Scalar::Util qw/refaddr/;

# Unit-level coverage for DBIx::QuickORM::Link (construction, parse, merge,
# clone, key derivation, unique inference) and DBIx::QuickORM::Role::Linked
# (resolve_link by name/alias/columns, the by-columns key path, ambiguity).

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Util qw/column_key/;

sub col {
    my ($name, $order) = @_;
    return DBIx::QuickORM::Schema::Table::Column->new(name => $name, order => $order, type => \'integer');
}

sub link_obj {
    my %params = @_;
    return DBIx::QuickORM::Link->new(
        local_table   => 'users',
        local_columns => ['user_id'],
        other_table   => 'posts',
        other_columns => ['user_id'],
        unique        => 0,
        %params,
    );
}

subtest construction_and_key => sub {
    my $link = link_obj();
    is($link->local_table, 'users', "local_table set");
    is($link->other_table, 'posts', "other_table set");
    is($link->local_columns, ['user_id'], "local_columns set");
    is($link->unique, 0, "unique set");
    is($link->key, column_key('user_id'), "key derived from local columns");
    is($link->aliases, [], "aliases default to an empty arrayref");

    my $multi = link_obj(local_columns => ['b', 'a']);
    is($multi->key, column_key('a', 'b'), "key is order-independent (sorted)");
    is($multi->key, 'a, b', "key joins sorted columns with comma-space");

    like(
        dies { DBIx::QuickORM::Link->new(local_table => 'x', other_table => 'y', local_columns => ['a'], other_columns => ['b']) },
        qr/'unique' is a required attribute/,
        "unique is required",
    );
    like(
        dies { DBIx::QuickORM::Link->new(local_table => 'x', other_table => 'y', unique => 0, other_columns => ['b']) },
        qr/'local_columns' is a required attribute/,
        "local_columns is required",
    );
    like(
        dies { DBIx::QuickORM::Link->new(local_table => 'x', other_table => 'y', unique => 0, local_columns => [], other_columns => ['b']) },
        qr/'local_columns' must be an arrayref with at least 1 element/,
        "local_columns must be non-empty",
    );
};

subtest clone => sub {
    my $orig = link_obj(aliases => ['author'], created => 'somewhere', compiled => 'compiled');
    my $clone = $orig->clone;

    is($clone->local_columns, ['user_id'], "clone copies local_columns");
    is($clone->aliases, ['author'], "clone copies aliases");
    is($clone->unique, 0, "clone copies unique");
    is($clone->key, $orig->key, "clone recomputes a matching key");

    ok(refaddr($clone->local_columns) != refaddr($orig->local_columns), "clone duplicates the local_columns array");
    ok(refaddr($clone->other_columns) != refaddr($orig->other_columns), "clone duplicates the other_columns array");
    ok(refaddr($clone->aliases) != refaddr($orig->aliases), "clone duplicates the aliases array");

    is($clone->created, undef, "clone drops created state");
    is($clone->{compiled}, undef, "clone drops compiled state");

    my $over = $orig->clone(local_columns => ['x']);
    is($over->local_columns, ['x'], "clone applies overrides");
    is($over->key, column_key('x'), "clone recomputes key from overridden columns");

    my $with_created = $orig->clone(created => 'override');
    is($with_created->created, 'override', "clone honors an explicit created override");
};

subtest merge => sub {
    my $a = link_obj(unique => 1, aliases => ['author'], created => 'A');
    my $b = link_obj(unique => 1, aliases => ['writer'], created => 'B');

    my $m = $a->merge($b);
    is($m->aliases, ['author', 'writer'], "merge combines aliases from both links");
    is($m->created, 'A, B', "merge combines created notes");
    ok($m->unique, "merge preserves unique when both links are unique");

    my $alias = $a->merge(link_obj(unique => 0, aliases => ['declared'], created => 'D'));
    ok($alias->unique, "merge preserves unique when only one side is unique");
    is($alias->aliases, ['author', 'declared'], "merge still combines aliases when uniqueness differs");

    is($a->aliases, ['author'], "merge does not mutate the first link's aliases");
    is($b->aliases, ['writer'], "merge does not mutate the second link's aliases");

    my $dup = link_obj(unique => 1, aliases => [], created => 'SAME');
    my $dup2 = link_obj(unique => 1, aliases => [], created => 'SAME');
    is($dup->merge($dup2)->created, 'SAME', "merge dedups identical created notes");

    my $no_created = link_obj(unique => 1, aliases => []);
    is($no_created->merge($dup2)->created, 'SAME', "merge takes other's created when self has none");

    like(
        dies { $a->merge(link_obj(local_table => 'other', unique => 1)) },
        qr/do not have the same 'local' table/,
        "merge croaks on mismatched local tables",
    );
    like(
        dies { $a->merge(link_obj(local_columns => ['nope'], unique => 1)) },
        qr/do not have the same columns/,
        "merge croaks on mismatched columns",
    );
};

subtest parse_existing_link_returned => sub {
    my $link = link_obj();
    my $got = DBIx::QuickORM::Link->parse($link);
    is(refaddr($got), refaddr($link), "parse returns an existing Link object unchanged");
};

subtest parse_hash_spec => sub {
    my $users = DBIx::QuickORM::Schema::Table->new(
        name => 'users', columns => {user_id => col('user_id', 1)},
        primary_key => ['user_id'], unique => {column_key('user_id') => ['user_id']},
    );
    my $posts = DBIx::QuickORM::Schema::Table->new(
        name => 'posts', columns => {post_id => col('post_id', 1), user_id => col('user_id', 2)},
        primary_key => ['post_id'], unique => {column_key('post_id') => ['post_id']},
    );
    my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {users => $users, posts => $posts});

    my $link = DBIx::QuickORM::Link->parse($schema, {
        local_table => 'posts', other_table => 'users',
        local => ['user_id'], other => ['user_id'],
    });
    is($link->local_table, 'posts', "parsed local_table");
    is($link->other_table, 'users', "parsed other_table");
    is($link->local_columns, ['user_id'], "parsed local_columns");
    is($link->unique, 1, "unique inferred true: other side is a unique column");

    my $non_unique = DBIx::QuickORM::Link->parse($schema, {
        local_table => 'users', other_table => 'posts',
        local => ['user_id'], other => ['user_id'],
    });
    is($non_unique->unique, 0, "unique inferred false: other side is not unique");

    my $pk_only = DBIx::QuickORM::Schema::Table->new(
        name        => 'pk_only',
        columns     => {id => col('id', 1)},
        primary_key => ['id'],
    );
    my $pk_schema = DBIx::QuickORM::Schema->new(name => 'pk', tables => {posts => $posts, pk_only => $pk_only});
    my $pk_link = DBIx::QuickORM::Link->parse($pk_schema, {
        local_table => 'posts', other_table => 'pk_only',
        local => ['user_id'], other => ['id'],
    });
    is($pk_link->unique, 1, "unique inferred true when other side is the primary key");

    my $single = DBIx::QuickORM::Link->parse($schema, {local_table => 'posts', users => ['user_id']});
    is($single->local_table, 'posts', "single-key hash form: local_table");
    is($single->other_table, 'users', "single-key hash form infers other_table from the key");
    is($single->local_columns, ['user_id'], "single-key hash form fills local_columns");
    is($single->other_columns, ['user_id'], "single-key hash form fills other_columns");

    my $single_with_options = DBIx::QuickORM::Link->parse($schema, {
        local_table => 'posts',
        users       => ['user_id'],
        unique      => 0,
        aliases     => ['author'],
    });
    is($single_with_options->other_table, 'users', "single-key hash form ignores option keys when finding the other table");
    is($single_with_options->unique, 0, "single-key hash form keeps an explicit unique option");
    is($single_with_options->aliases, ['author'], "single-key hash form keeps aliases");

    # A fully specified spec (other_table already set) must not have a leftover
    # key misread as the other-table name by the single-key convenience branch.
    my $explicit = DBIx::QuickORM::Link->parse($schema, {
        local_table => 'posts', table => 'users',
        local       => ['author_id'], other => ['user_id'], unique => 1,
    });
    is($explicit->other_table, 'users', "explicit other-table is not clobbered by the single-key branch");
    is($explicit->unique, 1, "explicit unique option is honored");

    like(
        dies {
            DBIx::QuickORM::Link->parse($schema, {
                local_table => 'posts', table => 'users',
                local       => ['author_id'], other => ['user_id'], bogus => 1,
            });
        },
        qr/Unknown link specification key\(s\): bogus/,
        "an unknown spec key croaks clearly instead of being misread as the other table",
    );
};

subtest parse_rejects_scalar_ref => sub {
    # A scalar ref is not a valid link spec. To look a link up by destination
    # table name use resolve_link(table => $name) (see the resolve_link
    # subtest); parse only builds links from hashrefs / key-value pairs.
    like(
        dies { DBIx::QuickORM::Link->parse(\'posts') },
        qr/Not sure what to do with arg/,
        "a scalar ref is rejected by parse",
    );

    my $users = DBIx::QuickORM::Schema::Table->new(name => 'users', columns => {user_id => col('user_id', 1)});
    like(
        dies { DBIx::QuickORM::Link->parse($users, \'posts') },
        qr/Not sure what to do with arg/,
        "a scalar ref is rejected even with a source",
    );
};

subtest resolve_link => sub {
    my $source = DBIx::QuickORM::Schema::Table->new(
        name => 'users', columns => {user_id => col('user_id', 1)},
    );

    my $by_alias = link_obj(local_table => 'users', other_table => 'posts', local_columns => ['user_id'], aliases => ['posts_alias']);
    my $by_cols  = link_obj(local_table => 'users', other_table => 'comments', local_columns => ['user_id']);
    push @{$source->links} => $by_alias, $by_cols;

    is($source->resolve_link($by_alias)->other_table, 'posts', "resolve_link returns an existing Link object as-is");

    # A bare string is a fuzzy lookup: alias, then table name, then key.
    is($source->resolve_link('posts_alias')->other_table, 'posts', "fuzzy string matches an alias");
    is($source->resolve_link('posts')->other_table, 'posts', "fuzzy string matches a table name");

    # Keyword forms force a specific dimension instead of the fuzzy match.
    is($source->resolve_link(alias => 'posts_alias')->other_table, 'posts', "keyword alias => forces an alias match");
    is($source->resolve_link(table => 'posts')->other_table, 'posts', "keyword table => forces a destination-table match");

    # The by-columns path derives a key via column_key and matches against the
    # cached per-table key index. Columns are scoped to a table.
    my $by_columns = $source->resolve_link(table => 'posts', columns => ['user_id']);
    is($by_columns->other_table, 'posts', "resolve_link by table + columns (column_key path)");
    is($by_columns->key, column_key('user_id'), "by-columns resolution matched on the column key");

    like(
        dies { $source->resolve_link('does_not_exist') },
        qr/Could not resolve link/,
        "resolve_link croaks when nothing matches",
    );
};

subtest resolve_link_ambiguous => sub {
    my $source = DBIx::QuickORM::Schema::Table->new(
        name => 'src', columns => {a => col('a', 1), b => col('b', 2)},
    );
    push @{$source->links} => (
        link_obj(local_table => 'src', other_table => 'other', local_columns => ['a'], other_columns => ['x']),
        link_obj(local_table => 'src', other_table => 'other', local_columns => ['b'], other_columns => ['y']),
    );

    like(
        dies { $source->resolve_link('other') },
        qr/Ambiguous link specification/,
        "resolve_link croaks and lists candidates when two links match a table with no alias",
    );

    # Disambiguating by columns picks the right one.
    my $picked = $source->resolve_link(table => 'other', columns => ['a']);
    is($picked->local_columns, ['a'], "ambiguity resolved by supplying the column set");
};

done_testing;
