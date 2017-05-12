use strict;
use warnings;

use lib qw( ../lib );

use AproJo;
use AproJo::DB::Schema;
use AproJo::Command::setup;

use Mojo::JSON qw(decode_json encode_json);

use Test::More;
END { done_testing(); }

use Test::Mojo;

my $db = AproJo::DB::Schema->connect('dbi:SQLite:dbname=:memory:');

AproJo::Command::setup->inject_sample_data('admin', 'pass', 'Joe Admin', $db);

ok($db->resultset('User')->single({name => 'admin'}), 'DB user exists');

is($db->resultset('User')->single({name => 'admin'})->password(),'pass','DB user has password');

ok($db->resultset('Role')->single({name => 'admin'}), 'DB role exists');

my $admin = $db->resultset('User')->single({name => 'admin'});
my $admin_id = $admin->user_id();

my $role = $db->resultset('Role')->single({name => 'admin'});
my $role_id = $role->role_id();

my $userroles = $db->resultset('UserRole')->search({user_id => $admin_id,role_id => $admin_id});

ok($userroles, 'admin has UserRole');

my $adminroles = $admin->roles();

my $adminrolename = $admin->roles()->single({name => 'admin'})->name();

while (my $adminrole = $adminroles->next) {
  my $rolename = $db->resultset('Role')->single({role_id => $adminrole->role_id})->name();
}


my $t = Test::Mojo->new(AproJo->new(db => $db));
$t->ua->max_redirects(2);

subtest 'Static File' => sub {
  $t->get_ok('/robots.txt')->status_is(200);
};

subtest 'Serverinfo' => sub {
  $t->get_ok('/serverinfo')->status_is(200)->text_is(h1 => 'Serverinfo');
};

subtest 'DBInfo' => sub {
  $t->get_ok('/dbinfo')->status_is(200)->text_is(h1 => 'Database Information');
};

subtest 'Anonymous User' => sub {
  $t->get_ok('/')->status_is(200)->text_is(h2 => 'Testpage for AproJo')
    ->element_exists('a');

  $t->get_ok('/page/doesntexist')->status_is(404);
};

subtest 'Anonymous User front/' => sub {
  $t->get_ok('/front/index')->status_is(200)->text_is(h2 => 'Testpage for AproJo')
    ->element_exists('a');

  #$t->get_ok('/front/doesntexist')->status_is(404);
};

subtest 'Do Login' => sub {

  # fail username
  $t->post_ok('/login' =>
      form => {from => '/', username => 'wronguser', password => 'pass'})
    ->status_is(200);

  # fail password
  $t->post_ok('/login' =>
      form => {from => '/', username => 'admin', password => 'wrongpass'})
    ->status_is(200);

  # successfully login
  $t->post_ok('/login' =>
      form => {username => 'admin', password => 'pass'})
    ->status_is(200)
    ->text_like(span => qr/.*admin.*/)
    ->text_like( 'a[href*="logout"]' => qr/Logout/ );

};

subtest 'Logging Out' => sub {
  # This is essentially a repeat of the first test
  $t->get_ok('/logout')
    ->status_is(200)
    ->text_like( 'a[href*="login"]' => qr/Login/ );
};

=comment




subtest 'Edit Page' => sub {

  # page editor
  $t->get_ok('/edit/home')
    ->status_is(200)
    ->text_like( '#wmd-input' => qr/Welcome to AproJo!/ )
    ->element_exists( '#wmd-preview' );

  # save page
  my $text = 'I changed this text';
  my $data = encode_json({
    name  => 'home',
    title => 'New Home',
    html  => "<p>$text</p>",
    md    => $text,
  });
  $t->websocket_ok( '/store/page' )
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  # see that the changes are reflected
  $t->get_ok('/page/home')
    ->status_is(200)
    ->text_is( h1 => 'New Home' )
    ->text_like( p => qr/$text/ );

  # author request non-existant page => create new page
  $t->get_ok('/page/doesntexist')
    ->status_is(200)
    ->text_like( '#wmd-input' => qr/Hello World/ )
    ->element_exists( '#wmd-preview' );

  # save page without title (error)
  my $data_notitle = encode_json({
    name  => 'notitle',
    title => '',
    html  => '<p>Hmmm no title</p>',
    md    => 'Hmmm no title',
  });
  $t->websocket_ok( '/store/page' )
    ->send_ok( $data_notitle )
    ->message_is( 'Not saved! A title is required!' )
    ->finish_ok;

};

