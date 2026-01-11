use v5.40;
use Alien::Xrepo;

# Initialize
my $repo = Alien::Xrepo->new();

# Add a custom repository (optional)
# $repo->add_repo( 'my-repo', 'https://github.com/my/repo.git' );
# Install a shared lib with an automatic configuration
my $ogg = $repo->install('libvorbis');

# Install a library with specific configuration
# equivalent to: xrepo install -p windows -a x86_64 -m debug --configs='shared=true,vs_runtime=MD' libpng
my $pkg = $repo->install( 'libpng', '1.6.x', plat => 'windows', arch => 'x64', mode => 'debug', configs => { vs_runtime => 'MD' } );
die 'Install failed' unless $pkg;

# Automatically wrap zlib as a whole with Affix::Wrap
use Affix;
use Affix::Wrap;
my $zlib = $repo->install('zlib');
Affix::Wrap->new(
    project_files => [ $zlib->find_header('zlib.h') ],
    include_dirs  => [ $zlib->includedirs ],
    types         => { gzFile_s => Pointer [Void] }
)->wrap( $zlib->libpath );
say 'zlib version:   ' . zlibVersion();

# Wrap a single function from sqlite3 with Affix
use Affix;
my $sqlite3 = $repo->install('sqlite3');
affix $sqlite3->libpath, 'sqlite3_libversion', [], String;
say 'SQLite version: ' . sqlite3_libversion();

# Wrap a single function from libpng with FFI::Platypus
use FFI::Platypus;
my $lz4 = $repo->install('lz4');
my $ffi = FFI::Platypus->new;
$ffi->lib( $lz4->libpath );
$ffi->attach( 'LZ4_versionString', [] => 'string' );
say 'LZ4 version:    ' . LZ4_versionString();
