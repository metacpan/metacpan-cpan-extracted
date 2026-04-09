#!/usr/bin/env perl
#
# pack.pl - Pack the example Chandra app into a distributable bundle
#
# Usage:
#   cd examples/pack_example
#   perl pack.pl                    # builds for current platform
#   perl pack.pl --platform=linux   # cross-target
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch";
use Chandra::Pack;

my $platform = 'macos';
for (@ARGV) {
    $platform = $1 if /^--platform=(\w+)$/;
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
);

print "Scanning dependencies...\n";
my @deps = $packer->scan_deps;
printf "  Found %d dependencies\n", scalar @deps;
for my $dep (@deps) {
    printf "    %s => %s\n", $dep->{module}, $dep->{file};
}

print "\nBuilding for $platform...\n";
$packer->build(sub {
    my ($result) = @_;
    if ($result->{success}) {
        printf "Done! Bundle at: %s (%d bytes)\n",
            $result->{path}, $result->{size};
    } else {
        die "Pack failed!\n";
    }
});
