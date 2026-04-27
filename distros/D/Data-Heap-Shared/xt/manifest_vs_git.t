use strict;
use warnings;
use Test::More;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires git' unless `which git 2>/dev/null` =~ /\S/;

# MANIFEST must list every tracked file that's not gitignored or in MANIFEST.SKIP.
use Cwd qw(abs_path);
use File::Basename qw(dirname);
my $root = dirname(dirname(abs_path(__FILE__)));
chdir $root or die "chdir $root: $!";

# Collect: git-tracked files not covered by MANIFEST.SKIP
my %git = map { chomp; $_ => 1 } qx(git ls-files);
delete $git{'.gitignore'};
delete $git{$_} for grep /^\.github\//, keys %git;   # CI files optional
delete $git{$_} for grep /^MANIFEST(\.SKIP)?$/, keys %git;  # MANIFEST self-excluded
delete $git{$_} for grep m{^\.claude/}, keys %git;

# Honor MANIFEST.SKIP patterns
if (-e 'MANIFEST.SKIP') {
    open my $sf, '<', 'MANIFEST.SKIP' or die;
    my @skip_re;
    while (my $l = <$sf>) {
        chomp $l;
        next if $l =~ /^\s*(#|$)/;
        push @skip_re, qr/$l/;
    }
    close $sf;
    for my $f (keys %git) {
        for my $re (@skip_re) {
            if ($f =~ $re) { delete $git{$f}; last }
        }
    }
}

open my $fh, '<', 'MANIFEST' or die "no MANIFEST";
my %mani;
while (my $line = <$fh>) {
    next if $line =~ /^\s*#/;
    $mani{$1} = 1 if $line =~ /^(\S+)/;
}
close $fh;

# Check every git file is in MANIFEST
my @missing = sort grep { !exists $mani{$_} } keys %git;
ok !@missing, 'all git-tracked files listed in MANIFEST'
    or diag "missing from MANIFEST: @missing";

# Check every MANIFEST file exists
my @missing_on_disk = sort grep { !-e $_ } keys %mani;
ok !@missing_on_disk, 'all MANIFEST files exist on disk'
    or diag "listed in MANIFEST but not on disk: @missing_on_disk";

done_testing;
