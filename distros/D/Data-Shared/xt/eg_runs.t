use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $root = "$FindBin::Bin/..";
my @eg = sort glob "$root/eg/*.pl";
ok @eg >= 8, 'examples populated';

for my $eg (@eg) {
    # Warnings go to stderr, so the child's stderr is folded into what the clean check reads.
    my ($errfh, $errfile) = tempfile(UNLINK => 1);
    my $out = do {
        open my $saved, '>&', \*STDERR or die $!;
        open STDERR, '>&', $errfh or die $!;
        open my $fh, '-|', $^X, "-I$root/lib", $eg or die $!;
        my $o = do { local $/; <$fh> };
        close $fh;
        open STDERR, '>&', $saved or die $!;
        $o;
    };
    my $status = $?;
    $out .= do { open my $e, '<', $errfile or die $!; local $/; <$e> };
    my ($name) = $eg =~ m{([^/]+)$};
    # An unguarded example dies on the backend-absent croak, which is a skip, not a break.
    if ($out =~ /is not available; install the/) {
        fail "$name: DS_ALL_BACKENDS is set, yet a backend is missing" if $ENV{DS_ALL_BACKENDS};
        if ($status != 0) { note "$name: skipped, backend not installed"; next }
    }
    is $status, 0, "$name exits 0";
    unlike $out, qr/isn't numeric|Use of uninitialized|Undefined subroutine/, "$name clean output";
}
done_testing;
