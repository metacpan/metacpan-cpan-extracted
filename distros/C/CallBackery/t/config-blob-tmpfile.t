use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);

plan skip_all => 'no /usr/bin/sqlite3' unless -x '/usr/bin/sqlite3';

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');
my $cfg = $t->app->config;
my $db  = $t->app->database;

unlink "/tmp/cbdump$$";
plan skip_all => "cannot remove /tmp/cbdump$$" if -e "/tmp/cbdump$$";
$db->setConfigValue('dumpProbe','before');
my $blob = $cfg->getConfigBlob('secret');
ok !-e "/tmp/cbdump$$", 'the backup leaves no database dump in /tmp';

$db->setConfigValue('dumpProbe','after');
$cfg->restoreConfigBlob($blob,'secret');
is $db->getConfigValue('dumpProbe'), 'before', 'the backup still restores';

done_testing();
