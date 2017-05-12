use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Catalyst::Plugin::I18N::DBI',
    license           => 'perl',
    dist_author       => 'Matthias Dietrich <perl@rainboxx.de>',
    dist_version_from => 'lib/Catalyst/Plugin/I18N/DBI.pm',
    requires => {
                  'Locale::Maketext::Lexicon::DBI' => 0,
                  'Locale::Maketext'               => 0,
                  'DBI'                            => 0,
                  'Moose::Role'                    => 0,
                  'I18N::LangTags'                 => 0,
                  'I18N::LangTags::Detect'         => 0,
                  'Test::More'                     => 0,
                  'version'                        => 0,
                  'Task::Weaken'                   => 0,
                },
    add_to_cleanup     => ['Catalyst-Plugin-I18N-DBI-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
