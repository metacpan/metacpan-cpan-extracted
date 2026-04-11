#!/usr/bin/env perl
#
# pack.pl - Pack the example Chandra app into a distributable bundle
#
# Usage:
#   cd examples/pack_example
#   perl pack.pl                       # builds for current platform
#   perl pack.pl --platform=linux      # cross-target
#   perl pack.pl --distribute          # build + sign/notarize/DMG (macOS) or AppImage (Linux)
#
# For distribution on macOS, configure signing credentials first:
#   Chandra::Pack->config(
#       identity  => 'Developer ID Application: ...',
#       apple_id  => 'your@email.com',
#       team_id   => 'TEAM123',
#   );
# Or via environment: CHANDRA_IDENTITY, CHANDRA_APPLE_ID, CHANDRA_TEAM_ID
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch";
use Chandra::Pack;

my $platform   = 'macos';
my $distribute = 0;

for (@ARGV) {
    $platform   = $1 if /^--platform=(\w+)$/;
    $distribute = 1  if /^--distribute$/;
}

my $packer = Chandra::Pack->new(
    script     => "$FindBin::Bin/app.pl",
    name       => 'PackedCounter',
    version    => '1.0.0',
    identifier => 'org.perl.packed-counter',
    assets     => "$FindBin::Bin/assets",
    output     => "$FindBin::Bin/dist",
    platform   => $platform,
    include    => ['PackedCounter'],
    distribute => $distribute,
);

print "Scanning dependencies...\n";
my @deps = $packer->scan_deps;
printf "  Found %d dependencies\n", scalar @deps;
for my $dep (@deps) {
    printf "    %s => %s\n", $dep->{module}, $dep->{file};
}

print "\nBuilding for $platform", ($distribute ? " (with distribution)" : ""), "...\n";
$packer->build(sub {
    my ($result) = @_;
    if ($result->{success}) {
        printf "Done! Bundle at: %s (%d bytes)\n",
            $result->{path}, $result->{size};
        
        if ($result->{signed}) {
            print "  ✓ Code signed\n";
        }
        if ($result->{notarized}) {
            print "  ✓ Notarized with Apple\n";
        }
        if ($result->{dmg_path}) {
            printf "  ✓ DMG created: %s\n", $result->{dmg_path};
        }
        if ($result->{appimage_path}) {
            printf "  ✓ AppImage created: %s\n", $result->{appimage_path};
        }
    } else {
        die "Pack failed: " . ($result->{error} || "unknown error") . "\n";
    }
});
