use v5.40;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Alien::Xmake;
use Alien::Xrepo;
use File::Temp qw[tempdir];
#
ok $Alien::Xrepo::VERSION, 'Alien::Xrepo::VERSION';
#
my $repo  = Alien::Xrepo->new( verbose => 0, kind => 'shared' );
my $xmake = Alien::Xmake->new;
my $exe   = $xmake->exe;
qx["$exe" g --theme=plain];
diag `"$exe" --help`;
diag $exe;

#~ diag `$exe update`;
#~ xmake.exe lua private.xrepo install -y -k shared libpng
diag `"$exe" lua private.xrepo install -y -k shared libpng`;
ok my $pkg = $repo->install('libpng'), 'install libpng';
skip_all 'Failed to install libpng', 3 unless $pkg;
diag 'Found library at: ' . $pkg->libpath;
diag 'Version: ' . $pkg->version;
diag 'License: ' . $pkg->license;
diag 'Header:  ' . $pkg->find_header('png.h');
diag 'Include dirs: ';
diag '     - ' . $_ for @{ $pkg->includedirs };
diag 'Lib:     ' . $pkg->libpath;

# Refetch an already-installed package without reinstalling
ok my $refetched = $repo->fetch('libpng'), 'fetch installed libpng';
is $refetched->version, $pkg->version, 'fetch agrees on version';
ok length( $refetched->libpath ),                          'fetch found a runtime lib';
ok length( $repo->fetch( 'libpng', undef, cflags => 1 ) ), 'fetch --cflags works';

# Query-only / metadata operations
ok scalar( $repo->list_repo ) > 0,                       'list_repo returns repos';
ok scalar( grep {/libpng/} $repo->scan('libpng') ),      'scan finds libpng';
ok my $info = $repo->info( 'libpng', format => 'json' ), 'info --format=json works';
is ref $info, 'ARRAY', 'info json is an array';

# Isolated package store (reproducible builds). zlib rather than pcre2: the GitHub macOS
# runner images carry a Homebrew pcre2, so xmake resolves that system package instead of
# building into the forced dir and the isolation assertions never hold there.
my $iso_root = tempdir( CLEANUP => 1 );
ok my $iso = $repo->install( 'zlib', undef, installdir => $iso_root ), 'install zlib into an isolated store';
ok length( $iso->libpath ), 'isolated install found a runtime lib';
diag 'Isolated libpath: ' . ( $iso->libpath // '(undef)' );
my ( $iso_lib, $iso_rel ) = map { ( $_ // '' ) =~ s{\\}{/}gr } ( $iso->libpath, $iso_root );
ok index( $iso_lib, $iso_rel ) == 0, 'isolated libpath lives under the forced dir';
ok my $iso_fetched = $repo->fetch( 'zlib', undef, installdir => $iso_root ), 'fetch from isolated store';
( $iso_lib, $iso_rel ) = map { ( $_ // '' ) =~ s{\\}{/}gr } ( $iso_fetched->libpath, $iso_root );
ok index( $iso_lib, $iso_rel ) == 0,                                       'isolated fetch stays in the forced dir';
ok scalar( grep {/zlib/} $repo->scan( 'zlib', installdir => $iso_root ) ), 'scan finds zlib in isolated store';
#
done_testing;
