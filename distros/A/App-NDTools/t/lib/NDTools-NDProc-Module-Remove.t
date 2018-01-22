use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use App::NDTools::NDProc::Module::Remove;

my ($exp, $got, $mod);
my $shared = 't/_data';

$mod = new_ok('App::NDTools::NDProc::Module::Remove');

$got = $mod->load_struct("$shared/menu.a.json");
$mod->process_path(\$got, '[]{}[](defined)');
$exp = [{File => []},{Edit => [undef,undef]},{View => []}];
is_deeply($got, $exp, "Path with hooks") || diag t_ab_cmp($got, $exp);
