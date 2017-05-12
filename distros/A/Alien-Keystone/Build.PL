use strict;
use warnings;
use Alien::Base::ModuleBuild;
$Alien::Base::ModuleBuild::Verbose = 1;
$Alien::Base::ModuleBuild::Force = 1;

my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::Keystone',
    license => 'mit',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for Keystone Engine from www.keystone-engine.org',
    create_readme => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Base::ModuleBuild' => '0.029',
    },
    build_requires => {
        'Alien::Base::ModuleBuild' => '0.029',
        'Module::Build' => 0,
        'Test::More' => 0,
    },
    requires => {
        'Alien::Base' => '0.029',
    },
    alien_name => 'keystone',
    alien_repository => {
        protocol => 'http',
        host => 'github.com',
        location => '/keystone-engine/keystone/archive/',
        exact_filename => 'master.tar.gz',
        exact_version => '1.0',
        c_compiler_required => 1,
    },
    alien_msys => 1,
    alien_bin_requires => {
        'Alien::CMake' => 0,
    },
    alien_build_commands => [
        'cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBS_ONLY=1 ' .
            '-DBUILD_SHARED_LIBS=ON -DLLVM_TARGETS_TO_BUILD="all" '.
            '-DCMAKE_INSTALL_PREFIX="%s" -G"Unix Makefiles"',
        'make clean',
        'make all',
    ],
    alien_install_commands => [
        'make install PREFIX=%s',
    ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/selectiveintellect/p5-alien-keystone',
            bugtracker => 'https://github.com/selectiveintellect/p5-alien-keystone/issues',
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
