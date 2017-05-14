#! perl

use Test::More tests => 9;
use Config::IniFiles;
use lib qw(. t);

BEGIN { use_ok("TestConfigIniFiles"); };

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

my $app = TestConfigIniFiles->new();
isa_ok($app,"TestConfigIniFiles");

my $out = $app->run;
#diag("\n" . $out);

ok($out =~ m#^Content-Type:#,"header");
ok($out =~ m#^title="Main title"#m,"main title");
ok($out =~ m#^dbs=main,test#m,"db list");

my $cfg = Config::IniFiles->new(
  -file => -f "test.conf" ? "test.conf" : "../test.conf"
);

$app = TestConfigIniFiles->new(
  PARAMS => { config_object => $cfg },
);

isa_ok($app,"TestConfigIniFiles");

$out = $app->run;
#diag("\n" . $out);

ok($out =~ m#^Content-Type:#,"header");
ok($out =~ m#^title="Main title"#m,"main title");
ok($out =~ m#^dbs=main,test#m,"db list");

exit;

### That's all, folks!
