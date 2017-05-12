#!/usr/bin/perl
use Module::Build;
Module::Build->new(
    # standing on the shoulders of giants...
    requires => {
        'perl'                                         => '5.10.0',
        'Algorithm::Evolutionary::Wheel'               => 0,
        'aliased'                                      => 0,
        'Class::Accessor::Fast'                        => 0,
        'Language::Befunge'                            => '4.10',
        'Language::Befunge::Storage::Generic::Vec::XS' => '0.02',
        'Language::Befunge::Vector::XS'                => '1.1.0',
        'LWP::UserAgent'                               => 0,
        'Parallel::Iterator'                           => 0,
        'Perl6::Export::Attrs'                         => 0,
        'Task::Weaken'                                 => 0,
        'Test::Exception'                              => 0,
        'Test::MockRandom'                             => 0,
        'Test::Output'                                 => 0,
        'UNIVERSAL::require'                           => 0,
        'YAML'                                         => 0,
    },
    module_name  => 'AI::Evolve::Befunge',
    license      => 'artistic_2',
    create_makefile_pl => 'traditional',
    script_files       => [qw(tools/evolve tools/migrationd)],
    dist_author        => 'Mark Glines <mark@glines.org>',
    dist_version_from  => 'lib/AI/Evolve/Befunge.pm',
    dist_abstract      => 'practical evolution of Befunge AI programs'
)->create_build_script;
