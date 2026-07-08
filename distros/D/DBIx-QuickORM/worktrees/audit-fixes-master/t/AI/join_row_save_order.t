use Test2::V0 '!meta', '!pass';

# Regression: Join::Row save/delete used to fan out to sub-rows in hash order,
# so with foreign-key constraints a join-row delete/save failed or succeeded by
# hash seed. They now use Join::save_order (a foreign-key parent precedes its
# child), forward for save and reverse for delete.

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;
require DBIx::QuickORM::Join::Row;

my $C = 'DBIx::QuickORM::Schema::Table::Column';
sub col { $C->new(name => $_[0], order => $_[1], affinity => 'numeric') }
sub tbl { my ($n, @c) = @_; DBIx::QuickORM::Schema::Table->new(name => $n, columns => {map { $_->{name} => $_ } @c}, primary_key => [$c[0]->{name}]) }
sub names { my ($j, $order) = @_; [map { $j->{components}{$_}{table}->name } @$order] }

my $users = tbl('users', col('id', 1));
my $posts = tbl('posts', col('id', 1), col('user_id', 2));
my $tags  = tbl('tags',  col('id', 1), col('post_id', 2));
my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {users => $users, posts => $posts, tags => $tags});

subtest save_order_puts_parents_first => sub {
    # belongs-to: posts is primary, each post has one user (unique) -> user is parent.
    my $bt = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $posts)
        ->left_join(DBIx::QuickORM::Link->new(local_table => 'posts', other_table => 'users', local_columns => ['user_id'], other_columns => ['id'], unique => 1));
    is(names($bt, $bt->save_order), ['users', 'posts'], "belongs-to: parent (users) saved before child (posts)");

    # has-many: users is primary, many posts per user (non-unique) -> user is parent.
    my $hm = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $users)
        ->left_join(DBIx::QuickORM::Link->new(local_table => 'users', other_table => 'posts', local_columns => ['id'], other_columns => ['user_id'], unique => 0));
    is(names($hm, $hm->save_order), ['users', 'posts'], "has-many: parent (users) saved before child (posts)");

    # chain: posts primary -> users (parent) and posts -> tags (children of posts).
    my $chain = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $posts)
        ->left_join(DBIx::QuickORM::Link->new(local_table => 'posts', other_table => 'users', local_columns => ['user_id'], other_columns => ['id'], unique => 1))
        ->left_join(DBIx::QuickORM::Link->new(local_table => 'posts', other_table => 'tags', local_columns => ['id'], other_columns => ['post_id'], unique => 0));
    my $names = names($chain, $chain->save_order);
    my %pos = map { $names->[$_] => $_ } 0 .. $#$names;
    ok($pos{users} < $pos{posts}, "users (parent) before posts");
    ok($pos{posts} < $pos{tags},  "posts (parent) before tags (child)");
};

subtest join_row_save_delete_order => sub {
    # A mock join whose save_order is fixed; recording sub-rows capture the order.
    my @saved, my @deleted;
    my $join = do {
        package t::OrderJoin;
        sub new { bless {}, shift }
        sub save_order { ['a', 'b', 'c'] }
        __PACKAGE__->new;
    };
    my $mkrow = sub {
        my $tag = shift;
        package t::OrderRow;
        sub new { bless {tag => $_[1], s => $_[2], d => $_[3]}, $_[0] }
        sub save   { push @{$_[0]{s}} => $_[0]{tag} }
        sub delete { push @{$_[0]{d}} => $_[0]{tag} }
        t::OrderRow->new($tag, \@saved, \@deleted);
    };

    my $jr = bless {
        source   => sub { $join },
        by_alias => {a => $mkrow->('a'), b => $mkrow->('b'), c => $mkrow->('c')},
    }, 'DBIx::QuickORM::Join::Row';

    $jr->save;
    is(\@saved, ['a', 'b', 'c'], "save fans out in save_order (parents first)");

    $jr->delete;
    is(\@deleted, ['c', 'b', 'a'], "delete fans out in reverse save_order (children first)");
};

done_testing;
