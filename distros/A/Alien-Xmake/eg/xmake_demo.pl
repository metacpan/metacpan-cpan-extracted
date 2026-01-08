use v5.40;
use Alien::Xmake;
use Path::Tiny;

# Setup
my $xmake     = Alien::Xmake->new();
my $xmake_bin = $xmake->exe;
my $version   = $xmake->config('version');
say "Using xmake $version at $xmake_bin";

# Create a temporary project directory
my $project_dir = Path::Tiny->tempdir( CLEANUP => 1 );
say "Working in: $project_dir";

# Use 'xmake create' to generate a C shared library project
# -P .      : Create in current directory
# -l c      : Language C
# -t shared : Shared library
chdir $project_dir;
system( $xmake_bin, 'create', '-P', '.', '-l', 'c', '-t', 'shared', 'alien_lib' ) == 0 or die "Failed to create project";

# Build the project
say 'Building project...';
system($xmake_bin) == 0 or die "Build failed";

# Install to a local directory to verify artifacts
my $install_dir = $project_dir->child('dist');
say "Installing to $install_dir...";
system( $xmake_bin, 'install', '-o', $install_dir ) == 0 or die 'Install failed';

# Verify output
my $lib_dir = $install_dir->child('lib');
if ( $lib_dir->exists ) {
    $lib_dir->visit(
        sub {
            my ($path) = @_;
            return unless $path->is_file;
            say ' - Artifact found: ' . $path->relative($install_dir);
        },
        { recurse => 1 }
    );
}
else {
    warn 'No library directory found.';
}