subtest 'Edit Main Navigation Menu' => sub {
  my $title = 'About AproJo';

  # check about page is in nav 
  $t->get_ok('/admin/menu')
    ->status_is(200)
    ->text_is( 'ul#main > li:nth-of-type(3) > a' => $title )
    ->text_is( '#list-active-pages > #pages-2 > span' => $title );

  # remove about page from list
  my $data = encode_json({
    name => 'main',
    list => [],
  });
  $t->websocket_ok('/store/menu')
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  # check that item is removed
  $t->get_ok('/admin/menu')
    ->status_is(200)
    ->element_exists_not( 'ul#main > li:nth-of-type(3) > a' )
    ->text_is( '#list-inactive-pages > #pages-2 > span' => $title );

  # put about page back
  $data = encode_json({
    name => 'main',
    list => ['pages-2'],
  });
  $t->websocket_ok('/store/menu')
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  # check about page is back in nav (same as first test block)
  $t->get_ok('/admin/menu')
    ->status_is(200)
    ->text_is( 'ul#main > li:nth-of-type(3) > a' => $title )
    ->text_is( '#list-active-pages > #pages-2 > span' => $title );

};

subtest 'Administrative Overview: All Users' => sub {

  # test the admin pages
  $t->get_ok('/admin/users')
    ->status_is(200)
    ->text_is( h1 => 'Administration: Users' )
    ->text_is( 'tr > td:nth-of-type(2)' => 'admin' )
    ->text_is( 'tr > td:nth-of-type(3)' => 'Joe Admin' );

};

subtest 'Administrative Overview: All Pages' => sub {

  $t->get_ok('/admin/pages')
    ->status_is(200)
    ->text_is( h1 => 'Administration: Pages' )
    ->text_is( 'tr > td:nth-of-type(2)' => 'home' );

  # attempt to remove home page
  $t->websocket_ok('/remove/page')
    ->send_ok('1')
    ->message_like( qr'Cannot remove home page' )
    ->finish_ok;

  # attempt to remove invalid page
  $t->websocket_ok('/remove/page')
    ->send_ok('5')
    ->message_like( qr'Could not access page' )
    ->finish_ok;

  # remove page
  $t->websocket_ok('/remove/page')
    ->send_ok('2')
    ->message_like( qr'Page removed' )
    ->finish_ok;

};

subtest 'Administer Users' => sub {

  $t->get_ok('/admin/user/admin')
    ->status_is(200)
    ->element_exists( 'input#name[placeholder=admin]' )
    ->element_exists( 'input#full[value="Joe Admin"]' )
    ->element_exists( 'input#is_author[checked=1]' )
    ->element_exists( 'input#is_admin[checked=1]' );

  # change name
  my $data = encode_json({
    name => "admin",
    full => "New Name",
    is_author => 1,
    is_admin => 1,
  });
  $t->websocket_ok('/store/user')
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  # check that the name change is reflected
  $t->get_ok('/admin/user/admin')
    ->status_is(200)
    ->element_exists( 'input#name[placeholder=admin]' )
    ->element_exists( 'input#full[value="New Name"]' );

  # attempt to change password, incorrectly
  $data = encode_json({
    name => "admin",
    full => "New Name",
    pass1 => 'newpass',
    pass2 => 'wrongpass',
    is_author => 1,
    is_admin => 1,
  });
  $t->websocket_ok('/store/user')
    ->send_ok( $data )
    ->message_is( 'Not saved! Passwords do not match' )
    ->finish_ok;

  ok( $t->app->get_user('admin')->check_password('pass'), 'Password not changed on non-matching passwords');

  # change password, correctly
  $data = encode_json({
    name => "admin",
    full => "New Name",
    pass1 => 'newpass',
    pass2 => 'newpass',
    is_author => 1,
    is_admin => 1,
  });
  $t->websocket_ok('/store/user')
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  ok( $t->app->get_user('admin')->check_password('newpass'), 'New password checks out');

};

subtest 'Create New User' => sub {

  # attempt to create a user without providing a password (fails)
  my $data = encode_json({
    name => "someone",
    full => "Jane Dow",
    is_author => 1,
    is_admin => 0,
  });
  $t->websocket_ok('/store/user')
    ->send_ok( $data )
    ->message_is( 'Cannot create user without a password' )
    ->finish_ok;

  # create a user
  $data = encode_json({
    name => "someone",
    full => "Jane Doe",
    pass1 => 'mypass',
    pass2 => 'mypass',
    is_author => 1,
    is_admin => 0,
  });
  $t->websocket_ok('/store/user')
    ->send_ok( $data )
    ->message_is( 'Changes saved' )
    ->finish_ok;

  # check the new user
  $t->get_ok('/admin/user/someone')
    ->status_is(200)
    ->element_exists( 'input#name[placeholder=someone]' )
    ->element_exists( 'input#full[value="Jane Doe"]' )
    ->element_exists( 'input#is_author:checked' )
    ->element_exists( 'input#is_admin:not(:checked)' );

};

subtest 'Logging Out' => sub {
  # This is essentially a repeat of the first test
  $t->get_ok('/logout')
    ->status_is(200)
    ->text_is( h1 => 'New Home' )
    ->element_exists( 'form' );
};

