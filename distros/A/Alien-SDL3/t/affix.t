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
        my @infos = $alien->package_info;
        skip_all 'Run `perl Build` first so ConfigData knows where the libraries live' unless @infos;

        # xrepo drops each package into its own bin directory, but the companion DLLs import
        # SDL3.dll's exports, so expose every bin dir to the OS loader.
        $ENV{PATH} = join( ';', ( map { @{ $_->bindirs // [] } } @infos ), $ENV{PATH} );

        # Each package exports an int SDLx_Version(void) returning SDL_VERSIONNUM(major, minor, patch);
        my %version_symbol = ( SDL3 => 'SDL_GetVersion', SDL3_mixer => 'MIX_Version', SDL3_image => 'IMG_Version', SDL3_ttf => 'TTF_Version' );
        my @pairs          = map { [ $_->links->[0], $_ ] } grep { @{ $_->links // [] } } @infos;
        #
        for my $pair (@pairs) {
            my ( $link, $info ) = @$pair;
            my $symbol = $version_symbol{$link} or next;
            subtest $link => sub {
                my $path = $info->libpath;
                my $lib  = load_library($path);
                ok( $lib, "loaded $path" ) or skip_all "cannot load $link: " . get_last_error_message();
                my $get_version = Affix::affix( $lib, $symbol, [], Affix::Int() );
                my $version_num = $get_version->();
                my $version     = join '.', int( $version_num / 1_000_000 ), int( $version_num % 1_000_000 / 1_000 ), $version_num % 1_000;
                is( $version, $info->version, "$symbol matches linked $link version" );
                diag "$link runtime version: $version";
            };
        }
    }
    catch ($e) { skip_all $e };
}
#
done_testing;
