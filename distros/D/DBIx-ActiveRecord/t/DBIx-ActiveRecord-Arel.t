use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok('DBIx::ActiveRecord::Arel');
    use_ok('DBIx::ActiveRecord::Arel::Native');
};

{
    my $post = DBIx::ActiveRecord::Arel->create('posts');
    my $user = DBIx::ActiveRecord::Arel->create('users');
    my $comment = DBIx::ActiveRecord::Arel->create('comments');

    sub join_user_post {
        shift->left_join(shift, {foreign_key => 'user_id', primary_key => 'id'});
    }
    sub join_post_user {
        shift->inner_join(shift, {foreign_key => 'user_id', primary_key => 'id'});
    }
    sub join_post_comment {
        shift->left_join(shift, {foreign_key => 'post_id', primary_key => 'id'});
    }
    sub join_comment_post {
        shift->inner_join(shift, {foreign_key => 'post_id', primary_key => 'id'});
    }
    sub join_comment_user {
        shift->inner_join(shift, {foreign_key => 'user_id', primary_key => 'id'});
    }

    # where
    my $scope = $user->eq(id => 1);
    is $scope->to_sql, 'SELECT * FROM users WHERE id = ?';
    is_deeply [$scope->binds], [1];

    # multi where
    $scope = $user->eq(id => 1)->eq(name => 'test');
    is $scope->to_sql, 'SELECT * FROM users WHERE id = ? AND name = ?';
    is_deeply [$scope->binds], [1, 'test'];

    $scope = $user->eq(id => 1)->eq(id => 2);
    is $scope->to_sql, 'SELECT * FROM users WHERE id = ? AND id = ?';
    is_deeply [$scope->binds], [1,2];

    # join
    $scope = join_user_post($user, $post);
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id';
    is_deeply [$scope->binds], [];

    # join 2
    $scope = join_post_user($post, $user);
    is $scope->to_sql, 'SELECT posts.* FROM posts INNER JOIN users ON users.id = posts.user_id';
    is_deeply [$scope->binds], [];

    # join and where
    $scope = join_user_post($user, $post)->eq(name => 'test');
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id WHERE users.name = ?';
    is_deeply [$scope->binds], ['test'];

    # join and multi where
    $scope = join_user_post($user, $post)->eq(name => 'test')->eq(type => 0);
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id WHERE users.name = ? AND users.type = ?';
    is_deeply [$scope->binds], ['test', 0];

    # merge
    my $post_scope = $post->eq(title => 'hogehoge');
    $scope = join_user_post($user, $post)->merge($post_scope);
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id WHERE posts.title = ?';
    is_deeply [$scope->binds], ['hogehoge'];

    # double merge
    $scope = join_user_post($user, $post)->merge($user->eq(type => 1))->merge($post->eq(published => 1)->eq(deleted => 0));
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id WHERE users.type = ? AND posts.published = ? AND posts.deleted = ?';
    is_deeply [$scope->binds], [1, 1, 0];


    # operators eq, ne, in, not_in
    $scope = $user->eq(id => 1)->ne(hoge => 'hoge')->in(fuga => [1,2,3,4])->not_in(bura => [1,2,3,4,5,6,7,8,9]);
    is $scope->to_sql, 'SELECT * FROM users WHERE id = ? AND hoge != ? AND fuga IN (?, ?, ?, ?) AND bura NOT IN (?, ?, ?, ?, ?, ?, ?, ?, ?)';
    is_deeply [$scope->binds], [1, 'hoge', 1, 2, 3, 4, 1,2,3,4,5,6,7,8,9];

    # operators null, not_null
    $scope = $post->null('title')->not_null('description');
    is $scope->to_sql, 'SELECT * FROM posts WHERE title IS NULL AND description IS NOT NULL';
    is_deeply [$scope->binds], [];

    # operators gt, lt, ge, le
    $scope = $post->gt(created_at => '2010-10-10')->lt(updated_at => '2010-10-11')->ge(uid => 1)->le(uid => 10);
    is $scope->to_sql, 'SELECT * FROM posts WHERE created_at > ? AND updated_at < ? AND uid >= ? AND uid <= ?';
    is_deeply [$scope->binds], ['2010-10-10', '2010-10-11', 1, 10];

    # operators like, contains, starts_with, ends_with
    $scope = $user->like(profile => '_HOGE')->contains(name => 'AA')->starts_with(uid => '10')->ends_with(uid => '99');
    is $scope->to_sql, 'SELECT * FROM users WHERE profile LIKE ? AND name LIKE ? AND uid LIKE ? AND uid LIKE ?';
    is_deeply [$scope->binds], ['_HOGE', '%AA%', '10%', '%99'];

    # operator between
    $scope = $user->between('uid', 1, 100);
    is $scope->to_sql, 'SELECT * FROM users WHERE uid >= ? AND uid <= ?';
    is_deeply [$scope->binds], [1, 100];

    # select
    $scope = $user->select('id', 'name');
    is $scope->to_sql, 'SELECT id, name FROM users';
    is_deeply [$scope->binds], [];

    # join and select
    $scope = join_user_post($user, $post)->select('id', 'name');
    is $scope->to_sql, 'SELECT users.id, users.name FROM users LEFT JOIN posts ON posts.user_id = users.id';
    is_deeply [$scope->binds], [];

    # multi table select
    $scope = join_user_post($user, $post)->select('id', 'name')->merge($post->select('id', 'title'));
    is $scope->to_sql, 'SELECT users.id, users.name, posts.id, posts.title FROM users LEFT JOIN posts ON posts.user_id = users.id';
    is_deeply [$scope->binds], [];

    # limit offset
    $scope = $user->limit(10)->offset(20);
    is $scope->to_sql, 'SELECT * FROM users LIMIT ? OFFSET ?';
    is_deeply [$scope->binds], [10, 20];

    # lock
    $scope = $user->lock;
    is $scope->to_sql, 'SELECT * FROM users FOR UPDATE';
    is_deeply [$scope->binds], [];

    # group
    $scope = $user->group('id');
    is $scope->to_sql, 'SELECT * FROM users GROUP BY id';
    is_deeply [$scope->binds], [];

    # order
    $scope = $user->desc('created_at')->asc('id');
    is $scope->to_sql, 'SELECT * FROM users ORDER BY created_at DESC, id';
    is_deeply [$scope->binds], [];

    # reorder
    $scope = $user->desc('created_at')->asc('id')->reorder->desc('id');
    is $scope->to_sql, 'SELECT * FROM users ORDER BY id DESC';
    is_deeply [$scope->binds], [];

    # join group
    $scope = join_user_post($user, $post)->merge($post->group('type'))->group('id');
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id GROUP BY posts.type, users.id';
    is_deeply [$scope->binds], [];

    # join order
    $scope = join_user_post($user, $post)->desc('created_at')->merge($post->asc('id'));
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id ORDER BY users.created_at DESC, posts.id';
    is_deeply [$scope->binds], [];

    # having
    # NOW, etc.. sql function
    $scope = $user->select(DBIx::ActiveRecord::Arel::Native->new('MAX(*)'))->group('type');
    is $scope->to_sql, 'SELECT MAX(*) FROM users GROUP BY type';
    is_deeply [$scope->binds], [];

    $scope = join_user_post($user->select(DBIx::ActiveRecord::Arel::Native->new('MAX(*)')), $post)->group('type');
    is $scope->to_sql, 'SELECT MAX(*) FROM users LEFT JOIN posts ON posts.user_id = users.id GROUP BY users.type';
    is_deeply [$scope->binds], [];

    # update
    $scope = $user->eq(id => 3)->update({hoge => 1});
    is $scope->to_sql, 'UPDATE users SET hoge = ? WHERE id = ?';
    is_deeply [$scope->binds], [1,3];

    # insert
    $scope = $user->insert({name => 'hoge', profile => 'hogehoge'});
    is $scope->to_sql, 'INSERT INTO users (profile, name) VALUES (?, ?)';
    is_deeply [$scope->binds], ['hogehoge', 'hoge'];

    # delete
    $scope = $user->in(id => [1,2,3])->delete;
    is $scope->to_sql, 'DELETE FROM users WHERE id IN (?, ?, ?)';
    is_deeply [$scope->binds], [1,2,3];

    # where
    $scope = $user->where("id = ? and name = ?", 5, 'hoge');
    is $scope->to_sql, 'SELECT * FROM users WHERE id = ? and name = ?';
    is_deeply [$scope->binds], [5, 'hoge'];

    # join where
    $scope = join_user_post($user, $post)->where("name = ?", 'fuga')->merge($post->where('name2 = ?', 'hoge')->eq(id => 45));
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id WHERE name = ? AND name2 = ? AND posts.id = ?';
    is_deeply [$scope->binds], ['fuga', 'hoge', 45];

    # count
    $scope = $user->eq(type => 'AA')->count;
    is $scope->to_sql, 'SELECT COUNT(*) FROM users WHERE type = ?';
    is_deeply [$scope->binds], ['AA'];

    # nested join
    $scope = join_post_comment($post, $comment);
    is $scope->to_sql, 'SELECT posts.* FROM posts LEFT JOIN comments ON comments.post_id = posts.id';

    $scope = join_user_post($user, $post)->merge(join_post_comment($post, $comment));
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id LEFT JOIN comments ON comments.post_id = posts.id';

    $scope = $scope->merge($comment->eq(content => 'hoge'));
    is $scope->to_sql, 'SELECT users.* FROM users LEFT JOIN posts ON posts.user_id = users.id LEFT JOIN comments ON comments.post_id = posts.id WHERE comments.content = ?';
    is_deeply [$scope->binds], ['hoge'];

    # table as
    $scope = $post->as('me');
    is $scope->to_sql, 'SELECT * FROM posts';
    is_deeply [$scope->binds], [];

    $scope = join_post_user($post->as("me"), $user->as('user'));
    is $scope->to_sql, 'SELECT me.* FROM posts me INNER JOIN users user ON user.id = me.user_id';
    is_deeply [$scope->binds], [];

    # sub query
    $scope = $user->in(id => $post->select('user_id')->eq(type => 2)->eq(deleted => 1))->eq(deleted => 0);
    is $scope->to_sql, 'SELECT * FROM users WHERE id IN (SELECT user_id FROM posts WHERE type = ? AND deleted = ?) AND deleted = ?';
    is_deeply [$scope->binds], [2, 1, 0];
}

done_testing;
