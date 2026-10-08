use v5.40;
use Test2::V0;
use blib;
use Alien::SDL3;
use experimental 'class';
skip_all 'Wrong dist for this';
#
# Simulate a build where libsdl3 could not be built/installed (e.g. a missing transitive link
# dependency) so the ConfigData records an error instead of a library's info.
class Alien::SDL3::NoTTF : isa(Alien::SDL3) {
}

package Alien::SDL3::NoTTF::ConfigData {
    use v5.40;

    sub _ok ( $version, $link ) {
        {   includedirs => [],
            libfiles    => [],
            license     => 'unknown',
            linkdirs    => [],
            links       => [$link],
            shared      => 1,
            static      => 0,
            version     => $version,
            installdir  => './fake/' . $link
        };
    }
    my %config = (
        libsdl3       => { error => 'link failed: BZ2_bzDecompress (libbz2)' },
        libsdl3_mixer => _ok( '3.2.4',  'SDL3_mixer' ),
        libsdl3_image => _ok( '3.4.0',  'SDL3_image' ),
        libsdl3_ttf   => _ok( '3.4.12', 'SDL3_ttf' )
    );
    sub config  ($class)                 { \%config }
    sub package ( $class, $pkg = undef ) { $config{$pkg} }
}
#
is Alien::SDL3::NoTTF->new->alt('libsdl3')->package_info, U(), 'missing packages reported';
is Alien::SDL3->new->alt('libsdl3')->package_info,        D(), 'a full install has nothing missing';
#
done_testing;
