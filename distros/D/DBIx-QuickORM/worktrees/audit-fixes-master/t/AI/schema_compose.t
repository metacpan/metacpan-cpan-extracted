use Test2::V0 '!meta', '!pass';
use Scalar::Util qw/refaddr/;

# Unit-level coverage for schema composition: Schema, Table, View, and Column
# clone()/merge() semantics, name vs db_name fallback, lazy affinity
# resolution, and is_view.

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::View;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;

sub col {
    my ($name, $order, %extra) = @_;
    return DBIx::QuickORM::Schema::Table::Column->new(
        name  => $name,
        order => $order,
        type  => \'integer',
        %extra,
    );
}

subtest column_affinity => sub {
    my $int = col('id', 1, type => \'INTEGER');
    is($int->affinity, 'numeric', "affinity derived from scalar-ref sql type");

    my $varchar = col('v', 1, type => \'VARCHAR(255)');
    is($varchar->affinity, 'string', "affinity strips the size qualifier from the sql type");

    require DBIx::QuickORM::Type::JSON;
    my $json = col('data', 1, type => 'DBIx::QuickORM::Type::JSON');
    is($json->affinity, 'string', "affinity derived from a type object via qorm_affinity");

    my $explicit = col('x', 1, type => undef, affinity => 'numeric');
    is($explicit->affinity, 'numeric', "explicit affinity used as-is, no type needed");

    like(
        dies { col('bad', 1, type => undef, affinity => 'sting') },
        qr/not a valid affinity/,
        "explicit affinity is validated at init",
    );

    my $cached = col('c', 1, type => \'integer');
    $cached->affinity;
    is($cached->{affinity}, 'numeric', "affinity is resolved and cached onto the column");

    like(
        dies { col('n', 1, type => undef)->affinity },
        qr/no type provided/,
        "no affinity and no type croaks",
    );

    like(
        dies { col('n', 1, type => \'NO_SUCH_TYPE_XYZ')->affinity },
        qr/could not be derived from type/,
        "an unknown sql type that yields no affinity croaks",
    );

    {
        package DBIx::QuickORM::Test::DialectAffinityType;
        use Role::Tiny::With qw/with/;
        with 'DBIx::QuickORM::Role::Type';

        sub qorm_affinity {
            my $self = shift;
            my %params = @_;
            return $params{dialect}->{numeric} ? 'numeric' : 'string';
        }
    }

    my $typed = col('typed', 1, type => bless({}, 'DBIx::QuickORM::Test::DialectAffinityType'));
    is($typed->affinity({numeric => 0}), 'string', "type-object affinity can resolve for one dialect");
    is($typed->affinity({numeric => 1}), 'numeric', "type-object affinity is not cached across dialects");
};

subtest field_type => sub {
    require DBIx::QuickORM::Type::JSON;

    my $json = bless {}, 'DBIx::QuickORM::Type::JSON';
    my $table = DBIx::QuickORM::Schema::Table->new(
        name    => 'docs',
        columns => {
            id      => col('id',      1),
            payload => col('payload', 2, type => $json),
            meta    => col('meta',    3, type => 'DBIx::QuickORM::Type::JSON'),
            raw     => col('raw',     3, type => \'TEXT'),
        },
    );

    ref_is($table->field_type('payload'), $json, "field_type returns blessed type instances");
    is($table->field_type('meta'), 'DBIx::QuickORM::Type::JSON', "field_type returns type class names");
    is($table->field_type('raw'), undef, "field_type ignores raw SQL scalar-ref types");
};

subtest table_name_db_name_fallback => sub {
    my $by_db = DBIx::QuickORM::Schema::Table->new(
        db_name => 'tbl_users',
        columns => {id => col('id', 1)},
    );
    is($by_db->name, 'tbl_users', "name falls back to db_name");
    is($by_db->db_name, 'tbl_users', "db_name is the db_name");

    my $by_name = DBIx::QuickORM::Schema::Table->new(
        name    => 'users',
        columns => {id => col('id', 1)},
    );
    is($by_name->db_name, 'users', "db_name falls back to name");
    is($by_name->name, 'users', "name is the name");

    my $both = DBIx::QuickORM::Schema::Table->new(
        name    => 'users',
        db_name => 'tbl_users',
        columns => {id => col('id', 1)},
    );
    is($both->name, 'users', "explicit name wins");
    is($both->db_name, 'tbl_users', "explicit db_name wins");

    like(
        dies { DBIx::QuickORM::Schema::Table->new(columns => {id => col('id', 1)}) },
        qr/'name' attribute is required/,
        "a table with neither name nor db_name croaks",
    );
};

