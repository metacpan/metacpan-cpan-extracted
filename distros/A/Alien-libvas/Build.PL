use Alien::Base::ModuleBuild;
use Config;
use Alien::CMake;
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
        'perl' => '5.008001',
        'Alien::Base' => '0.030',
    },
    alien_inline_auto_include => [ 'vas.h' ],
    alien_stage_install => 1,

    alien_build_commands => [
            Alien::CMake->config('prefix')
              . "/bin/cmake -DCMAKE_C_COMPILER_INIT=$Config{cc}"
              . ' -DCMAKE_INSTALL_PREFIX:PATH=%s CMakeLists.txt',
            $Config{make},
    ],
    alien_install_commands => ["$Config{make} install"],

    extra_compiler_flags => Alien::CMake->config('cflags'),
    extra_linker_flags   => Alien::CMake->config('libs'),
);

$build->create_build_script;
$build->dispatch('distmeta');
#$build->dispatch('manifest');
#$build->dispatch('build');
