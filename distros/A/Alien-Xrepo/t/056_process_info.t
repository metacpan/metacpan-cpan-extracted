use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use experimental 'class';
use Alien::Xrepo;
use File::Temp qw[tempdir];
use Path::Tiny;
#
my $repo = Alien::Xrepo->new( verbose => 0, cache => 0 );

# The only library extension that is unambiguous on the platform we are running on: an import lib on Windows, a static
# archive everywhere else. Both are what a static-only port ships and neither has a shared object to dlopen.
my $static_name = $^O eq 'MSWin32' ? 'zlib.lib' : 'libz.a';
subtest 'an install tree holding libraries is not mistaken for a header-only package' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) )->child('zlib');
    $dir->child('lib')->mkpath;
    $dir->child('include')->mkpath;
    $dir->child( 'include', 'zlib.h' )->spew_utf8(q{});
    my $lib = $dir->child( 'lib', $static_name );
    $lib->spew_utf8(q{});
    my $info = $repo->_process_info(
        {   libfiles    => [],
            includedirs => [ $dir->child('include')->stringify ],
            linkdirs    => [],
            version     => '1.3.2',
            artifacts   => { installdir => $dir->stringify }
        }
    );
    is $info->libpath,           $lib->stringify,                   'libpath points at the library xrepo did not list';
    is [ @{ $info->libfiles } ], [ $lib->stringify ],               'libfiles recovered from the install tree';
    is $info->kind,              'library',                         'a package with libraries is not demoted to a binary tool';
    is [ @{ $info->linkdirs } ], [ $dir->child('lib')->stringify ], 'the directory that yielded files joins linkdirs';
    ok $info->find_header('zlib.h'), 'headers still resolve alongside the recovered library';
};
subtest 'a genuinely header-only package stays header-only' => sub {
    my $dir = path( tempdir( CLEANUP => 1 ) )->child('headers-only');
    $dir->child('lib')->mkpath;
    $dir->child('include')->mkpath;
    $dir->child( 'include', 'zlib.h' )->spew_utf8(q{});
    $dir->child( 'lib',     'zlib.pc' )->spew_utf8(q{});
    $dir->child( 'lib',     'notes.txt' )->spew_utf8(q{});
    my $info = $repo->_process_info(
        {   libfiles    => [],
            includedirs => [ $dir->child('include')->stringify ],
            linkdirs    => [],
            version     => '1.0.0',
            artifacts   => { installdir => $dir->stringify }
        }
    );
    is $info->libpath,           undef, 'libpath stays undef when the tree really has no library';
    is [ @{ $info->libfiles } ], [],    'no libfiles invented out of a lib dir of non-libraries';
    is [ @{ $info->linkdirs } ], [],    'a lib dir that yielded nothing does not join linkdirs';
};
subtest 'libfiles xrepo did report are left alone' => sub {
    my $dir  = path( tempdir( CLEANUP => 1 ) )->child('reported');
    my $real = $dir->child( 'lib', $static_name );
    $dir->child('lib')->mkpath;
    $real->spew_utf8(q{});
    my $other = "$dir/somewhere-else/$static_name";
    my $info  = $repo->_process_info(
        { libfiles => [$other], includedirs => [], linkdirs => [], version => '2.0.0', artifacts => { installdir => $dir->stringify } } );
    is $info->libpath,           $other,   'the reported libfile wins over anything found on disk';
    is [ @{ $info->libfiles } ], [$other], 'libfiles are not supplemented when xrepo already listed some';
};
#
done_testing;
