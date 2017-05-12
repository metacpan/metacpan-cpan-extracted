use strict;
use warnings;
use Alien::Base::ModuleBuild;
$Alien::Base::ModuleBuild::Verbose = 1;
$Alien::Base::ModuleBuild::Force = 1;

my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::Capstone',
    license => 'mit',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for Capstone Engine from www.capstone-engine.org',
    create_readme => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Base::ModuleBuild' => '0.029',
        'Pod::Readme' => 0,
    },
    build_requires => {
        'Alien::Base::ModuleBuild' => '0.029',
        'Test::More' => 0,
        'Module::Build' => 0,
    },
    requires => {
        'Alien::Base' => '0.029',
    },
    alien_name => 'capstone',
    alien_repository => {
        protocol => 'http',
        host => 'github.com',
        location => '/aquynh/capstone/archive/',
        exact_filename => 'master.tar.gz',
        exact_version => '3.0.4',
        c_compiler_required => 1,
    },
    alien_msys => 1,
    alien_bin_requires => {
        'Alien::gmake' => 0.11,
    },
    alien_build_commands => [
        '%{gmake} clean all PREFIX=%s',
        '%{gmake} check PREFIX=%s',
    ],
    alien_install_commands => [
        '%{gmake} install PREFIX=%s',
    ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/selectiveintellect/p5-alien-capstone',
            bugtracker => 'https://github.com/selectiveintellect/p5-alien-capstone/issues',
        },
    },
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');
$build->dispatch('build');

__END__
#### COPYRIGHT: Selective Intellect LLC.
#### AUTHOR: Vikas N Kumar
#### DATE: 13 September 2016
