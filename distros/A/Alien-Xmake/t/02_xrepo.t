use v5.40;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib 'lib', '../lib', 'blib/lib', '../blib/lib';
use Alien::Xmake;
use Alien::Xrepo;
#
ok $Alien::Xrepo::VERSION, 'Alien::Xrepo::VERSION';
#
my $repo  = Alien::Xrepo->new( verbose => 0 );
my $xmake = Alien::Xmake->new;
my $exe   = $xmake->exe;
diag `$exe --help`;
diag $exe;

#~ diag `$exe update`;
#~ xmake.exe lua private.xrepo install -y -k shared libpng
diag `$exe lua private.xrepo install -y -k shared libpng`;
ok my $pkg = $repo->install('libpng'), 'install libpng';
skip_all 'Failed to install libpng', 3 unless $pkg;
diag 'Found library at: ' . $pkg->libpath;
diag 'Version: ' . $pkg->version;
diag 'License: ' . $pkg->license;
diag 'Header:  ' . $pkg->find_header('png.h');
diag 'Include dirs: ';
diag '     - ' . $_ for @{ $pkg->includedirs };
diag 'Lib:     ' . $pkg->libpath;
#
done_testing;
