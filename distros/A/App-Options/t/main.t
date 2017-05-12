#!/usr/bin/perl -w

BEGIN {
    $ENV{VAR10} = "value10";
    $ENV{APP_VAR11} = "value11";
    $ENV{VAR12} = "value12";
    $ENV{ZZ} = "zz";
    $ENV{APP_PLUGH} = "twisty passages";
    delete $ENV{PREFIX};
    delete $ENV{DOCUMENT_ROOT};
}

use Config;
use File::Spec;
use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

my ($dir);

$dir = ".";
$dir = "t" if (! -f "app.conf");

BEGIN {
    $App::options{testdir} = (-f "app.conf") ? "." : "t";
}

use App::Options (
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
is($App::options{prefix}, $prefix, "prefix = $prefix");
is($App::options{app}, "main", "app = main");
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
is($ENV{LD_LIBRARY_PATH}, "/usr/local/foo/lib", "set environment variables [$ENV{LD_LIBRARY_PATH}]");
is($App::options{continuation}, "hello, world!", "line continuation characters (\\) [$App::options{continuation}]");

#open(FILE2, "< $dir/file.txt");
#$file_txt = join("", <FILE2>);
#close(FILE2);

#is($App::options{var21}, $file_txt, "value from file");
#is($App::options{var22}, $file_txt, "value from file (2)");
#ok($App::options{var23} eq $file_txt || $App::options{var23} =~ /open/, "value from command");

#$var24 = <<EOF;
#This is text
#and more text
#EOF
#is($App::options{var24}, $var24, "value from here doc");
#is($App::options{var25}, $var24, "value from line continuations");
#is($App::options{var26}, "normal", "back to normal");

%App::options = (
    config_file => "app.conf",
    prefix => "/usr/local",
    perlinc => "/usr/mycompany/2.1.7/lib/perl5",
    testdir => (-f "app.conf") ? "." : "t",
);

App::Options->_import_test();
#print "CONF:\n   ", join("\n   ",%App::options), "\n";
ok(%App::options, "put something in %App::options");
is($App::options{prefix}, "/usr/local", "prefix = /usr/local");
is($App::options{app}, "main", "app = main");
is($App::options{var}, "value", "var = value");
is($App::options{var1}, "pattern match", "pattern match");
is($App::options{var2}, "old pattern match", "old pattern match");
is($INC[0], "/usr/mycompany/2.1.7/lib/perl5", "\@INC affected by perlinc");

$App::otherconf{testdir} = (-f "app.conf") ? "." : "t";
App::Options->_import_test(\%App::otherconf);
#print "CONF:\n   ", join("\n   ",%App::otherconf), "\n";
ok(%App::otherconf, "put something in %App::otherconf");
is($App::otherconf{prefix}, $prefix, "prefix = $prefix");
is($App::otherconf{app}, "main", "app = main");
is($App::otherconf{var}, "value", "var = value");
is($App::otherconf{var1}, "pattern match", "pattern match");
is($App::otherconf{var2}, "old pattern match", "old pattern match");

$App::options3{testdir} = (-f "app.conf") ? "." : "t";
App::Options->_import_test(values => \%App::options3);
#print "CONF:\n   ", join("\n   ",%App::options3), "\n";
ok(%App::options3, "put something in %App::options3");
is($App::options3{prefix}, $prefix, "prefix = $prefix");
is($App::options3{app}, "main", "app = main");
is($App::options3{var}, "value", "var = value");
is($App::options3{var1}, "pattern match", "pattern match");
is($App::options3{var2}, "old pattern match", "old pattern match");

# hostname/host tests
ok($App::options{hostname}, "hostname option set");
ok($App::options{host}, "host option set");
ok(length($App::options{host}) <= length($App::options{hostname}) && $App::options{host} !~ /\./,
    "host option shorter than hostname option");
ok(! defined $App::options{hosttest}, "host not named xyzzy3");

# $ENV{X} variable substitution tests
ok($App::options{envtest} eq "xyzzy", "\$ENV{X} variable substitution worked");
ok($App::options{plugh} eq "twisty passages", "auto-import of APP_ env vars worked");
ok(defined $App::options{"foo-bar"} && $App::options{"foo-bar"} eq "1", "foo-bar = 1 (dash in option key)");

exit 0;

