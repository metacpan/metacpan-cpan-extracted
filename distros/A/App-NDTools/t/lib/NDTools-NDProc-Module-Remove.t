use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use App::NDTools::Test;
use App::NDTools::NDProc::Module::Remove;

chdir t_dir or die "Failed to change test dir";

my ($exp, $got, $mod);

$mod = new_ok('App::NDTools::NDProc::Module::Remove');

$got = $mod->load_struct("_menu.a.json");
$mod->process_path(\$got, '[]{}[](defined)');
$exp = [{File => []},{Edit => [undef,undef]},{View => []}];
is_deeply($got, $exp, "Path with hooks") || diag t_ab_cmp($got, $exp);
