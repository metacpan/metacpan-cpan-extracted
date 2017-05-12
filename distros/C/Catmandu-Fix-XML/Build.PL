use warnings;
use strict;
use Module::Build;

my $requires = {
  perl => '5.10.1',
  'Catmandu::XML' => '0.04',
};
my $recommends = {};

my $build = Module::Build->new(
  module_name => 'Catmandu-Fix-XML',
  dist_version_from => 'lib/Catmandu/Fix/XML.pm',  
  dist_author => [qw(
    nicolas.franck@ugent.be
  )],
  dist_abstract => 'Catmandu fix modules for processing xml (deprecated)',
  requires => $requires,
  recommends => $recommends,
  license => 'perl',
  create_license => 1,
  create_makefile_pl => 'traditional'
);
$build->create_build_script();
