#!/usr/bin/env perl

use 5.014;
use warnings;

use FindBin;
use File::Basename qw(basename);
use Getopt::Long;

my $lib_dir = "$FindBin::RealBin/../lib";
my $examples_dir = "$FindBin::RealBin/../examples";

my $save_to_dir;
GetOptions ("save-to-dir=s" => \$save_to_dir );
$save_to_dir //= $examples_dir;

my @scripts = glob("$examples_dir/*.pl");

for my $script (@scripts) {
    my @cmd = ($^X, "-I$lib_dir", $script);
    if (defined $save_to_dir) {
        my $ofile = basename($script) =~ s/\.pl$/.png/r;
        push @cmd, "-o", "$save_to_dir/$ofile";
    }

    say join(' ', @cmd);
    my $rslt = system(@cmd);
    die if ($rslt);
}
