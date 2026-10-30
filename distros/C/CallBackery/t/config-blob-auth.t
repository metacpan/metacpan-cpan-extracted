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

$db->setConfigValue('blobProbe','saved');
my $blob = $cfg->getConfigBlob('hunter2');
isnt $cfg->getConfigBlob('hunter2'), $blob,
    'two backups of the same data are not identical';
$db->setConfigValue('blobProbe','changed');

ok !eval { $cfg->restoreConfigBlob($blob,'hunter2x'); 1 },
    'a password that only adds the old padding character is refused';
like "$@", qr/Wrong password/, 'with the wrong password error';
my $tampered = $blob;
substr($tampered,-1,1) ^= "\x01";
ok !eval { $cfg->restoreConfigBlob($tampered,'hunter2'); 1 },
    'a modified backup is refused';
is $db->getConfigValue('blobProbe'), 'changed', 'and nothing was restored';

$cfg->restoreConfigBlob($blob,'hunter2');
is $db->getConfigValue('blobProbe'), 'saved', 'the right password restores';

# a backup made before the format change still restores, with a warning
require Archive::Zip;
my $zip = Archive::Zip->new;
$zip->addString("CREATE TABLE legacy (x);\n",'{DATABASEDUMP}');
open my $fh, '>', \my $zipData;
$zip->writeToFileHandle($fh,0);
close $fh;
my @warn;
$t->app->log->level('warn');
$t->app->log->on(message => sub { push @warn, $_[2] if $_[1] eq 'warn' });
$cfg->restoreConfigBlob($cfg->getCrypt('hunter2')->encrypt($cfg->pack16($zipData)),'hunter2');
ok scalar(grep { /old, unauthenticated format/ } @warn),
    'an old-format backup is restored with a warning to replace it';

done_testing();
