#
# $Id: Build.PL 2000 2015-01-13 18:24:09Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Class::Gomor',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Class/Gomor.pm',
   requires => {
      'perl' => '5.6.1',
      'Data::Dumper' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
