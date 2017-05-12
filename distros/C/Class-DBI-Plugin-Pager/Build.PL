use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::DBI::Plugin::Pager',
    license             => 'perl',
    dist_author         => ['David Baird', 'Nikolay S. <majestic@cpan.org>'],
    dist_version_from   => 'lib/Class/DBI/Plugin/Pager.pm',
    meta_add => {
        resources => {
            repository => 'git://github.com/majesticcpan/class-dbi-plugin-pager.git',
        },
    },
    requires => { 'Test::More' => 0,
                  'Test::Exception' => 0,
                  'Test::Warn' => 0,
                  'Class::DBI' => 0.90,
                  'SQL::Abstract' => 1.61,
                  'Data::Page' => 2,
                  'Class::DBI::Plugin::AbstractCount' => 0,
                  'Class::Data::Inheritable' => 0,
                  'UNIVERSAL::require' => 0,
                  Carp => 0,
                  },
    add_to_cleanup      => [ 'Class-DBI-Plugin-Pager-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script;
