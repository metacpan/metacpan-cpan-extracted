use v5.40;
use blib;
use Alien::Xrepo;
$|++;

# Initialize
my $repo = Alien::Xrepo->new();

# List configured remote repositories
say 'Remote repositories';
say for $repo->list_repo;

# Search for a package (addon => search <repository>/addons/)
# $repo->search( 'sqlite', addon => 1 );
# Show info about an installed package (as JSON)
# my $info = $repo->info( 'zlib', format => 'json' );
# Scan installed packages (optional lua-pattern filter)
say 'Installed libpng';
say for $repo->scan('libpng');

# Fetch info for an already-installed package without installing again
# my $pkg = $repo->fetch('zlib');
# Add a custom repository (optional)
# $repo->add_repo( 'my-repo', 'https://github.com/my/repo.git' );
# Install a shared lib with an automatic configuration
my $ogg = $repo->install( 'libvorbis', undef, kind => 'shared' );

# Install a library with specific configuration
# equivalent to: xrepo install -p windows -a x86_64 -m debug --configs='shared=true,vs_runtime=MD' libpng
my $pkg = $repo->install( 'libpng', '1.6.x', kind => 'shared', plat => 'windows', arch => 'x64', mode => 'debug', configs => { vs_runtime => 'MD' } );
die 'Install failed' unless $pkg;
{    # Bind a single zlib function with Affix (fast; Affix::Wrap can block for

    # a very long time parsing zlib.h on some platforms)
    use Affix;
    my $zlib = $repo->install( 'zlib', undef, kind => 'shared' );
    affix $zlib->libpath, 'zlibVersion', [], String;
    say 'zlib version:   ' . zlibVersion();
}
{    # Wrap a single function from sqlite3 with Affix
    use Affix;
    my $sqlite3 = $repo->install( 'sqlite3', undef, kind => 'shared' );
    affix $sqlite3->libpath, 'sqlite3_libversion', [], String;
    say 'SQLite version: ' . sqlite3_libversion();
}
{    # Wrap a single function from libpng with FFI::Platypus
    use FFI::Platypus;
    my $lz4 = $repo->install( 'lz4', undef, kind => 'shared' );
    my $ffi = FFI::Platypus->new;
    $ffi->lib( $lz4->libpath );
    $ffi->attach( 'LZ4_versionString', [] => 'string' );
    say 'LZ4 version:    ' . LZ4_versionString();
}
