use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp qw[tempdir];
use JSON::PP   qw[decode_json];
use Path::Tiny;
use Alien::Xrepo;
use Alien::Xrepo::Build;
use Alien::Xrepo::Build::Recipe;
use experimental 'class';

# Spy repo: records every call instead of talking to xrepo. `preinstalled` maps
# package => version for the probe stage; `fail` makes install die for a package.
class Alien::Xrepo::Build::TestSpy {
    field $calls        : param = [];
    field $preinstalled : param = {};
    field $fail         : param = {};
    field $fail_once    : param = {};

    method install ( $name, $version, %opts ) {
        push @$calls, { action => 'install', name => $name, version => $version, opts => {%opts} };
        if ( $fail_once->{$name} ) { delete $fail_once->{$name}; die "boom once on $name"; }
        die "boom on $name" if $fail->{$name};
        return $self->_pkg( $name, $version );
    }

    method fetch ( $name, $version, %opts ) {
        push @$calls, { action => 'fetch', name => $name, version => $version, opts => {%opts} };
        return $self->_pkg( $name, $version );
    }

    method info ( $name, %opts ) {
        push @$calls, { action => 'info', name => $name, opts => {%opts} };
        my $v = $preinstalled->{$name};
        return $v ? { version => $v } : {};
    }

    method export ( $name, $version, %opts ) {
        push @$calls, { action => 'export', name => $name, version => $version, opts => {%opts} };
        return 1;
    }

    method add_repo ( $name, $url ) {
        push @$calls, { action => 'add_repo', name => $name, url => $url };
    }

    method update_repo ( $name //= () ) {
        push @$calls, { action => 'update_repo', name => $name };
        return 1;
    }
    method calls () { return $calls }

    method _pkg ( $name, $version ) {
        return Alien::Xrepo::PackageInfo->new(
            includedirs => ["/tmp/store/$name/include"],
            libfiles    => [],
            license     => undef,
            linkdirs    => [],
            links       => [],
            shared      => 1,
            static      => 0,
            version     => $version // '1.2.3',
            installdir  => "/tmp/store/$name",
            kind        => 'library',
        );
    }
}
my $dir = tempdir( CLEANUP => 1 );

