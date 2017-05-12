#!perl -T

use strict;
use warnings;
use Test::More;
use File::Temp;
use Config::Yak;
use Test::MockObject::Universal;
use App::Standby::Cmd;
use App::Standby::Cmd::Command::bootstrap;

my $tempdir = File::Temp::tempdir( CLEANUP => 1);
my $Config  = Config::Yak::->new({ locations => [$tempdir]});
my $MOU  = Test::MockObject::Universal->new();

$Config->set('App::Standby::DBFile',$tempdir.'/db.sqlite3');

my $app = App::Standby::Cmd->new();

my $bs = App::Standby::Cmd::Command::bootstrap->new({
    'app'       => $app,
    'usage'     => $MOU,
    '_config'    => $Config,
    '_logger'    => $MOU,
    'name'      => 'Test',
    'key'       => 'test',
});

isa_ok($bs,'App::Standby::Cmd::Command::bootstrap');
ok($bs->execute(),'Bootstrap ran');

my $sql = 'SELECT COUNT(*) FROM groups WHERE name = ? AND key = ?';
my $sth = $bs->dbh()->prepexec($sql,'Test','test');
ok($sth->execute());
my $cnt = $sth->fetchrow_array();
is($cnt,1,'Got exactly one matching group');
$sth->finish();

done_testing();