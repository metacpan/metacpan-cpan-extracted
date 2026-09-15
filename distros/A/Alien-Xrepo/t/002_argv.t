use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Config;
use Alien::Xrepo;
use experimental 'class';
use Path::Tiny;
#
my $repo = Alien::Xrepo->new( verbose => 0 );

# Grab the resolved xmake exe the same way _argv does (via the field object).
my $xmake_exe = eval { Alien::Xmake->new->exe } // 'xmake';
subtest 'enum-cli-methods' => sub {
    isa_ok $repo, ['Alien::Xrepo'], 'Alien::Xrepo object';
    ok $repo->can('_argv'),         'has _argv';
    ok $repo->can('_build_args'),   'has _build_args';
    ok $repo->can('_confirm_args'), 'has _confirm_args';
};
subtest '_argv prefix and flags-before-spec invariant' => sub {

    # Every action with a trailing package spec: flags come first, then the
    # (possibly versioned) spec, and NOTHING follows the spec.
    for my $case (
        [ install    => [qw[-y -k shared]],     'zlib' ],
        [ install    => [qw[-y]],               'libsdl3_ttf' ],
        [ remove     => [qw[-y --all]],         'zlib' ],
        [ fetch      => [qw[--json -k shared]], 'zlib 1.2.11' ],
        [ info       => [qw[-k static]],        'zlib' ],
        [ scan       => [qw[--format=plain]],   'zlib' ],
        [ download   => [qw[-y -o /tmp/o]],     'zlib' ],
        [ import     => [qw[-y -i /tmp/i]],     'zlib' ],
        [ export     => [qw[-y -o /tmp/o]],     'zlib' ],
        [ 'add-repo' => [qw[-y]],               'myrepo', 'https://example.com/repo.git' ],
        [ search     => [qw[--addon]],          'zlib' ],
    ) {
        my ( $action, $flags, @spec ) = @$case;
        my @argv = $repo->_argv( $action, $flags, @spec );
        is $argv[0],            $xmake_exe,                         "$action: argv starts with the xmake exe";
        is [ @argv[ 1 .. 3 ] ], [ qw[lua private.xrepo], $action ], "$action: runs `xmake lua private.xrepo $action`";

        # The spec (versioned single-string or multi-token) is the trailing argv.
        my @tail  = @argv[ 4 .. $#argv ];
        my $n     = @spec;
        my $start = $#tail + 1 - $n;
        is [ @tail[ $start .. $#tail ] ], [@spec], "$action: package spec is the trailing argument(s)";

        # No dash-prefixed flag may appear after the first spec token: that is
        # exactly the parser-leak the invariant guards against.
        my $first_spec = $#argv + 1 - $n;
        for my $i ( $first_spec + 1 .. $#argv ) {
            unlike $argv[$i], qr{^-}, "$action: no flag follows the spec";
        }
    }

    # A versioned spec stays a single argv element so spaces never split argv.
    my @argv = $repo->_argv( 'install', ['-y'], 'libsdl3_ttf >=3.2.2' );
    is $argv[-1], 'libsdl3_ttf >=3.2.2', 'versioned spec is a single trailing element';
};
subtest '_full_spec composes a pinned version into a single spec token' => sub {
    is $repo->_full_spec( 'raylib', undef ),   'raylib',       'no version keeps the bare name';
    is $repo->_full_spec( 'raylib', '' ),      'raylib',       'empty version ignored';
    is $repo->_full_spec( 'raylib', '6.0.x' ), 'raylib 6.0.x', 'a pinned version joins the name';
    my @argv = $repo->_argv( 'install', ['-y'], $repo->_full_spec( 'raylib', '6.0.x' ) );
    is scalar @argv, 6,              'one spec token, no argv inflation';
    is $argv[-1],    'raylib 6.0.x', 'pinned spec is the single trailing element';
};
subtest '_build_args configs boolean rendering' => sub {

    # A Perl built-in boolean (use feature 'true'/'false' via use v5.40) must render as the
    # literal string 'true'/'false' that xrepo expects, never as 1 / "".
    my @bool = $repo->_build_args( { configs => { shared => true } } );
    my ($flag_bool) = grep {/^--configs=/} @bool;
    is $flag_bool, '--configs=shared=true', 'built-in true renders as --configs=shared=true';
    my @boolf = $repo->_build_args( { configs => { shared => false } } );
    my ($flag_boolf) = grep {/^--configs=/} @boolf;
    is $flag_boolf, '--configs=shared=false', 'built-in false renders as --configs=shared=false';
    my @mixed = $repo->_build_args( { configs => { shared => true, vs_runtime => 'MD' } } );
    my ($flag_mixed) = grep {/^--configs=/} @mixed;
    is $flag_mixed, '--configs=shared=true,vs_runtime=MD', 'booleans and strings mix in key order';

    # Plain numbers / strings are historical behavior: values pass through untouched.
    my @vec = $repo->_build_args( { configs => { legacy => 1, mode => 'debug' } } );
    my ($flag_vec) = grep {/^--configs=/} @vec;
    is $flag_vec, '--configs=legacy=1,mode=debug', 'non-boolean config values pass through unchanged';
};
subtest '_build_args includes uses the OS path separator' => sub {

    # xrepo's install.lua splits `--includes` with path.splitenv and rejoins with
    # path.joinenv -- both keyed off the platform path separator, never a comma.
    my $sep = $Config{path_sep};

    # Nonexistent/plain includes pass through as absolute paths (xrepo silently
    # drops anything that doesn't resolve, preserving the old no-op behavior).
    my @single = $repo->_build_args( { includes => 'recipe.lua' } );
    my ($flag_single) = grep {/^--includes=/} @single;
    is $flag_single, '--includes=' . path('recipe.lua')->absolute->stringify, 'scalar include normalized to an absolute path';
    my @multi = $repo->_build_args( { includes => [ 'a.lua', 'b.lua' ] } );
    my ($flag_multi) = grep {/^--includes=/} @multi;
    is $flag_multi, '--includes=' . join( $sep, map { path($_)->absolute->stringify } qw[a.lua b.lua] ),
        "array includes joined with path separator ($sep)";
    unlike $flag_multi, qr{,}, 'array includes never joined with a comma';

    # Paths containing the separator would split, but normal single paths are fine.
    # (Path::Tiny normalizes backslashes to forward slashes, which xmake accepts.)
    if ( $^O eq 'MSWin32' ) {
        my @win = $repo->_build_args( { includes => 'C:\path with space\recipe.lua' } );
        my ($flag_win) = grep {/^--includes=/} @win;
        is $flag_win, '--includes=C:/path with space/recipe.lua', 'Windows path passes through (forward-slash normalized)';
    }
};
subtest '_build_args auto-confirm flags' => sub {
    my @default = $repo->_build_args( {} );
    is [ grep {/^-y$/} @default ], [], 'no -y when neither yes nor confirm is given';
    my @yes = $repo->_build_args( { yes => 1 } );
    is [ grep {/^-y$/} @yes ], ['-y'], '-y emitted for yes => 1';
    my @yes0 = $repo->_build_args( { yes => 0 } );
    is [ grep {/^-y$/} @yes0 ], [], 'no -y for yes => 0';
    my @confirm = $repo->_build_args( { confirm => 'never' } );
    is [ grep {/^--confirm=/} @confirm ], ['--confirm=never'], '--confirm= emitted for confirm =>';
    is [ grep {/^-y$/} @confirm ],        [],                  'confirm suppresses -y';
    my @both = $repo->_build_args( { yes => 1, confirm => 'never' } );
    is [ grep {/^--confirm=/} @both ], ['--confirm=never'], 'confirm wins over yes';
    is [ grep {/^-y$/} @both ],        [],                  'no -y when confirm is set';
};
subtest '_confirm_args default-confirm for mutating actions' => sub {

    # install/uninstall/download/import/export auto-confirm by default so a
    # captured install never hangs, but an explicit choice is honored.
    is [ $repo->_confirm_args( {} ) ], ['-y'], 'default mutating action confirms';
    is [ $repo->_confirm_args( { yes     => 0 } ) ],       [], 'yes => 0 opts out';
    is [ $repo->_confirm_args( { yes     => 1 } ) ],       [], 'yes => 1 handled by _build_args';
    is [ $repo->_confirm_args( { confirm => 'never' } ) ], [], 'confirm opts out';
};

# End-to-end-ish: the full install argv for the SDL3 TTF recipe (the case that
# motivated `--includes`) has the recipe as a flag and the package last.
subtest 'sdl3 ttf install argv' => sub {
    my $recipe = 'C:/dir/libsdl3_ttf.lua';
    my @argv   = $repo->_argv( 'install', [ '-y', '-k', 'shared', "--includes=$recipe" ], 'libsdl3_ttf' );
    is $argv[-1], 'libsdl3_ttf', 'ttf package is the trailing spec';
    my ($inc) = grep {/^--includes=/} @argv;
    is $inc, "--includes=$recipe", '--includes recipe precedes the spec';
    my $inc_at = -1;
    for my $i ( 0 .. $#argv ) { $inc_at = $i if $argv[$i] eq $inc; }
    ok $inc_at >= 0 && $inc_at < $#argv, 'includes flag comes before the package spec';
};
subtest '_parse_search reads xrepo search output' => sub {

    # Layout produced by `xmake require --search` (see xrepo action/search.lua):
    # one block per query term, `      -> <name>[-<version>]: <desc> (in <repo>)` rows.
    my @r = $repo->_parse_search(<<'POD');
The package names:
    zlib: 
      -> zlib-v1.3.2: A Massively Spiffy Yet Delicately Unobtrusive Compression Library (in xmake-repo)
      -> zlib-ng-2.3.3: zlib replacement with optimizations for next generation systems. (in xmake-repo)
      -> miniz-3.1.1: miniz: Single C source file zlib-replacement library (in xmake-repo)
      -> chromium_zlib-2024.01.29: zlib from chromium (in xmake-repo)
POD
    is [@r], [qw[zlib-v1.3.2 zlib-ng-2.3.3 miniz-3.1.1 chromium_zlib-2024.01.29]], 'rows become tokens';
    ok !grep {/zlib/} $repo->_parse_search("The package names:\n"), 'no matches parse to an empty list';

    # Names and tokens with '-', '::' namespaces, description colons and no repo:
    my @t = $repo->_parse_search(<<'POD');
The package names:
    serial: 
      -> serial-tools-v1.0.4: The serial port toolkit it provides the `xmake monitor` command and the serial module. (in xmake-repo)
    pcre*: 
      -> pcre2-10.47: A Perl Compatible Regular Expressions Library (in xmake-repo)
      -> jpcre2-2021.06.15: C++ wrapper  for PCRE2 Library (in xmake-repo)
    vcpkg::pcre: 
      -> vcpkg::pcre-8.44: Perl Compatible Regular Expressions
      -> vcpkg::pcre2-10.35: PCRE2 is a re-working of the original Perl Compatible Regular Expressions library
    conan::openssl: 
      -> conan::openssl/1.1.1g: 
POD
    is [@t], [qw[serial-tools-v1.0.4 pcre2-10.47 jpcre2-2021.06.15 vcpkg::pcre-8.44 vcpkg::pcre2-10.35 conan::openssl/1.1.1g]],
        'tokens keep - and :: and description colons';
};
#
done_testing;