sub build ( $packages, %opts ) {
    my $recipe = Alien::Xrepo::Build::Recipe->new( packages => $packages, %{ $opts{recipe_extra} // {} } );
    delete $opts{recipe_extra};
    return Alien::Xrepo::Build->new( recipe => $recipe, %opts );
}
subtest 'configure freezes recipe and folds ambient opts' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( [ 'zstd', { name => 'libsdl3', kind => 'shared' } ], repo => $spy, root => '/tmp/store', );
    my @hook_calls;
    $b->register_hook( configure => sub { push @hook_calls, 1 } );
    $b->configure( kind => 'static' );
    ok !defined $b->meta_prop->{name}, 'name stays undef unless recipe names it';
    is $b->meta_prop->{packages},                    [qw[zstd libsdl3]], 'meta lists packages';
    is $b->meta_prop->{package_defs}{libsdl3}{kind}, 'shared',           'meta captures defs';
    is $b->install_prop->{profile}{kind},            'static',           'ambient option folded into profile';
    is $b->install_prop->{store},                    '/tmp/store',       'store root resolved';
    is $b->install_type,                             'system',           'nothing installed yet';
    is $b->stage_done->{configure},                  1,                  'configure stage marked done';
    is scalar @hook_calls,                           1,                  'configure hook ran';
};
subtest 'probe marks satisfied packages and install skips them' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( preinstalled => { zstd => '1.5.6' } );
    my $b   = build( [ { name => 'zstd', version => '1.5.6' }, 'libsdl3' ], repo => $spy, );
    $b->run;
    my %by_action = map { $_->{action} => 1 } @{ $spy->calls };
    ok $by_action{info}, 'probe asked xrepo for each package';
    is $b->install_prop->{probed}{zstd}{satisfied},    1, 'matching version satisfied';
    is $b->install_prop->{probed}{libsdl3}{satisfied}, 0, 'no store hit for libsdl3';
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs,   1,         'only the unsatisfied package was installed';
    is $installs[0]{name}, 'libsdl3', 'skip hit the right package';
    is $b->install_type,   'share',   'a fetched package flips install_type';
};
subtest 'probe_policy always reinstalls despite a hit' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( preinstalled => { zstd => '1.5.6' } );
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'always' );
    $b->run;
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs, 1, 'always policy installed anyway';
};
subtest 'probe_policy off never probes' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'off' );
    $b->run;
    my (@infos) = grep { $_->{action} eq 'info' } @{ $spy->calls };
    is scalar @infos, 0, 'no probe calls with policy off';
    ok !$b->install_prop->{probed}{zstd}, 'no probe data recorded';
};
subtest 'a failed package isolates: siblings install, error recorded' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( fail => { libsdl3 => 1 } );
    my $b   = build( [ 'zstd', { name => 'libsdl3' }, 'ninja' ], repo => $spy, probe_policy => 'off' );
    $b->run;
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs, 3, 'all packages attempted';
    like $b->runtime_prop->{errors}{libsdl3}, qr/boom/, 'failure captured in runtime_prop';
    ok exists $b->runtime_prop->{packages}{zstd},  'sibling before the failure installed';
    ok exists $b->runtime_prop->{packages}{ninja}, 'sibling after the failure installed';
    is $b->install_type, 'share', 'a partial success is still a share install';
};
subtest 'a pinned version reaches install and probe falls through' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( preinstalled => { raylib => '6.0' } );
    my $b   = build( [ { name => 'raylib', version => '6.0.x', kind => 'shared' } ], repo => $spy );
    $b->run;
    ok !$b->install_prop->{probed}{raylib}{satisfied}, 'exact-match probe cannot satisfy a 6.0.x pattern';
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs,                              1,       'the pinned package was installed';
    is $installs[0]{version},                         '6.0.x', 'install asked for the pinned version';
    is $b->runtime_prop->{packages}{raylib}{version}, '6.0.x', 'runtime data carries the pinned version';
};
subtest 'update_repo refreshes repositories and retries the install once' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( fail_once => { raylib => 1 } );
    my $b   = build( ['raylib'], repo => $spy, probe_policy => 'off', update_repo => 1 );
    $b->run;
    my (@updates) = grep { $_->{action} eq 'update_repo' } @{ $spy->calls };
    is scalar @updates, 1, 'registry refreshed exactly once';
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs, 2, 'install attempted again after the refresh';
    ok exists $b->runtime_prop->{packages}{raylib}, 'retried install resolved the package';
    ok !exists $b->runtime_prop->{errors}{raylib},  'no error recorded after the retry succeeded';
};
subtest 'a still-failing install records the error after one refresh' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new( fail => { raylib => 1 } );
    my $b   = build( ['raylib'], repo => $spy, probe_policy => 'off', update_repo => 1 );
    $b->run;
    my (@updates)  = grep { $_->{action} eq 'update_repo' } @{ $spy->calls };
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @updates,  1, 'refresh ran before the final attempt';
    is scalar @installs, 2, 'two attempts total';
    like $b->runtime_prop->{errors}{raylib}, qr/boom/, 'failure recorded after the retry limit';
};
subtest 'gather fetches anything the install did not produce' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'off' );
    $b->install;
    $b->gather;
    my (@fetches) = grep { $_->{action} eq 'fetch' } @{ $spy->calls };
    is scalar @fetches,                             0,       'gather skips packages already gathered by install';
    is $b->runtime_prop->{packages}{zstd}{version}, '1.2.3', 'runtime data present';
    my $spy2 = Alien::Xrepo::Build::TestSpy->new;
    my $b2   = build( ['zstd'], repo => $spy2, probe_policy => 'off' );
    $b2->gather;
    my (@f2) = grep { $_->{action} eq 'fetch' } @{ $spy2->calls };
    is scalar @f2, 1, 'gather fetches when install never ran';
};
subtest 'export writes the runtime snapshot' => sub {
    my $snap = path($dir)->child('snapshot.json');
    my $spy  = Alien::Xrepo::Build::TestSpy->new;
    my $b    = build( [ { name => 'zstd', version => '1.5.6' } ], repo => $spy, probe_policy => 'off', snapshot => $snap );
    $b->run;
    ok -e $snap, 'snapshot file written';
    my $data = decode_json( $snap->slurp_utf8 );
    is $data->{install_type},               'share',           'snapshot records install_type';
    is $data->{packages}{zstd}{version},    '1.5.6',           'snapshot records runtime data';
    is $data->{packages}{zstd}{installdir}, '/tmp/store/zstd', 'snapshot records installdir';
};
subtest 'checkpoint/resume skips completed work' => sub {
    my $cp  = path($dir)->child('state.json');
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'off', checkpoint => $cp );
    $b->run;
    my $calls_after_first = scalar @{ $spy->calls };
    ok $calls_after_first > 0, 'first run made calls';
    ok -e $cp,                 'checkpoint file written';
    my $spy2      = Alien::Xrepo::Build::TestSpy->new;
    my $b2        = build( ['zstd'], repo => $spy2, probe_policy => 'off', checkpoint => $cp, resume => 1 );
    my @installs2 = grep { $_->{action} eq 'install' } @{ $spy2->calls };
    is scalar @installs2,                            0,       'resume did not reinstall';
    is $b2->install_type,                            'share', 'resumed build kept prior install_type';
    is $b2->runtime_prop->{packages}{zstd}{version}, '1.2.3', 'resumed build kept runtime data';
    is $b2->stage_done->{install},                   1,       'resumed build knows install completed';
};
subtest 'hooks run for every registered stage' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'off' );
    my @ran;
    for my $stage (qw[install gather]) {
        $b->register_hook( $stage => sub { push @ran, $stage } );
    }
    ok $b->has_hook('install'), 'register_hook/has_hook agree';
    ok !$b->has_hook('probe'),  'unregistered stage has no hooks';
    like dies {
        $b->register_hook( bogus => sub { } )
    }, qr/Unknown stage/, 'bad stage dies';
    $b->run;
    is \@ran, [qw[install gather]], 'hooks fired in stage order';
};
our @HOOK_RAN;
subtest 'recipe hooks load once and register stage callbacks' => sub {
    my $hdir = Path::Tiny->tempdir;
    $hdir->child('RecipeHooksDemo.pm')->spew_utf8(
        q{
        package RecipeHooksDemo;
        sub register_hooks {
            my ($build) = @_;
            push @main::HOOK_RAN, 'register';
            $build->register_hook( install => sub { push @main::HOOK_RAN, 'install' } );
        }
        1;
    }
    );
    local @INC = ( @INC, $hdir->stringify );
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, probe_policy => 'off', recipe_extra => { hooks => ['RecipeHooksDemo'] } );
    is \@main::HOOK_RAN, [], 'nothing registered before configure';
    $b->configure;
    is \@main::HOOK_RAN,        ['register'], 'recipe hook module saw register_hooks';
    is $b->has_hook('install'), 1,            'recipe hook attached a stage hook';
    @main::HOOK_RAN = ();
    $b->configure;
    is scalar @main::HOOK_RAN, 0, 'recipe hooks load once even if configure repeats';
    $b->install;
    is \@main::HOOK_RAN, ['install'], 'recipe-registered hook fired at its stage';
};
subtest 'recipe hooks die clearly when the module lacks register_hooks' => sub {
    my $hdir = Path::Tiny->tempdir;
    $hdir->child('RecipeHooksBad.pm')->spew_utf8("package RecipeHooksBad;\n1;\n");
    local @INC = ( @INC, $hdir->stringify );
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, recipe_extra => { hooks => ['RecipeHooksBad'] } );
    like dies { $b->configure }, qr/register_hooks/, 'missing register_hooks dies at configure';
};
subtest 'pkg_roots resolve a package from a system root' => sub {
    my $root = Path::Tiny->tempdir;
    $root->child('include')->mkpath;
    $root->child('lib')->mkpath;
    $root->child( 'include', 'zstd.h' )->spew_utf8('#define ZSTD 1');
    $root->child( 'lib',     'libzstd.a' )->spew_utf8('');
    local $ENV{ZSTD_ROOT} = $root->stringify;
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, recipe_extra => { pkg_roots => { zstd => 'ZSTD_ROOT' } } );
    $b->run;
    my (@infos)    = grep { $_->{action} eq 'info' } @{ $spy->calls };
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    my (@fetches)  = grep { $_->{action} eq 'fetch' } @{ $spy->calls };
    is scalar @infos,                                      0,                'probe never consults xrepo for a root-resolved package';
    is scalar @installs,                                   0,                'install never consults xrepo for a root-resolved package';
    is scalar @fetches,                                    0,                'gather never consults xrepo for a root-resolved package';
    is $b->install_prop->{probed}{zstd}{satisfied},        1,                'probe reports the root-satisfied package';
    is $b->install_prop->{probed}{zstd}{root},             $root->stringify, 'probe records the root';
    is $b->runtime_prop->{packages}{zstd}{installdir},     $root->stringify, 'package data points at the root';
    is $b->runtime_prop->{packages}{zstd}{includedirs}[0], $root->child('include')->stringify, 'include dir from the root';
    is $b->runtime_prop->{packages}{zstd}{linkdirs}[0],    $root->child('lib')->stringify,     'lib dir from the root';
    is $b->runtime_prop->{packages}{zstd}{kind},           'system',                           'root entry marked as system-provided';
    is $b->install_type,                                   'system', 'a root-resolved package leaves install_type at system';
    ok !exists $b->runtime_prop->{errors}{zstd}, 'no error recorded';
};
subtest 'pkg_roots ignore a variable that does not name a directory' => sub {
    local $ENV{ZSTD_ROOT} = 'C:/definitely/not/a/real/zstd/root';
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = build( ['zstd'], repo => $spy, recipe_extra => { pkg_roots => { zstd => 'ZSTD_ROOT' } } );
    $b->run;
    my (@infos) = grep { $_->{action} eq 'info' } @{ $spy->calls };
    is scalar @infos,                               1, 'probe consulted xrepo when the root env var was unusable';
    is $b->install_prop->{probed}{zstd}{satisfied}, 0, 'package not satisfied by a dead root';
    ok exists $b->runtime_prop->{packages}{zstd}, 'package installed via xrepo as normal';
};
subtest 'Build accepts a hashref recipe from a subclass recipe()' => sub {
    my $spy = Alien::Xrepo::Build::TestSpy->new;
    my $b   = Alien::Xrepo::Build->new(
        recipe => {
            name        => 'Alien-TestFull',
            packages    => [ { name => 'zstd', version => '1.5.6', kind => 'shared' } ],
            defaults    => { mode => 'release' },
            local_repos => ['vendor/recipes'],
        },
        repo         => $spy,
        root         => '/tmp/store',
        probe_policy => 'off',
    );
    $b->run;
    is $b->meta_prop->{name},             'Alien-TestFull', 'name from hashref recipe';
    is $b->meta_prop->{packages},         ['zstd'],         'packages from hashref recipe';
    is $b->install_prop->{profile}{mode}, 'release',        'defaults folded into profile';
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is $installs[0]{opts}{kind},                    'shared',     'per-package def folded into install opts';
    is $b->runtime_prop->{packages}{zstd}{version}, '1.5.6',      'install ran with the recipe version';
    is $b->install_prop->{store},                   '/tmp/store', 'store root resolved';
    is $b->install_type,                            'share',      'share install';
};

