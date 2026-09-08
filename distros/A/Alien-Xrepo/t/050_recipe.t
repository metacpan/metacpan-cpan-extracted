use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp qw[tempdir];
use JSON::PP   qw[encode_json];
use Path::Tiny;
use Alien::Xrepo::Build::Recipe;
use experimental 'class';
#
my $dir = tempdir( CLEANUP => 1 );
subtest 'inline defs normalize like Base pkg_name' => sub {
    my $recipe = Alien::Xrepo::Build::Recipe->new(
        packages => [
            'zstd',
            { name => 'libsdl3', version => '3.4.12', kind => 'shared', configs => { wayland => 1 } },
            { name => 'ninja',   kind    => 'binary' }
        ]
    );
    is [ $recipe->packages ],                              [qw[zstd libsdl3 ninja]], 'packages in recipe order';
    is $recipe->package_defs->{libsdl3}{version},          '3.4.12',                 'version captured';
    is $recipe->package_defs->{libsdl3}{configs}{wayland}, 1,                        'configs captured';
    ok !exists $recipe->package_defs->{zstd}, 'plain entry carries no def';
    is $recipe->version_for('zstd'),    undef,    'no version for plain entry';
    is $recipe->version_for('libsdl3'), '3.4.12', 'per-package version';
};
subtest 'opts_for merges defs over ambient opts' => sub {
    my $recipe = Alien::Xrepo::Build::Recipe->new( packages => [ 'zstd', { name => 'libsdl3', kind => 'shared', configs => { wayland => 1 } }, ], );
    my %zstd   = $recipe->opts_for( 'zstd', kind => 'static', configs => { wayland => 0 } );
    is $zstd{kind},             'static', 'plain entry keeps ambient kind';
    is $zstd{configs}{wayland}, 0,        'plain entry keeps ambient configs';
    my %sdl = $recipe->opts_for( 'libsdl3', kind => 'static', configs => { zlib => 0, wayland => 0 } );
    is $sdl{kind},             'shared', 'def kind overrides ambient';
    is $sdl{configs}{zlib},    0,        'ambient configs preserved';
    is $sdl{configs}{wayland}, 1,        'def config wins per-key';
};
subtest 'file round-trip (xrepo.json)' => sub {
    my $file = path($dir)->child('xrepo.json');
    $file->spew_utf8(
        encode_json(
            {   name        => 'Alien-Zstandard',
                packages    => [ { name => 'zstd', version => '1.5.6', kind => 'shared' } ],
                defaults    => { mode => 'release', configs => { legacy => 1 } },
                pkg_roots   => { ZSTD => '$ZSTD' },
                local_repos => ['vendor/recipes'],
                hooks       => ['Alien::Zstandard::Hooks']
            }
        )
    );
    my $recipe = Alien::Xrepo::Build::Recipe->new( file => $file );
    is $recipe->name,                        'Alien-Zstandard',         'name from file';
    is [ $recipe->packages ],                ['zstd'],                  'packages from file';
    is $recipe->version_for('zstd'),         '1.5.6',                   'version from file';
    is $recipe->defaults->{mode},            'release',                 'defaults from file';
    is $recipe->defaults->{configs}{legacy}, 1,                         'defaults configs from file';
    is $recipe->pkg_roots->{ZSTD},           '$ZSTD',                   'pkg_roots from file';
    is $recipe->local_repos->[0],            'vendor/recipes',          'local_repos from file';
    is $recipe->hooks->[0],                  'Alien::Zstandard::Hooks', 'hooks from file';
    my $from_dir = Alien::Xrepo::Build::Recipe->new( dir => $dir );
    is [ $from_dir->packages ], ['zstd'], 'dir form loads xrepo.json';
};
subtest 'validation dies loudly' => sub {
    for my $case (
        [ 'packages required',    { defaults => {} },                                             qr/packages is required/ ],
        [ 'empty packages',       { packages => [] },                                             qr/at least one package/ ],
        [ 'entry missing name',   { packages => [ { kind => 'shared' } ] },                       qr/requires a 'name' key/ ],
        [ 'unknown def key',      { packages => [ { name => 'zstd', foo => 1 } ] },               qr/unknown key 'foo'/ ],
        [ 'non-hashref configs',  { packages => [ { name => 'zstd', configs => 'wayland=1' } ] }, qr/configs must be a hashref/ ],
        [ 'numeric entry',        { packages => [42] },                                           qr/must be a name or a hashref/ ],
        [ 'duplicate plain name', { packages => [ 'zstd', 'zstd' ] },                             qr/duplicate package name 'zstd'/ ],
        [ 'duplicate def name',   { packages => [ 'zstd', { name => 'zstd' } ] },                 qr/duplicate package name 'zstd'/ ],
        [ 'bad defaults key',     { packages => ['zstd'], defaults => { bogus => 1 } },       qr/defaults: unknown key 'bogus'/ ],
        [ 'bad defaults configs', { packages => ['zstd'], defaults => { configs => 'x=1' } }, qr/defaults configs must be a hashref/ ],
        [ 'bad pkg_roots',        { packages => ['zstd'], pkg_roots => [] },                  qr/pkg_roots must be a hashref/ ],
        [ 'bad local_repos',      { packages => ['zstd'], local_repos => 'x' },               qr/local_repos must be an arrayref/ ],
        [ 'bad hooks',            { packages => ['zstd'], hooks => { x => 1 } },              qr/hooks must be an arrayref/ ]
    ) {
        my ( $label, $data, $re ) = @$case;
        my $err = dies { Alien::Xrepo::Build::Recipe->new(%$data) };
        like $err, $re, $label;
    }
};
subtest 'missing file dies' => sub {
    like dies { Alien::Xrepo::Build::Recipe->new( file => path($dir)->child('nope.json') ) }, qr/not found/, 'bad file path dies';
};
#
done_testing;
