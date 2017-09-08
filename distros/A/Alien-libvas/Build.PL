use Alien::Base::ModuleBuild;
use Config;
use Alien::CMake;
use File::Which;
$ENV{CC} //= $Config{cc} if $^O eq 'MSWin32' && !which('cl');
my $cmake = Alien::CMake->config('prefix') . '/bin/cmake';
my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::libvas',
    alien_name => 'libvas',
    dist_author => 'Ahmad Fatoum <athreef@cpan.org>',
    license => 'perl',

    alien_repository => {
        protocol => 'http',
        host     => 'github.com',
        location => '/a3f/libvas/archive',
        exact_filename => 'master.tar.gz',
    },
    alien_bin_requires => {
        'Alien::CMake' => '0.07',
    },
    configure_requires => {
        'Alien::Base::ModuleBuild' => 0,
        'Module::Build' => 0,
        'File::Which' => 0,
        'Alien::CMake' => '0.07',
    },
    build_requires => {
        'Alien::CMake' => '0.07',
        # TODO: fallback to HTTP download when IO::Socket::SSL doesn't exist
        'IO::Socket::SSL' => 0
    },
    recommends => {
        'IO::Socket::SSL' => 0,
    },
    test_requires => {
        'ExtUtils::CBuilder'  => 0,
        'Test::Alien'         => '0.05',
        'Test2'               => '1.302015',
        'Test2::Suite'        => '0.000030',
        'Test2::Bundle::More' => 0,
    },
    requires => {
        'perl' => '5.010',
        'Alien::Base' => '0.030',
    },
    alien_inline_auto_include => [ 'vas.h' ],
    alien_stage_install => 1,
    alien_build_commands => [
                Alien::CMake->config('prefix')
              . "/bin/cmake -DCMAKE_C_COMPILER_INIT=$Config{cc}"
              . ' -DWITH_PIC=ON -DBUILD_MANUAL_TESTS=OFF'
              . ' -DCMAKE_INSTALL_PREFIX:PATH=%s CMakeLists.txt',
            "$cmake --build ."
     ],
    alien_install_commands => ["cmake --build . --target install"],

    alien_test_commands => [
            Alien::CMake->config('prefix') . "/bin/ctest --output-on-failure" .
            ($^O eq 'darwin' ? " -E child" : '') # child tests on macOS require superuser privileges
    ],

    extra_compiler_flags => Alien::CMake->config('cflags'),
    extra_linker_flags   => Alien::CMake->config('libs'),
    alien_isolate_dynamic => 1,
);

$build->create_build_script;
$build->dispatch('distmeta');
#$build->dispatch('manifest');
#$build->dispatch('build');
