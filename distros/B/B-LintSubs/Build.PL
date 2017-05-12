use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'B::LintSubs',
   dist_version_from => 'lib/B/LintSubs.pm',
   build_requires => {
                        'Test::More' => 0,
                        'IPC::Run'   => 0,
                     },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
  );
  
$build->create_build_script;
