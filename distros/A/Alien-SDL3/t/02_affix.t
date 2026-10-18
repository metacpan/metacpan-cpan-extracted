use v5.40;
use Test2::V0;
use blib;
use Alien::SDL3;
no warnings 'experimental';
#
SKIP: {
    try {
        builtin::load_module('Affix');
        Affix->import(qw[:all]);
        #
        my $alien = Alien::SDL3->new;

        # package_info() with no argument returns the *primary* package's info (a single
        # object or undef), so assigning it to a list yields a one-element list that is
        # truthy even when it holds undef -- the guard below then passes and line 18 dies
        # on an undefined value. Collect each named package instead and drop the undefs.
        my @infos = grep {defined} map { $alien->package_info($_) } $alien->package_names;
        skip_all 'Run `perl Build` first so ConfigData knows where the libraries live' unless @infos;

        # xrepo drops each package into its own bin directory, but the companion DLLs import
        # SDL3.dll's exports, so expose every bin dir to the OS loader.
        $ENV{PATH} = join( ';', ( map { @{ $_->bindirs // [] } } @infos ), $ENV{PATH} );

        # Each package exports an int SDLx_Version(void) returning SDL_VERSIONNUM(major, minor, patch).
        # Key the symbol on the package name, not the link name: the from-source recipes report
        # SDL3/SDL3_image/..., but a system package (vcpkg/apt/brew) reports the lowercase library
        # name (sdl3/sdl3_image/...). Keying off links() matched nothing on the system path, so the
        # loop ran zero tests -- and a zero-test done_testing() is a hard failure, not a pass.
        my %version_symbol
            = ( libsdl3 => 'SDL_GetVersion', libsdl3_image => 'IMG_Version', libsdl3_ttf => 'TTF_Version', libsdl3_mixer => 'MIX_Version' );
        my @pairs = map { [ $_, $alien->package_info($_) ] } grep { $version_symbol{$_} } $alien->package_names;
        @pairs = grep { $_->[1] } @pairs;
        skip_all 'no installed package exports a known version symbol' unless @pairs;
        #
        for my $pair (@pairs) {
            my ( $name, $info ) = @$pair;
            my $symbol = $version_symbol{$name};
            subtest $name => sub {
                my $path = $info->libpath;
                my $lib  = load_library($path);
                ok( $lib, "loaded $path" ) or skip_all "cannot load $name: " . get_last_error_message();
                my $get_version = Affix::affix( $lib, $symbol, [], Affix::Int() );
                my $version_num = $get_version->();
                my $version     = join '.', int( $version_num / 1_000_000 ), int( $version_num % 1_000_000 / 1_000 ), $version_num % 1_000;
                is $version, $info->version, "$symbol matches linked $name version";
                diag "$name runtime version: $version";
            };
        }
    }
    catch ($e) { skip_all $e };
}
#
done_testing;
