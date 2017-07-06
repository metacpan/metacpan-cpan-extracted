use Alien::Base::ModuleBuild;
use Alien::Autotools qw(autoconf_dir automake_dir libtool_dir);
use Config;

$ENV{PATH} = join ":", autoconf_dir, automake_dir, libtool_dir, $ENV{PATH};

my $build = Alien::Base::ModuleBuild->new(
    module_name => 'Alien::HIDAPI',
    license => 'perl',
    alien_bin_requires => {
    },
    configure_requires => {
        'Alien::Autotools' => '0.000_006',
        'Alien::Base::ModuleBuild' => 0,
        'Module::Build' => 0,
    },
    build_requires => {
        # TODO: fallback to HTTP download when IO::Socket::SSL doesn't exist
        'IO::Socket::SSL' => 0
    },
    recommends => {
        'IO::Socket::SSL' => 0
    },
    test_requires => {
        'Test::More'         => 0,
        'ExtUtils::CBuilder' => 0,
        'Test::Alien'        => '0.05',
        'Test2'              => '1.302015',
        'Test2::Suite'       => '0.000030',
    },
    requires => {
        'perl' => '5.008001',
        'Alien::Base' => '0.030',
    },
    dist_author => 'Ahmad Fatoum <athreef@cpan.org>',
    alien_name => 'HIDAPI',
    alien_repository => {
        protocol => 'http',
        host     => 'github.com',
        location => '/signal11/hidapi/archive',
        exact_filename => 'master.tar.gz',
    },
    alien_inline_auto_include => [ 'hidapi.h' ],
    alien_stage_install => 1,

    alien_build_commands => [
        './bootstrap',
        '%c --prefix=%s',
        'make',
    ],
    alien_install_commands => ['make install'],
    # extra_compiler_flags => Alien::CMake->config('cflags'),
    # extra_linker_flags   => Alien::CMake->config('libs'),
);

$build->create_build_script;
#$build->dispatch('distmeta');
#$build->dispatch('manifest');
#$build->dispatch('build');
