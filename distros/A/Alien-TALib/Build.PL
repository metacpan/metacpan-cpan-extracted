use strict;
use warnings;
use Alien::Build::MB;

my $build = Alien::Build::MB->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 0,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Build' => 0,
        'Alien::Build::MB' => 0,
    },
    build_requires => {
        'Alien::Build::MB' => 0,
        'Module::Build' => 0,
        'Path::Tiny' => 0,
        'HTTP::Tiny' => 0,
    },
    test_requires => {
        'Test::More'        => 0,
        'Test2::V0'         => 0,
        'Test::Alien'       => 0,
        'Test::Alien::Diag' => 0,
    },
    requires => {
        'perl' => '5.10.0',
    },
    meta_merge => {
        'meta-spec' => {
            version => 2
        },
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
        prereqs => {
            develop => {
                requires => {
                    'Software::License' => 0,
                },
            },
        },
    },
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### DATE: 26th Dec 2022
#### LICENSE: Refer LICENSE file.
