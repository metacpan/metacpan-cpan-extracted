#
# $Id: Build.PL 9 2015-01-13 18:13:54Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Bundle::Net::Frame',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Bundle/Net/Frame.pm',
   requires => {
      'perl' => '5.6.1',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
