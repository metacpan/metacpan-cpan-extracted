use strict;
use warnings FATAL => 'all';

use Test::More tests => 49;
use File::Slurp;
use Apache::SWIT::Test::Utils;
use YAML;

BEGIN { use_ok('Apache::SWIT::Maker');
	use_ok('Apache::SWIT::Test::ModuleTester');
}

Apache::SWIT::Test::ModuleTester::Drop_Root();

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;

`modulemaker -I -n TTT`;
ok(-f './TTT/LICENSE');
chdir 'TTT';

Apache::SWIT::Maker->new->write_initial_files();
ok(-f "conf/startup.pl");
is(Apache::SWIT::Maker::Config->instance->app_name, 'ttt');

`./scripts/swit_app.pl add_class TTT::SomeClass`;
ok(-f 'lib/TTT/SomeClass.pm');

`./scripts/swit_app.pl add_class AnotherClass`;
ok(-f 'lib/TTT/AnotherClass.pm');

my $res = `./scripts/swit_app.pl add_class AnotherClass 2>&1`;
isnt($?, 0);
like($res, qr/refusing/);

`./scripts/swit_app.pl add_ht_page TTT::SomePage`;
ok(-f 'lib/TTT/SomePage.pm');
my @recs = `grep SomePage MANIFEST`;
is(scalar(@recs), 1);

undef $Apache::SWIT::Maker::Config::_instance;
my $e = Apache::SWIT::Maker::Config->instance->pages->{somepage};
ok($e);
$e->{ddd} = 1;
Apache::SWIT::Maker::Config->instance->save;
like(read_file('conf/swit.yaml'), qr/ddd/);

ok(-f 'templates/somepage.tt');
append_file('templates/somepage.tt', "bobo");
$res = `./scripts/swit_app.pl add_ht_page TTT::SomePage 2>&1`;
isnt($?, 0);
like(read_file('templates/somepage.tt'), qr/bobo/);
like(read_file('conf/swit.yaml'), qr/ddd/);

unlike(`diff -u Makefile.PL MANIFEST`, qr/newline/);

`./scripts/swit_app.pl add_ht_page AnotherPage`;
ok(-f 'lib/TTT/UI/AnotherPage.pm');

my $lines = `perl Makefile.PL && make install SITEPREFIX=$td/inst 2>&1`;
isnt($?, 0) or ASTU_Wait($lines);
like($lines, qr/APACHE_SWIT_DB_NAME/);
ok(-f "t/conf/schema.sql");

append_file("t/conf/schema.sql", "--moo\ncreate table btt (a text);\n");
write_file("blib/lib/G.pm", "ddd\n");
write_file("blib/v.txt", "aaa\n");

my $tree = YAML::LoadFile('conf/swit.yaml');
push @{ $tree->{skip_install} }, qw(lib/G.pm v.txt);
YAML::DumpFile('conf/swit.yaml', $tree);

$lines = `make install SITEPREFIX=$td/inst APACHE_SWIT_DB_NAME=inst510_db 2>&1`;
is($?, 0) or ASTU_Wait($lines);
unlike($lines, qr/uninitialized value/);
isnt(-d "$td/inst/share/ttt", undef);
is(-d "$td/inst/share/perl", undef);
like(read_file('t/conf/schema.sql'), qr/moo/);
is(-f "$td/inst/share/ttt/lib/G.pm", undef);
is(-f "$td/inst/share/ttt/v.txt", undef);
is(read_file("blib/lib/G.pm"), "ddd\n");
is(read_file("blib/v.txt"), "aaa\n");

like(`psql -l`, qr/inst510_db/);
append_file("lib/TTT/DB/Schema.pm", <<'ENDS');
__PACKAGE__->add_version(sub {
	shift->do("create table a (b integer)");
});
ENDS

# second time APACHE_SWIT_DB_NAME is taken from httpd.conf
$lines = `make install SITEPREFIX=$td/inst 2>&1`;
is($?, 0);

`psql -c 'select * from a' inst510_db 2>/dev/null 1>/dev/null`;
is($?, 0);

`psql -c 'select * from btt' inst510_db 2>/dev/null 1>/dev/null`;
isnt($?, 0);

ok(-f "$td/inst/share/ttt/conf/startup.pl");
ok(-f "$td/inst/share/ttt/conf/do_swit_startups.pl");

`APACHE_SWIT_DB_NAME=inst510_db perl $td/inst/share/ttt/conf/startup.pl`;
is($?, 0);

write_file("scripts/swit_app.pl", <<'ENDS');
#!/usr/bin/perl -w
use strict;
use Apache::SWIT::Maker;
use Test::TempDatabase;
my $became;
BEGIN {
	no strict 'refs';
	no warnings 'redefine';
	*{ "Test::TempDatabase::become_postgres_user" } = sub { $became = 1; }
};
Apache::SWIT::Maker->new->do_swit_app_cmd(@ARGV);
print "Became" if $became;
ENDS

$lines = `make install SITEPREFIX=$td/inst 2>&1`;
is($?, 0);
unlike($lines, qr/Became/);

`dropdb inst510_db 2>/dev/null`;
unlike(`psql -l`, qr/inst510_db/);

my $fstr = read_file("$td/inst/share/ttt/conf/httpd.conf");
like($fstr, qr#$td/inst/share/ttt/conf/startup\.pl#) or diag($lines);
like($fstr, qr/PerlSetEnv APACHE_SWIT_DB_NAME inst510_db\n/);
unlike($fstr, qr/blib/);

ok(-f "public_html/main.css");
ok(-f "blib/public_html/main.css");
ok(-f "$td/inst/share/ttt/public_html/main.css");

`touch lib/TTT/DB/Schema.pm`;
`make`;
my $ssq = read_file('t/conf/schema.sql');
unlike($ssq, qr/moo/);
like($ssq, qr/SCHEMA/);

chdir '/';