subtest is_view => sub {
    my $table = DBIx::QuickORM::Schema::Table->new(name => 't', columns => {id => col('id', 1)});
    is($table->is_view, 0, "plain table is_view is false");

    my $view = DBIx::QuickORM::Schema::View->new(name => 'v', columns => {id => col('id', 1)});
    is($view->is_view, 1, "view is_view is true");
    isa_ok($view, ['DBIx::QuickORM::Schema::Table'], "a view is-a table");
};

subtest column_clone_and_merge => sub {
    my $orig = col('id', 1, type => \'integer', nullable => 1);

    my $clone = $orig->clone(name => 'id2');
    is($clone->name, 'id2', "clone applies overrides");
    is($orig->name, 'id', "original is untouched by clone");
    ok(refaddr($clone) != refaddr($orig), "clone is a distinct object");

    my $plain = $orig->clone;
    is($plain->name, 'id', "clone with no overrides copies values");

    my $other = col('id', 1, type => \'text', nullable => 0);
    my $merged = $orig->merge($other);
    is($merged->{type}, \'text', "merge: other column's values win");
    is($orig->{type}, \'integer', "original is untouched by merge");

    my $with_params = $orig->merge($other, nullable => 1);
    is($with_params->nullable, 1, "merge: explicit params win over both columns");
};

subtest table_clone_independence => sub {
    my $table = DBIx::QuickORM::Schema::Table->new(
        name        => 'a',
        columns     => {id => col('id', 1), n => col('n', 2)},
        primary_key => ['id'],
        unique      => {id => ['id']},
        indexes     => [['n']],
        links       => [
            DBIx::QuickORM::Link->new(
                local_table => 'a', local_columns => ['id'],
                other_table => 'b', other_columns => ['a_id'],
                unique => 0,
            ),
        ],
    );

    my $clone = $table->clone;

    ok(refaddr($clone->{columns}) != refaddr($table->{columns}), "columns hash is a fresh ref");
    ok(refaddr($clone->{columns}{id}) != refaddr($table->{columns}{id}), "column objects are cloned, not shared");
    ok(refaddr($clone->{unique}) != refaddr($table->{unique}), "unique hash is a fresh ref");
    ok(refaddr($clone->{primary_key}) != refaddr($table->{primary_key}), "primary_key array is a fresh ref");
    ok(refaddr($clone->{indexes}) != refaddr($table->{indexes}), "indexes array is a fresh ref");
    ok(refaddr($clone->{links}) != refaddr($table->{links}), "links array is a fresh ref");

    is([$clone->column_names], [qw/id n/], "cloned columns preserved");
    is($clone->primary_key, ['id'], "cloned primary key preserved");

    my $renamed = $table->clone(name => 'a2');
    is($renamed->name, 'a2', "clone applies table overrides");
    is($table->name, 'a', "original table untouched by clone");
};

subtest table_merge => sub {
    my $a = DBIx::QuickORM::Schema::Table->new(
        name        => 'a',
        columns     => {id => col('id', 1), n => col('n', 2)},
        primary_key => ['id'],
        unique      => {id => ['id']},
        indexes     => [['id']],
        links       => [
            DBIx::QuickORM::Link->new(
                local_table => 'a', local_columns => ['id'],
                other_table => 'b', other_columns => ['a_id'], unique => 0,
            ),
        ],
    );

    my $b = DBIx::QuickORM::Schema::Table->new(
        name    => 'a',
        columns => {n => col('n', 2, type => \'text'), extra => col('extra', 3)},
        indexes => [['n']],
        links   => [
            DBIx::QuickORM::Link->new(
                local_table => 'a', local_columns => ['id'],
                other_table => 'c', other_columns => ['a_id'], unique => 0,
            ),
        ],
    );

    my $m = $a->merge($b);

    is([$m->column_names], [qw/extra id n/], "merge unions columns from both tables");
    is($m->column('n')->{type}, \'text', "merge: other table's column wins on conflict");
    is(scalar(@{$m->indexes}), 2, "merge concatenates indexes");
    is(scalar(@{$m->{links}}), 2, "merge concatenates links");

    is([$a->column_names], [qw/id n/], "original table untouched by merge");
    is($a->column('n')->{type}, \'integer', "original column untouched by merge");
};

