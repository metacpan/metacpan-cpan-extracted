use v5.40;
use Alien::Xmake;
use Path::Tiny;
#
my $xmake = Alien::Xmake->new();

# Locate xrepo: usually sits next to the xmake binary
my $xrepo_bin = $xmake->xrepo;
my $library   = 'zlib';

# Get Information about a package
say "Fetching info for $library...";
system $xrepo_bin, 'info', $library;

# Install the package
say "\nInstalling $library...";
system( $xrepo_bin, 'install', '-y', $library ) == 0 or die "Failed to install $library";

# Fetch integration flags (CFLAGS/LDFLAGS)
# This is useful if you want to use the library in a non-xmake build system (like MakeMaker)
say "\nFetching build flags for $library...";
my $flags = qx[$xrepo_bin fetch --cflags --ldflags $library];
if ($flags) {
    say 'Flags acquired:';
    say $flags;
}
else {
    warn 'Could not fetch flags.';
}
