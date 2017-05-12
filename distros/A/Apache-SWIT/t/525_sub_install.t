use strict;
use warnings FATAL => 'all';

use Test::More tests => 27;
use YAML;
use Data::Dumper;
use File::Slurp;
use Apache::SWIT::Test::Utils;
use Test::TempDatabase;

BEGIN { use_ok('Apache::SWIT::Subsystem::Maker');
	use_ok('Apache::SWIT::Test::ModuleTester');
}

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;
ok(-f 'LICENSE');

Apache::SWIT::Subsystem::Maker->new->write_initial_files();
isnt(-f './t/001_load.t', undef);
isnt(-f './conf/startup.pl', undef);

my $res = `scripts/swit_app.pl add_ht_page BB`;
is($?, 0);
ok(-f 'lib/TTT/UI/BB.pm');

undef $Apache::SWIT::Maker::Config::_instance;
my $tree = Apache::SWIT::Maker::Config->instance;
$tree->{pages}->{"index"}->{entry_points}->{r}->{foo} = 'boo';
isnt(delete $tree->{pages}->{bb}->{entry_points}, undef);
$tree->{pages}->{bb}->{handler} = 'some_handler';
$tree->save;

undef $Apache::SWIT::Maker::Config::_instance;
$tree = Apache::SWIT::Maker::Config->instance;
my $ind = $tree->{pages}->{"index"};
is($ind->{entry_points}->{r}->{foo}, 'boo');

$res = join('', `perl Makefile.PL && make 2>&1`);
is($?, 0) or diag($res);
unlike($res, qr/950/);
isnt(-f 'blib/lib/TTT/InstallationContent.pm', undef);
sleep 1;

append_file("templates/index.tt", "<!-- qqq -->\n");
$res = `make 2>&1`;
like(read_file('blib/lib/TTT/InstallationContent.pm'), qr/qqq/)
	or ASTU_Wait($td);

my $icmt = (stat 'blib/lib/TTT/InstallationContent.pm')[9];
sleep 1;

$tree = YAML::LoadFile('conf/swit.yaml');
push @{ $tree->{skip_install} }, qw(lib/G.pm);
YAML::DumpFile('conf/swit.yaml', $tree);

$res = `make 2>&1`;
cmp_ok((stat 'blib/lib/TTT/InstallationContent.pm')[9], '>', $icmt);

$icmt = (stat 'blib/lib/TTT/InstallationContent.pm')[9];
write_file("blib/lib/G.pm", "ddd\n");

my $hc = read_file('blib/conf/httpd.conf');
like($hc, qr#Location /ttt/bb#);
like($hc, qr#BB->some_handler#);

sleep 1;
$res = $mt->run_make_install;
is((stat 'blib/lib/TTT/InstallationContent.pm')[9], $icmt);

my $inst_path = $mt->install_dir . "/TTT";
ok(-f "$inst_path/Maker.pm");
is(-f $mt->install_dir . "/G.pm", undef);
is(`find $td/inst -name httpd.conf`, "");
unlike($mt->install_dir, qr/\/lib/);
is(`find $td/inst -name templates`, "");
like($mt->install_dir, qr/perl.*\d$/);

chdir $td;
$mt->make_swit_project(root_class => 'MU');
$mt->install_subsystem('TheSub');

undef $Apache::SWIT::Maker::Config::_instance;
$tree = Apache::SWIT::Maker::Config->instance;
$ind = $tree->{pages}->{"thesub/index"};
isnt($ind, undef) or diag(Dumper($tree));
is($ind->{entry_points}->{r}->{template}, 'templates/thesub/index.tt');
unlike(Dumper($ind), qr/html/);
is($ind->{entry_points}->{r}->{foo}, 'boo')
	 or diag(Dumper($tree));

chdir '/';
