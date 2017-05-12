use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name => 'Catmandu::MediaMosa',
  license => 'perl',
  dist_author => [
    'Nicolas Franck <nicolas.franck@ugent.be>',
    'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>'
  ],
  dist_version_from => 'lib/Catmandu/Importer/MediaMosa.pm',
  build_requires => {
    'Software::License' => 0,
    'Test::Exception' => 0,
    'Test::More' => 0,
  },
  requires => {
    'perl' => '5.10.0',
    'Carp' => 0,
    'Catmandu' => '0.06',
    'Moo' => '0.009011',
    'LWP::UserAgent' => 0,
    'Data::UUID' => 0,
    'Data::Util' => 0,
    'Digest::SHA1' => 0,
    'URI::Escape' => 0,
    'XML::LibXML' => 0,
    'XML::LibXML::XPathContext' => 0,
    all => 0
  },
  add_to_cleanup => [qw(
    Catmandu-MediaMosa-*
  )],
  create_makefile_pl => 'traditional',
  create_license => 1,
);

$builder->create_build_script;
