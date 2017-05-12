use lib 'inc';
use Test::More;
use Cwd;
use File::Path;

plan(tests => 9);

my $cwd = cwd;
rmtree('t/kwiki');
ok(mkdir 't/kwiki', 0777);
ok(chdir 't/kwiki');
ok(system("PERL5LIB=../../blib/lib;../../blib/script/kwiki-install") == 0);
ok(-f 'config.yaml');
ok(-d 'database');
ok(-f 'database/HomePage');
ok(-f 'database/KwikiFormattingRules');
ok(-f 'database/KwikiHelpIndex');
ok(chdir $cwd);