subtest table_merge_alias_collision => sub {
    my $db = DBIx::QuickORM::Schema::Table->new(
        name    => 'accounts',
        columns => {
            user    => col('user',    1, type => \'TEXT'),
            user_id => col('user_id', 2, type => \'INTEGER'),
        },
    );

    my $declared = DBIx::QuickORM::Schema::Table->new(
        name    => 'accounts',
        columns => {
            user => col('user', 1, db_name => 'user_id'),
        },
    );

    like(
        dies { $db->merge($declared) },
        qr/both map to ORM column 'user'/,
        "merge croaks instead of silently dropping a real column on alias collision",
    );
};

subtest link_resolution_treats_primary_key_as_unique => sub {
    my $users = DBIx::QuickORM::Schema::Table->new(
        name        => 'users',
        columns     => {id => col('id', 1)},
        primary_key => ['id'],
    );

    my $posts = DBIx::QuickORM::Schema::Table->new(
        name        => 'posts',
        columns     => {id => col('id', 1), user_id => col('user_id', 2)},
        primary_key => ['id'],
    );

    DBIx::QuickORM::Schema->new(
        name   => 'declared',
        tables => {users => $users, posts => $posts},
        _links => [
            [
                ['posts', ['user_id'], undef],
                ['users', ['id'],      undef],
                'test link',
            ],
        ],
    );

    my ($to_user) = grep { $_->other_table eq 'users' } @{$posts->links};
    my ($to_post) = grep { $_->other_table eq 'posts' } @{$users->links};

    ok($to_user->unique, "link to a declared primary key is unique even without a unique hash entry");
    ok(!$to_post->unique, "reverse link to a non-unique foreign key is not unique");
};

subtest schema_clone_and_merge => sub {
    my $users = DBIx::QuickORM::Schema::Table->new(name => 'users', columns => {id => col('id', 1)});
    my $posts = DBIx::QuickORM::Schema::Table->new(name => 'posts', columns => {id => col('id', 1)});

    my $s1 = DBIx::QuickORM::Schema->new(name => 's1', tables => {users => $users});
    my $s2 = DBIx::QuickORM::Schema->new(name => 's2', tables => {posts => $posts});

    my $merged = $s1->merge($s2);
    is([sort map { $_->name } $merged->tables], [qw/posts users/], "schema merge unions tables");
    is($merged->name, 's1', "schema merge keeps the first schema's name");

    my $clone = $s1->clone;
    ok(refaddr($clone->{tables}) != refaddr($s1->{tables}), "cloned schema gets a fresh tables hash");
    ok(refaddr($clone->{tables}{users}) != refaddr($s1->{tables}{users}), "cloned schema deep-clones its tables");
    is($clone->table('users')->name, 'users', "cloned schema preserves table");

    my $renamed = $s1->clone(name => 'renamed');
    is($renamed->name, 'renamed', "schema clone applies name override");
    is($s1->name, 's1', "original schema untouched by clone");
};

subtest schema_table_accessors => sub {
    my $users = DBIx::QuickORM::Schema::Table->new(name => 'users', columns => {id => col('id', 1)});
    my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {users => $users});

    is($schema->table('users'), $users, "table() returns the named table");
    is($schema->maybe_table('users'), $users, "maybe_table() returns the named table");
    is($schema->maybe_table('nope'), undef, "maybe_table() returns undef for an unknown table");

    like(
        dies { $schema->table('nope') },
        qr/Table 'nope' is not defined/,
        "table() croaks for an unknown table",
    );

    my $posts = DBIx::QuickORM::Schema::Table->new(name => 'posts', columns => {id => col('id', 1)});
    $schema->add_table('posts', $posts);
    is($schema->table('posts'), $posts, "add_table() adds a new table");

    like(
        dies { $schema->add_table('posts', $posts) },
        qr/Table 'posts' already defined/,
        "add_table() croaks on a duplicate table name",
    );
};

done_testing;
