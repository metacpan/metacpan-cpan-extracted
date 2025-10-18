use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Alien::SDL3_ttf;
#
diag 'Alien::SDL3_ttf::VERSION == ' . $Alien::SDL3_ttf::VERSION;
#
diag 'Support:';
diag sprintf '  - %s', $_,
    for grep {defined}
    map { Alien::SDL3_ttf->features->{$_}{okay} ? $_ . ' v' . Alien::SDL3_ttf->features->{$_}{version} : () } qw[SDL3 SDL2_image SDL2_mixer SDL2_ttf];
diag 'Libs:';
diag '  - ' . $_ for sort Alien::SDL3_ttf->dynamic_libs;
#
isa_ok( Alien::SDL3_ttf->sdldir, ['Path::Tiny'], 'sdldir' );
isa_ok( Alien::SDL3_ttf->incdir, ['Path::Tiny'], 'incdir' );
isa_ok( Alien::SDL3_ttf->libdir, ['Path::Tiny'], 'libdir' );
#
Alien::SDL3_ttf->incdir->visit( sub { diag $_->realpath } );
Alien::SDL3_ttf->libdir->visit( sub { diag $_->realpath } );
#
done_testing;
