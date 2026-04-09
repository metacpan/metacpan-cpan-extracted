#!/usr/bin/env perl
#
# pack.pl - Build a bundled app for Chandra::Game::Tetris
#
use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../lib";

use Chandra::Pack;

my $platform = 'macos';
for (@ARGV) {
    $platform = $1 if /^--platform=(\w+)$/;
}

my $packer = Chandra::Pack->new(
    script     => "$FindBin::Bin/app.pl",
    name       => 'ChandraTetris',
    version    => '0.01',
    identifier => 'org.perl.chandra.tetris',
    icon       => "$FindBin::Bin/icon.png",
    output     => "$FindBin::Bin/dist",
    platform   => $platform,
    include    => ['Chandra::Game::Tetris'],
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
