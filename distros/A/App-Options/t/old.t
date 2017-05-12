#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";
use Config;

use_ok("App::Options");

my ($dir);

$dir = ".";
$dir = "t" if (! -f "app.conf");

delete $ENV{PREFIX};
delete $ENV{DOCUMENT_ROOT};

$ENV{VAR10} = "value10";
$ENV{APP_VAR11} = "value11";
$ENV{VAR12} = "value12";

BEGIN {
    $App::options{testdir} = (-f "app.conf") ? "." : "t";
}
App::Options->_import_test(
    option => {
        var10 => { env => "VAR10a;VAR10", },
        var11 => { },
        var12 => { env => "VAR12", },
    },
);

my $prefix = $Config{prefix};
$prefix =~ s!\\!/!g;  # transform to POSIX-compliant

#print "CONF:\n   ", join("\n   ",%App::options), "\n";
ok(%App::options, "put something in %App::options");
#is($App::options{prefix}, $prefix, "prefix = $prefix");
is($App::options{app}, "old", "app = old");
is($App::options{var}, "value", "var = value");
is($App::options{var1}, "pattern match", "pattern match");
is($App::options{var2}, "old pattern match", "old pattern match");
is($App::options{htdocs_dir}, "/usr/local/htdocs", "variable substitution");
is($App::options{cgibin_dir}, "/usr/local/cgi-bin", "variable substitution (default used)");
is($App::options{template_dir}, "/usr/local/template", "variable substitution (default supplied but not used)");
is($App::options{greeting}, "Hello", "variable substitution (var name used since var not defined)");
is($App::options{var3}, "value3", "inline pattern match");
is($App::options{var4}, undef,    "section excluded");
is($App::options{var5}, "value5", "section exclusion ended");
is($App::options{var6}, undef,    "section excluded again");
is($App::options{var9}, "value9", "section included");
is($App::options{var7}, "value7", "section included (regexp)");
is($App::options{var8}, "value8", "ALL works");
is($App::options{var11}, "value11", "default env var works");
is($App::options{var12}, "value12", "specified env var works");
is($App::options{var10}, "value10", "specified secondary env var works");

%App::options = (
    config_file => "$dir/app.conf",
    prefix => "/usr/local",
    perlinc => "/usr/mycompany/2.1.7/lib/perl5",
    testdir => (-f "app.conf") ? "." : "t",
);

App::Options->_import_test();
#print "CONF:\n   ", join("\n   ",%App::options), "\n";
ok(%App::options, "put something in %App::options");
is($App::options{prefix}, "/usr/local", "prefix = /usr/local");
is($App::options{app}, "old", "app = old");
is($App::options{var}, "value", "var = value");
is($App::options{var1}, "pattern match", "pattern match");
is($App::options{var2}, "old pattern match", "old pattern match");
is($INC[0], "/usr/mycompany/2.1.7/lib/perl5", "\@INC affected by perlinc");

$App::otherconf{testdir} = (-f "app.conf") ? "." : "t";
App::Options->_import_test(\%App::otherconf);
#print "CONF:\n   ", join("\n   ",%App::otherconf), "\n";
ok(%App::otherconf, "put something in %App::otherconf");
is($App::otherconf{prefix}, $prefix, "prefix = $prefix");
is($App::otherconf{app}, "old", "app = old");
is($App::otherconf{var}, "value", "var = value");
is($App::otherconf{var1}, "pattern match", "pattern match");
is($App::otherconf{var2}, "old pattern match", "old pattern match");

$App::options3{testdir} = (-f "app.conf") ? "." : "t";
App::Options->_import_test(values => \%App::options3);
#print "CONF:\n   ", join("\n   ",%App::options3), "\n";
ok(%App::options3, "put something in %App::options3");
is($App::options3{prefix}, $prefix, "prefix = $prefix");
is($App::options3{app}, "old", "app = old");
is($App::options3{var}, "value", "var = value");
is($App::options3{var1}, "pattern match", "pattern match");
is($App::options3{var2}, "old pattern match", "old pattern match");

exit 0;

