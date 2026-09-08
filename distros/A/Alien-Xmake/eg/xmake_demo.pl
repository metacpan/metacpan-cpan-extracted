use v5.40;
use blib;
use Alien::Xmake;
use Path::Tiny;

# Setup
my $xmake     = Alien::Xmake->new();
my $xmake_bin = $xmake->exe;
my $version   = $xmake->config('version');
say "Using xmake $version at $xmake_bin";

# Create a temporary project directory
my $project_dir = Path::Tiny->tempdir( CLEANUP => 0 );
say 'Working in: ' . $project_dir;

# Use 'xmake create' to generate a C shared library project
chdir $project_dir;
$xmake->create( 'alien_lib', project => '.', language => 'c', template => 'shared' ) or die 'Failed to create project';

# Build the project
say 'Building project...';
$xmake->build or die 'Build failed';

# Install to a local directory to verify artifacts
my $install_dir = $project_dir->child('dist');
say "Installing to $install_dir...";
$xmake->install( 'alien_lib', installdir => $install_dir ) or die 'Install failed';

# Verify output
my $lib_dir = $install_dir->child('lib');
exit say 'No library directory found.' unless $lib_dir->exists;
$lib_dir->visit(
    sub {
        my ($path) = @_;
        return unless $path->is_file;
        say ' - Artifact found: ' . $path->relative($install_dir);
    },
    { recurse => 1 }
);
