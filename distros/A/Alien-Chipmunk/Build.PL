use strict;
use warnings;
use lib 'inc';
use My::ModuleBuild;
use Config;

my $cflags = '';
my $libs
    = join( ' ', '-lchipmunk', grep( /^-lm$/, split /\s+/, $Config{libs} ) );

if ( $ENV{ALIEN_CHIPMUNK_PREFIX} ) {
    $cflags = "-I$ENV{ALIEN_CHIPMUNK_PREFIX}/include/chipmunk";
    $libs   = "-L$ENV{ALIEN_CHIPMUNK_PREFIX}/lib $libs";
}
else {
    foreach
        my $dir ( map {"$_/chipmunk"} qw( /usr/include /usr/local/include ) )
    {
        if ( -r "$dir/chipmunk.h" ) {
            $cflags = "-I$dir";
        }
    }
}

my $builder = My::ModuleBuild->new(
    module_name        => 'Alien::Chipmunk',
    dist_abstract      => 'Build and install the Chipmunk Physics library',
    dist_author        => 'Jeffrey T. Palmer <jtpalmer@cpan.org>',
    license            => 'mit',
    configure_requires => {
        'Module::Build'            => 0,
        'Alien::Base::ModuleBuild' => 0,
    },
    build_requires     => { 'Test::More'   => 0, },
    alien_bin_requires => { 'Alien::CMake' => '0.03', },
    requires           => {
        'perl'        => '5.8.1',
        'Alien::Base' => '0.020',
    },
    add_to_cleanup => [ 't/src/test.o', 't/src/test' ],
    meta_merge     => {
        resources => {
            homepage   => 'https://github.com/jtpalmer/Alien-Chipmunk',
            repository => 'https://github.com/jtpalmer/Alien-Chipmunk.git',
            bugtracker => 'https://github.com/jtpalmer/Alien-Chipmunk/issues',
        },
    },
    alien_name            => 'chipmunk',
    alien_isolate_dynamic => 1,
    alien_provides_cflags => $cflags,
    alien_provides_libs   => $libs,
    alien_repository      => {
        protocol => 'http',
        host     => 'chipmunk-physics.net',
        location => '/release/Chipmunk-6.x',
        pattern  => qr/Chipmunk-([\d\.]+)\.tgz$/,
    },
    alien_build_commands =>
        [ 'cmake -DBUILD_DEMOS=OFF -DCMAKE_INSTALL_PREFIX=%s', 'make', ],
    alien_install_commands => ['make install'],
);

$builder->create_build_script;

