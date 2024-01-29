use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Domain',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Data/Domain.pm',
    requires => {
      'perl'            => "5.010001",
      'autouse'         => 0,
      'experimental'    => 0,
      'match::simple'   => 0,
      'Date::Calc'      => 0,
      'List::Util'      => 1.45,
      'List::MoreUtils' => 0,
      'Scalar::Does'    => 0.007,
      'Scalar::Util'    => 0,
      'Sub::Exporter'   => 0,
      'Try::Tiny'       => 0,
     },
    recommends => {
      'match::simple::XS' => 0,
    },
    build_requires => {
      'Test::More'       => 1.302190,
      'Test::Warnings'   => 0,
      'Clone'            => 0,
    },
    add_to_cleanup      => [ 'Data-Domain-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Data-Domain',
       }
     },
);

$builder->create_build_script();