# Spy whose installs record opts and derive the reported paths from the
# requested installdir, so share_dir behaviour can be verified without xrepo.
class Alien::Xrepo::Build::TestShare {
    field $calls : param = [];

    method install ( $name, $version, %opts ) {
        push @$calls, { action => 'install', name => $name, version => $version, opts => {%opts} };
        return $self->_pkg( $name, $version, %opts );
    }

    method fetch ( $name, $version, %opts ) {
        push @$calls, { action => 'fetch', name => $name, version => $version, opts => {%opts} };
        return $self->_pkg( $name, $version, %opts );
    }
    method info   ( $name, %opts )           { push @$calls, { action => 'info',   name => $name, opts    => {%opts} }; return {}; }
    method export ( $name, $version, %opts ) { push @$calls, { action => 'export', name => $name, version => $version, opts => {%opts} }; return 1; }
    method add_repo ( $name, $url )          { push @$calls, { action => 'add_repo', name => $name, url => $url }; }
    method calls () {$calls}

    method _pkg ( $name, $version, %opts ) {
        my $dir = defined $opts{installdir} ? $opts{installdir} : "/tmp/default/$name";
        return Alien::Xrepo::PackageInfo->new(
            includedirs => [ Path::Tiny::path($dir)->child('include')->stringify ],
            libfiles    => [],
            license     => undef,
            linkdirs    => [],
            links       => [],
            shared      => 1,
            static      => 0,
            version     => $version // '1.2.3',
            installdir  => $dir,
            kind        => 'library',
        );
    }
}
subtest 'share_dir shallow-installs packages and records share-relative paths' => sub {
    my $share = path($dir)->child('share');
    my $snap  = $share->child('xrepo-snapshot.json');
    my $spy   = Alien::Xrepo::Build::TestShare->new;
    my $b     = Alien::Xrepo::Build->new(
        recipe       => { name => 'Alien-TestFull', packages => [ { name => 'zstd', version => '1.5.6' }, 'libsdl3' ] },
        repo         => $spy,
        share_dir    => $share->stringify,
        snapshot     => $snap,
        probe_policy => 'off',
    );
    $b->run;
    my (@installs) = grep { $_->{action} eq 'install' } @{ $spy->calls };
    is scalar @installs,               2,                                         'both packages installed';
    is $installs[0]{opts}{installdir}, path($share)->child('zstd')->stringify,    'zstd installation goes into the sharedir';
    is $installs[1]{opts}{installdir}, path($share)->child('libsdl3')->stringify, 'libsdl3 installation goes into the sharedir';
    my (@fetches) = grep { $_->{action} eq 'fetch' } @{ $spy->calls };
    is scalar @fetches, 0, 'gather reuses install data (no extra fetch)';
    my $data = decode_json( $snap->slurp_utf8 );
    is $data->{packages}{zstd}{installdir}, 'zstd', 'snapshot installdir is share-relative';
    like $data->{packages}{zstd}{includedirs}[0], qr/^zstd[\\\/]include$/, 'snapshot includedirs are share-relative';
    is $data->{install_type},         'share',           'share install recorded';
    is $b->install_prop->{share_dir}, $share->stringify, 'share_dir recorded in install_prop';
};
done_testing;
