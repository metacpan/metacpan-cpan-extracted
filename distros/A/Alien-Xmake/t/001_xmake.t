use v5.40;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use blib;
use Cwd;
use File::Temp    qw[tempdir];
use Capture::Tiny qw[capture];
use Alien::Xmake;
#
ok $Alien::Xmake::VERSION, 'Alien::Xmake::VERSION';
#
my $xmake = Alien::Xmake->new;
ok $xmake->version,         'version is set';
ok defined $xmake->buildid, 'buildid is defined-ish';
ok my $exe = $xmake->exe,   'exe works';
qx["$exe" g --theme=plain];

# Query mode
my @platforms = $xmake->show('platforms');
ok scalar @platforms > 0, 'show -l platforms returns a list';
my $lua_scripts = $xmake->lua( undef, list => 1 );
ok length( $lua_scripts // '' ), 'lua --list returns scripts';
my $macros = $xmake->macro( undef, list => 1 );
ok defined $macros, 'macro list returns output';
my $checks = $xmake->check( undef, list => 1 );
ok defined $checks, 'check list returns output';
subtest 'inline lua' => sub {
    my $json_ok = 0;
    for my $code ( q{print(os.host())}, q{import("core.base.json"); print(json.encode({host=os.host()}))}, ) {
        my ( $out, $err, $exit ) = capture { $xmake->lua($code) };
        ok length($out) > 0 || $exit == 0, 'lua inline evaluated (no hang/mangle/spawn error)';
        $json_ok++ if $out =~ /\{\s*"host"/;
    }
    is $json_ok, 1, 'the json snippet printed a parseable {"host":...} line';
};
subtest 'lua_json decodes emitted / returned Lua values' => sub {
    my $host = $xmake->lua_json( 'os.host()', return => 1 );
    ok defined $host && length $host, 'lua_json(return=>1) decodes a scalar';
    my $arr = $xmake->lua_json( q{{1, 2, 3}}, return => 1 );
    is ref $arr,       'ARRAY', 'lua_json returns a table as an ARRAY';
    is scalar @{$arr}, 3,       'array has three elements';
    my $nested = $xmake->lua_json( q{{name='z', libs={'z','m'}}}, return => 1 );
    is ref $nested,     'HASH',       'lua_json returns a nested HASH';
    is $nested->{libs}, [ 'z', 'm' ], 'nested list decoded';
    my @none = $xmake->lua_json(q{print('no json')});
    ok !scalar @none, 'lua_json with no JSON returns empty list';
};
subtest 'scaffold a project and drive it' => sub {
    my $old = getcwd;
    my $dir = tempdir( CLEANUP => 1 );
    chdir $dir or die "chdir $dir: $!";
    local $@;
    ok $xmake->create( 't_demo', template => 'console' ), 'create scaffolds a project';
    ok -f 't_demo/xmake.lua',                             'xmake.lua was generated';
    chdir 't_demo' or die 'chdir t_demo: $!';
    ok $xmake->configure( mode => 'debug', jobs => 2 ), 'configure succeeds';
    my $targets = $xmake->show( 'targets', format => 'json' );
    is ref $targets, 'ARRAY', 'show -l targets --format=json is an array';
    ok scalar @{$targets}, 'at least one target';
    my $t = $xmake->target_info( $targets->[0] );
    is ref $t, 'HASH', 'target_info returns a decoded HASH';
    ok $t->{name} && $t->{kind}, 'target_info has name and kind';
    ok defined $t->{targetfile}, 'target_info exposes targetfile';
    my $t_plain = $xmake->target_info( $targets->[0], plain => 1 );
    ok length $t_plain, 'target_info(plain=>1) returns text';
    ok $xmake->clean,   'clean succeeds';
    chdir $old or die "chdir $old: $!";
};
subtest 'drive a Perl-generated build file via file=>' => sub {
    my $old = getcwd;
    my $dir = tempdir( CLEANUP => 1 );
    mkdir "$dir/src" or die "mkdir src: $!";
    open my $fh, '>', "$dir/src/main.cpp" or die "src/main.cpp: $!";
    print {$fh} "int main(){ return 0; }\n";
    close $fh;
    open my $bf, '>', "$dir/mybuild.lua" or die "mybuild.lua: $!";
    print {$bf} "set_project('gen')\ntarget('app')\n  set_kind('binary')\n  add_files('src/main.cpp')\n";
    close $bf;
    my $g = Alien::Xmake->new( file => "$dir/mybuild.lua" );
    chdir $dir or die "chdir $dir: $!";
    ok $g->configure( mode => 'release' ), 'configure reads the -F build file';
    ok $g->build,                          'build from the generated build file';
    my $targets = $g->show( 'targets', format => 'json' );
    is $targets, ['app'], 'targets reflect the generated build file';
    my $t = $g->target_info('app');
    is $t->{kind}, 'binary', 'target_info sees the generated target';
    ok $g->clean, 'clean from the generated build file';
    chdir $old or die "chdir $old: $!";
};
#
done_testing;
