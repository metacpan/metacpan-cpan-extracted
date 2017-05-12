use strict;
use Test::More;
use App::makedpkg;

use lib 't/lib';
use App::makedpkg::Tester;

mkdir path("makedpkg"); # implicit template directory

my $common_output = "\nverbose: 1\n---\nbuilding into debuild\nexec debuild";

makedpkg '-n';
ok exit_code;
is error, "error reading config file ", "error reading config file ";

makedpkg qw(--config notfound.yml -n);
ok exit_code;
is error, "error reading config file notfound.yml", "error reading config file notfound.yml";

write_yaml "malformed.yml", ".";

makedpkg qw(--config malformed.yml -n);
ok exit_code;
is error, "error reading config file malformed.yml", "error reading config file malformed.yml";

write_yaml "ok.yml", "foo: bar";
makedpkg qw(--config ok.yml --verbose -n);
ok !exit_code;
is output, "---\nfoo: bar$common_output";

write_yaml "makedpkg.yml", "foo: '`pwd`'";
makedpkg qw(--verbose -n);
ok !exit_code;
is output, "---\nfoo: ".path.$common_output, "expanded config";

write_yaml "makedpkg.yml", "foo:\n  bar: '`pwd`'";
makedpkg qw(--verbose -n);
ok !exit_code;
is output, "---\nfoo:\n  bar: ".path.$common_output, "expanded config deeply";

write_yaml "makedpkg.yml", "foo: '`rm /dev/null`'";
makedpkg qw(--verbose -n);
ok exit_code;
is error, "`rm /dev/null` died with exit code 1";

makedpkg '-t',path("notfound"),'-n';
ok exit_code;
is error, "error reading template directory ".path("notfound"), "error reading template directory";

done_testing;
