use strict;
use warnings;

use Test2::V0;
use File::Find qw/find/;

# Every tempdir/tempfile template here must contain $$. File::Temp draws names
# from rand(), and Test2 seeds srand from the date, so every test process walks
# the identical name sequence and recycles freed names. Two of them copying into
# one dir corrupts a database; two test files sharing a name means one deletes
# the other's directory mid-run, which failed a release.
#
# A static scan, so it needs no database server and catches a new call site when
# it is added rather than when some CI job loses the race.

# By contents, not by name: a bare -d 'lib' also matches t/lib from cwd t/.
my ($libdir) = grep { -f "$_/DBIx/QuickDB.pm" } qw{lib ../lib};
my ($tdir)   = grep { -f "$_/tempdir_pid.t" } qw{t .};

plan skip_all => "Cannot locate the distribution's lib/ directory to scan"
    unless $libdir;

plan skip_all => "Cannot locate the distribution's t/ directory to scan"
    unless $tdir;

my %expected = ($libdir => 4, $tdir => 44);

my @files;
for my $dir ($libdir, $tdir) {
    my @found;
    find(
        {
            no_chdir => 1,
            wanted   => sub { push @found => $File::Find::name if -f $_ && m/\.(pm|t)$/ },
        },
        $dir,
    );

    push @files => map { [$dir, $_] } sort @found;
}

plan skip_all => "No files found to scan" unless @files;

my %found_any;

for my $pair (@files) {
    my ($dir, $file) = @$pair;
    my $content = do {
        open(my $fh, '<', $file) or die "Could not open '$file': $!";
        local $/;
        <$fh>;
    };

    # Blank out POD so a documentation example is not read as a call
    # site. Newlines are preserved to keep line numbers accurate.
    $content =~ s{^(=\w+.*?)(^=cut[^\n]*$|\z)}{"\n" x (($1 . $2) =~ tr/\n//)}gmse;

    while ($content =~ m/\b(tempdir|tempfile)\s*\(/g) {
        my $fn     = $1;
        my $pos    = pos($content);
        my $before = substr($content, 0, $pos);
        my $no     = 1 + ($before =~ tr/\n//);
        my $rest   = substr($content, $pos);

        # Skip mentions inside a comment: this distribution's prose does
        # name these calls, and an unverifiable site fails hard below.
        my $line_start = rindex($before, "\n") + 1;
        next if substr($before, $line_start) =~ m/#/;

        # First argument. Matched from the open paren so a call split
        # across lines is still checked.
        my (undef, $template) = $rest =~ m/\A\s*(["'])(.*?)\1/;

        # Fail rather than skip: a variable template, or a bare tempdir()
        # taking File::Temp's pid-free default, is what this test hunts.
        unless (defined $template) {
            fail("$file line $no: $fn() has no literal template, so the pid cannot be verified statically");
            diag("Give it a literal template containing \$\$, or check this site by hand and teach this test about it.");
            next;
        }

        # A template with no X placeholders is not a generated name at all.
        next unless $template =~ m/X/;

        $found_any{$dir}++;

        like(
            $template,
            qr/\$\$/,
            "$file line $no: template '$template' includes the pid",
        );
    }
}

# Exact counts, so a whole file cannot drop out of coverage unnoticed.
for my $dir ($libdir, $tdir) {
    is($found_any{$dir}, $expected{$dir}, "Scan reached every known tempdir/tempfile template in $dir/")
        or diag("Expected $expected{$dir} checked templates under '$dir'. If a call site was legitimately added or removed, update this count; if not, the scan has gone blind.");
}

done_testing;
