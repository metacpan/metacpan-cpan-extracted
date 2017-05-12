use warnings;
use strict;
use Module::Build;

my $requires = {
  perl => '5.10.0', 
  Carp => 0,
  'Catmandu' => '0.8014',
  'Activiti::Rest::Client' => '0.1'
};
my $recommends = {};
my $build = Module::Build->new(
  module_name => 'Catmandu-Activiti',
  dist_author => [
    'Nicolas Franck <nicolas.franck@ugent.be>'
  ],
  dist_abstract => 'Catmandu module for Activiti',
  requires => $requires,
  recommends => $recommends,
  build_requires => {
    'Software::License' => 0,
    'Test::Exception' => 0,
    'Test::More' => 0,
  },
  create_license => 1,
  license => 'perl',
  dist_version_from => 'lib/Catmandu/Activiti.pm',
  create_makefile_pl => 'traditional'  
);
$build->create_build_script;
