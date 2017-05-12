use strict;
use warnings;

use Module::Build;
use Devel::CheckLib;

use Alien::AntTweakBar;
use Alien::SDL;

my $opengl_lib = $^O eq 'MSWin32' ? 'opengl32' : 'GL';
check_lib_or_exit( lib => $opengl_lib );

my $atb_inc = Alien::AntTweakBar->config('cflags');
my $atb_libs = Alien::AntTweakBar->config('libs');

my $sdl_inc = Alien::SDL->config('cflags');
my $sdl_libs = Alien::SDL->config('libs');

my @all_libs = (
    ( $^O ne 'MSWin32' ? ('-x', 'c++') : () ),
    $atb_libs, $sdl_libs, "-l$opengl_lib", '-lstdc++',
);

my $all_c_flags = join(' ', $atb_inc, $sdl_inc, '-DTW_STATIC');
my $all_libs = join(' ', @all_libs);

my $build = Module::Build->new(
    module_name        => 'AntTweakBar',
    dist_version_from  => 'lib/AntTweakBar.pm',
    dist_author        => 'DMOL, dmol@cpan.org',
    dynamic_config     => 1,
    license            => 'perl',
    configure_requires => {
        'perl'                    => '5.008',
        'Module::Build'           => '0.42',
        'Alien::AntTweakBar'      => '0.02',
        'Alien::SDL'              => '1.44',
        'Devel::CheckLib'         => '1.01',
    },
    requires           => {
      'perl'               => 5.008,
      'Carp'               => 0,
      'Alien::AntTweakBar' => '0.02',
      'Alien::SDL'         => '1.444',
    },
    test_requires => {
        'Test::Fatal'    => 0,
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    extra_compiler_flags => $all_c_flags,
    extra_linker_flags   => $all_libs,
    c_source             => 'src',
    needs_compiler       => 1,
    add_to_cleanup     => [ 'AntTweakBar-*', 'build_done' ],
    meta_merge => {
        resources  => {
            bugtracker => 'https://github.com/PerlGameDev/AntTweakBar/issues',
            repository => 'https://github.com/PerlGameDev/AntTweakBar',
        }
    },

);

$build->create_build_script;
