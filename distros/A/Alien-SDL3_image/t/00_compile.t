use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Alien::SDL3_image;
#
diag 'Alien::SDL3_image::VERSION == ' . $Alien::SDL3_image::VERSION;
#
diag 'Support:';
diag sprintf '  - %s', $_,
    for grep {defined}
    map      { Alien::SDL3_image->features->{$_}{okay} ? $_ . ' v' . Alien::SDL3_image->features->{$_}{version} : () }
    qw[SDL3 SDL2_image SDL2_mixer SDL2_ttf];
diag 'Libs:';
diag '  - ' . $_ for sort Alien::SDL3_image->dynamic_libs;
#
isa_ok( Alien::SDL3_image->sdldir, ['Path::Tiny'], 'sdldir' );
isa_ok( Alien::SDL3_image->incdir, ['Path::Tiny'], 'incdir' );
isa_ok( Alien::SDL3_image->libdir, ['Path::Tiny'], 'libdir' );
#
Alien::SDL3_image->incdir->visit( sub { diag $_->realpath } );
Alien::SDL3_image->libdir->visit( sub { diag $_->realpath } );
#
done_testing;
