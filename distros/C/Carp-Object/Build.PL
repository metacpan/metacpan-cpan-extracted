use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Carp::Object',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/Carp/Object.pm',

    requires => {
      'perl'                      => "5.010001",
      'utf8'                      => 0,
      'Devel::StackTrace'         => 0,
      'Module::Load'              => 0,
      'Clone'                     => 0,
     },
    build_requires => {
      'Test::More'                => 0,
    },

    add_to_cleanup      => [ 'Carp-Object-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Carp-Object',
        bugtracker => 'https://github.com/damil/Carp-Object/issues',
       }
     },
);

$builder->create_build_script();
