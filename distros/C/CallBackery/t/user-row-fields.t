use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use Mojo::Util qw(hmac_sha1_sum);

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my $db = $t->app->database;
my $admin = $db->updateOrInsertData('cbuser',{login => 'root', family => 'R', given => 'R', password => hmac_sha1_sum('rootpw'), note => 'root note'});
$db->updateOrInsertData('cbuserright',{cbuser => $admin, cbright => $db->lookUp('cbright','key','admin')});
my $bob = $db->updateOrInsertData('cbuser',{login => 'bob', family => 'B', given => 'B', password => hmac_sha1_sum('bobpw'), note => 'admin only'});

my $id = 0;
my $cookie = $t->post_ok('/QX-JSON-RPC' => json => {jsonrpc => '2.0', id => ++$id, method => 'login', params => ['bob','bobpw']})
    ->tx->res->json('/result/sessionCookie');
my %rpc = (
    'getUserConfig' => [{}],
    'getPluginData Users' => ['Users','tableData',{firstRow => 0, lastRow => 10}],
    'getPluginData Users_edit' => ['Users_edit','allFields',{selection => {cbuser_id => $bob}}],
);
my %res = map {
    my ($method) = split / /;
    ($_ => $t->post_ok('/QX-JSON-RPC' => {'X-Session-Cookie' => $cookie}
        => json => {jsonrpc => '2.0', id => ++$id, method => $method, params => $rpc{$_}})->tx->res->json('/result'))
} sort keys %rpc;

is $res{getUserConfig}{userInfo}{cbuser_login}, 'bob', 'getUserConfig returns the user';
ok !exists $res{getUserConfig}{userInfo}{cbuser_password}, 'getUserConfig does not return the password hash';
is_deeply [map { ($_->{cbuser_login}, exists $_->{cbuser_note} ? 'note' : 'no note') }
        $res{getUserConfig}{userInfo}, $res{'getPluginData Users'}[0], $res{'getPluginData Users_edit'}],
    [('bob','no note') x 3], 'a non-admin does not receive the admin-only note';

my $rootCookie = $t->post_ok('/QX-JSON-RPC' => json => {jsonrpc => '2.0', id => ++$id, method => 'login', params => ['root','rootpw']})
    ->tx->res->json('/result/sessionCookie');
is $t->post_ok('/QX-JSON-RPC' => {'X-Session-Cookie' => $rootCookie}
        => json => {jsonrpc => '2.0', id => ++$id, method => 'getUserConfig', params => [{}]})->tx->res->json('/result/userInfo/cbuser_note'),
    'root note', 'an admin still receives the note';

done_testing();
