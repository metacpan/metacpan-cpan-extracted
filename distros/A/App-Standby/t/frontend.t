#!perl -T

use strict;
use warnings;
use Test::More;
use File::Temp;
use Config::Yak;
use Test::MockObject::Universal;
use Plack::Test;
use HTTP::Request::Common;

use App::Standby::Cmd;
use App::Standby::Frontend;
use App::Standby::Cmd::Command::bootstrap;

my $tempdir = File::Temp::tempdir( CLEANUP => 1);
my $Config  = Config::Yak::->new({ locations => [$tempdir]});
my $MOU  = Test::MockObject::Universal->new();

$Config->set('App::Standby::DBFile',$tempdir.'/db.sqlite3');

my $appl = App::Standby::Cmd->new();

my $bs = App::Standby::Cmd::Command::bootstrap->new({
    'app'       => $appl,
    'usage'     => $MOU,
    '_config'    => $Config,
    '_logger'    => $MOU,
    'name'      => 'Test',
    'key'       => 'test',
});

isa_ok($bs,'App::Standby::Cmd::Command::bootstrap');
ok($bs->execute(),'Bootstrap ran');

my $Frontend = App::Standby::Frontend::->new({
    'config'    => $Config,
    'logger'    => $MOU,
});

my $app = sub { my $env = shift; return $Frontend->run($env); };

test_psgi $app, sub {
    my $cb  = shift;

    # frontpage works
    my $res = $cb->(GET '/', );
    is($res->code, 200, 'Got expected content');

    # overview works, bootstraped group exists
    $res = $cb->(GET '/?rm=overview',);
   like($res->content, qr/Current order/, 'Overview is displayed');

   # manage groups works
   $res = $cb->(GET '/?rm=list_groups',);
   like($res->content, qr/Groups configured/, 'Group page is displayed');

    # adding contact fails w/o group key
    $res = $cb->(POST '/', [
        rm          => 'insert_contact',
        'group_id'  => 1,
        'name'      => 'Testcontact',
        'cellphone' => '01234567890',
        'group_key' => '',
    ]);
    ok($res->is_redirect, 'Redirect after create');
    like($res->header('Location'), qr/Invalid...Key/, 'Error due to invalid key');

    # adding contact succeeds w/ correct key
    $res = $cb->(POST '/', [
        rm          => 'insert_contact',
        'group_id'  => 1,
        'name'      => 'Testcontact',
        'cellphone' => '01234567890',
        'group_key' => 'test',
    ]);

    ok($res->is_redirect, 'Redirect after create');
    unlike($res->header('Location'), qr/Invalid...Key/, 'No error due to invalid key');

    # contacts page for group 1 lists the new contact
    $res = $cb->(GET '/?rm=list_contacts&group_id=1',);
    like($res->content, qr/Testcontact/, 'User Testcontact exists in group 1');

    # adding config item succeeds w/ correct key
    $res = $cb->(POST '/', [
        rm          => 'insert_config',
        'group_id'  => 1,
        'key'      => 'ms_endpoint',
        'value' => 'http://localhost/ms/',
        'group_key' => 'test',
    ]);
    ok($res->is_redirect, 'Redirect after create');
    unlike($res->header('Location'), qr/Invalid...Key/, 'No error due to invalid key');

    # config page for group 1 lists the new item
    $res = $cb->(GET '/?rm=list_config&group_id=1',);
    like($res->content, qr/ms_endpoint/, 'Config item ms_endpoint exists in group 1');

    # adding service succeeds w/ correct key
    $res = $cb->(POST '/', [
        rm          => 'insert_service',
        'group_id'  => 1,
        'name'      => 'ms',
        'description' => 'Monitoring::Spooler',
        'class' => 'MS',
        'group_key' => 'test',
    ]);
    ok($res->is_redirect, 'Redirect after create');
    unlike($res->header('Location'), qr/Invalid...Key/, 'No error due to invalid key');

    # config page for group 1 lists the new item
    $res = $cb->(GET '/?rm=list_services&group_id=1',);
    like($res->content, qr/App::Standby::Service::MS/, 'Config item ms_endpoint exists in group 1');
};

done_testing();

