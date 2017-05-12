use strict;
use warnings FATAL => 'all';

use Test::More tests => 20;
use File::Slurp;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester');
	use_ok('Apache::SWIT::Subsystem::Maker');
}

Apache::SWIT::Test::ModuleTester::Drop_Root();

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;
ok(-f 'LICENSE');

Apache::SWIT::Subsystem::Maker->new->write_initial_files();
is(-f './t/T/TTT/DB/Connection.pm', undef);

my $res = `./scripts/swit_app.pl add_ht_page P1`;
ok(-f 'lib/TTT/UI/P1.pm');
ok(-f 'templates/p1.tt');

$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 16');
append_file("t/dual/001_load.t", <<'ENDS');
$t->ok_ht_p1_r(make_url => 1, ht => { first => ""});
$t->ok_get('p1/r');
# to test g modifier do it twice
$t->ok_get("p1/r");

# check that relative urls are not affected
is("../p1/r", "../p" . "1/r");

# but quoting still works
$t->ok_get(qw(p1/r));
ENDS

$res = `perl Makefile.PL 2>&1`;
$res = $mt->run_make_install;
is(-d "$td/inst/share/ttt", undef);
isnt(-d "$td/inst/share/perl", undef);

chdir $td;

is(Apache::SWIT::Maker::Config->instance->app_name, 'ttt');
$mt->make_swit_project(root_class => 'MU');
is(Apache::SWIT::Maker::Config->instance->app_name, 'mu');

$mt->install_subsystem('TheSub');
is(-f 'lib/MU/TheSub.pm', undef);

$res = `./scripts/swit_app.pl override P89 2>&1`;
isnt($?, 0);
like($res, qr/Unable/);
like($res, qr/P89/);

$res = `./scripts/swit_app.pl override P1`;
is($?, 0) or diag($res);
ok(-f 'lib/MU/UI/TTT/P1.pm');

$ENV{PERL5LIB} .= ":$td/TTT/blib/lib";

write_file('lib/MU/UI/Index.pm', <<'ENDS');
use strict;
use warnings FATAL => 'all';

package MU::UI::Index::Root;
use base 'HTML::Tested';

package MU::UI::Index;
use base 'TTT::UI::P1';

1;
ENDS

$res = `perl Makefile.PL && make test_direct 2>&1`;
unlike($res, qr/Error/) or ASTU_Wait($td);
like($res, qr/success/);

$mt->replace_in_file('t/dual/thesub/001_load.t', '=> 16', '=> 17');
$mt->replace_in_file('t/dual/thesub/001_load.t', 'Index'
		, "Index'); use_ok('MU::UI::TTT::P1");

$res = `make test 2>&1`;
like($res, qr/success/);
unlike($res, qr/Error/);

chdir '/';
