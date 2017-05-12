use strict;
use warnings FATAL => 'all';

use Test::More tests => 48;
use Apache::SWIT::Test::ModuleTester;
use File::Slurp;
use ExtUtils::Manifest qw(maniadd);
use Test::TempDatabase;

BEGIN { use_ok('Apache::SWIT::Maker::Makefile');
	use_ok('Apache::SWIT::Maker::Manifest');
}

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;

ok(-f 'Makefile.PL');
is(Apache::SWIT::Maker::Config->instance->root_class, 'TTT');
is(Apache::SWIT::Maker::Config->instance->app_name, 'ttt');
is(Apache::SWIT::Maker::Config->instance->root_location, '/ttt');
is(Apache::SWIT::Maker::Config->instance->session_class, 'TTT::Session');

mkdir('conf');
write_file('conf/makefile_rules.yaml', <<ENDS);
- targets: [ config ]
  dependencies:
    - t/conf/httpd.conf
    - blib/conf/httpd.conf
  actions:
    - \$(NOECHO) \$(NOOP)
- targets: [ t/conf/httpd.conf ]
  dependencies:
    - t/conf/extra.conf.in
  actions:
    - PERL_DL_NONLAZY=1 \$(FULLPERLRUN) t/apache_test_run.pl -config
ENDS
is(Apache::SWIT::Maker::Makefile->get_makefile_rules, <<ENDS);
config :: t/conf/httpd.conf blib/conf/httpd.conf
	\$(NOECHO) \$(NOOP)

t/conf/httpd.conf :: t/conf/extra.conf.in
	PERL_DL_NONLAZY=1 \$(FULLPERLRUN) t/apache_test_run.pl -config

ENDS

my $args = Apache::SWIT::Maker::Makefile::Args();
write_file('Makefile.PL', <<ENDS);
use strict;
use warnings FATAL => 'all';

use Apache::SWIT::Maker::Makefile;
Apache::SWIT::Maker::Makefile->new->write_makefile$args;
ENDS

my $res = `perl Makefile.PL 2>&1`;
ok(-f 'Makefile');

my $am = Apache::SWIT::Maker::Makefile->new({ overrides => {
	postamble => sub { return "# gogogo\n"; },
} });
$am->write_makefile(NAME => 'TTT');
my $m = read_file('Makefile');
like($m, qr/gogogo/);

# from test
like($m, $< ? qr/-I t/ : qr/test_root/);

$am = Apache::SWIT::Maker::Makefile->new;
$am->write_makefile(NAME => 'TTT');
unlike(read_file('Makefile'), qr/gogogo/);

mkdir 'ddd';
write_file('ddd/aga.txt', "Hello\n");
maniadd({ 'ddd/aga.txt' => "", 'hoho/vvv.txt' => '' });

my $mf = read_file('MANIFEST');
like($mf, qr/ddd/);
like($mf, qr/hoho/);

swmani_filter_out('hoho/vvv.txt');
$mf = read_file('MANIFEST');
unlike($mf, qr/hoho/);

$am->overrides({
	postamble => sub { return "# hroror\n"; },
});
$am->blib_filter(sub { return $_ =~ /ddd/; });
$am->write_makefile(NAME => 'TTT');
$res = `make 2>&1`;
is($?, 0) or diag($res);
ok(-f 'blib/ddd/aga.txt');

$m = read_file('Makefile');
like($m, qr/hroror/);
unlike($m, qr/gogogo/);

chdir '/';

$mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
$td = $mt->root_dir;
chdir $td;
$mt->make_swit_project;

ok(-f 'scripts/swit_app.pl');
$m = read_file('Makefile.PL');
unlike($m, qr/MakeMaker/);
unlike($m, qr/postamble/);

$res = `perl Makefile.PL 2>&1`;
is($?, 0) or do {
	diag($res);
	write_file('/tmp/m', read_file('Makefile.PL'));
};

unlike(read_file('conf/httpd.conf.in'), qr/do_swit_startups/);
$res = `make 2>&1`;
is($?, 0) or diag($res);
ok(-d 'blib/templates');
ok(-f 'blib/templates/index.tt');
ok(-f 'blib/conf/seal.key');
ok(-f 'blib/conf/startup.pl');
ok(-f 'blib/conf/do_swit_startups.pl');
ok(! -f 'blib/scripts/swit_app.pl');
unlike(read_file('blib/conf/httpd.conf'), qr/swit_startup\>/);
like(read_file('blib/conf/do_swit_startups.pl'), qr/swit_startup/);

is_deeply([ swmani_dual_tests() ], [ 't/dual/001_load.t' ]);

# We have to sleep because timestamps are the same otherwise
sleep 1;
append_file('templates/index.tt', "gogo");
append_file('conf/startup.pl', "# touuu");
$res = `make 2>&1`;
is($?, 0) or diag($res);
ok($res);
like(read_file('templates/index.tt'), qr/gogo/);
like(read_file('blib/templates/index.tt'), qr/gogo/);
like(read_file('blib/conf/startup.pl'), qr/tou/);

$res = `make 2>&1`;
is($?, 0) or diag($res);
unlike($res, qr/seal/);

$m = read_file('Makefile');
like($m, qr/share\/ttt/);

ok(-f "blib/conf/httpd.conf");
ok(-f "blib/conf/startup.pl");
$ENV{APACHE_SWIT_DB_NAME} = "moo";
Apache::SWIT::Maker::Makefile->deploy_httpd_conf("blib", "$td/hdir");
ok(-f "$td/hdir/conf/httpd.conf");

$m = read_file("$td/hdir/conf/httpd.conf");
like($m, qr/$td\/hdir/);
unlike($m, qr/blib/);
like($m, qr/APACHE_SWIT_DB_NAME moo/);

chdir '/';
