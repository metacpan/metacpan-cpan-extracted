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
    $dir->child( 'include', 'zlib.h' )->spew_utf8('');
    my $lib = $dir->child( 'lib', $static_name );
    $lib->spew_utf8('');
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
    $dir->child( 'include', 'zlib.h' )->spew_utf8('');
    $dir->child( 'lib',     'zlib.pc' )->spew_utf8('');
    $dir->child( 'lib',     'notes.txt' )->spew_utf8('');
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
    $real->spew_utf8('');
    my $other = "$dir/somewhere-else/$static_name";
    my $info  = $repo->_process_info(
        { libfiles => [$other], includedirs => [], linkdirs => [], version => '2.0.0', artifacts => { installdir => $dir->stringify } } );
    is $info->libpath,           $other,   'the reported libfile wins over anything found on disk';
    is [ @{ $info->libfiles } ], [$other], 'libfiles are not supplemented when xrepo already listed some';
};
subtest 'on Windows, the DLL the package links against wins the libpath' => sub {
    local $^O = 'MSWin32';    # exercise the Windows branch on any platform; tree is just files
    my $dir     = path( tempdir( CLEANUP => 1 ) )->child('sdl3_image');
    my $imp     = $dir->child( 'bin', 'SDL3_image.lib' );
    my $codec   = $dir->child( 'bin', 'libavif-16.dll' );
    my $runtime = $dir->child( 'bin', 'SDL3_image.dll' );
    $dir->child('bin')->mkpath;
    for ( $imp, $codec, $runtime ) { $_->spew_utf8(''); }
    my $info = $repo->_process_info(
        {   libfiles    => [ map { $_->stringify } $imp, $codec, $runtime ],
            includedirs => [],
            linkdirs    => [],
            version     => '3.4.0',
            links       => ['SDL3_image'],
            artifacts   => { installdir => $dir->stringify }
        }
    );
    is $info->libpath, $runtime->stringify, 'a DLL matching the package links wins over one that sorts first (libavif < SDL3_image)';
};
subtest 'on Windows, DLLs are preferred over import libs even when links match nothing' => sub {
    local $^O = 'MSWin32';
    my $dir   = path( tempdir( CLEANUP => 1 ) )->child('mismatched');
    my $imp   = $dir->child( 'bin', 'sdl3_image.lib' );
    my $codec = $dir->child( 'bin', 'libavif-16.dll' );
    $dir->child('bin')->mkpath;
    for ( $imp, $codec ) { $_->spew_utf8(''); }
    my $info = $repo->_process_info(
        {   libfiles    => [ map { $_->stringify } $imp, $codec ],
            includedirs => [],
            linkdirs    => [],
            version     => '3.4.0',
            links       => ['SDL2_unknown'],
            artifacts   => { installdir => $dir->stringify }
        }
    );
    is $info->libpath, $codec->stringify, 'falls back to the first DLL when no DLL matches the links';
};
#
done_testing;
