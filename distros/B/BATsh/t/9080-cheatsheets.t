######################################################################
#
# 9080-cheatsheets.t  doc/ cheat sheet quality checks
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

my @manifest  = _manifest_files($ROOT);
my @doc_files = sort grep { m{^doc/.*\.txt$} && -f "$ROOT/$_" } @manifest;

plan_skip('no doc/*.txt files found') unless @doc_files;
plan_tests(scalar(@doc_files) * 3);

my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN KM MN RU AR);

for my $doc (@doc_files) {
    my $path = "$ROOT/$doc";
    my $lang = '';
    $lang = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;

    if ($lang && $native_script{$lang}) {
        local *FHS1;
        open(FHS1, "< $path") or do {
            ok(0, "S1: $doc cannot open"); ok(1, "S1: skip"); ok(1, "S1: skip"); next;
        };
        my $has_native = 0;
        while (<FHS1>) { if (/[^\x00-\x7F]/) { $has_native = 1; last } }
        close(FHS1);
        ok($has_native, "S1: $doc has non-ASCII (native script)");
    }
    else {
        ok(1, "S1: $doc (Latin script -- skipped native check)");
    }

    local *FHS2;
    open(FHS2, "< $path") or do { ok(0,"S2: $doc open fail"); ok(0,"S3: $doc open fail"); next };
    my @nums;
    while (<FHS2>) { if (/^\s*(\d+)\.\s/) { push @nums, $1 } }
    close(FHS2);
    my $consecutive = 1;
    for my $i (1 .. $#nums) {
        if ($nums[$i] != $nums[$i-1]+1 && $nums[$i] != $nums[$i-1]) {
            $consecutive = 0; last;
        }
    }
    ok($consecutive || @nums == 0, "S2: $doc section numbers consecutive");

    local *FHS3;
    open(FHS3, "< $path") or do { ok(0,"S3: $doc open fail"); next };
    my $first = <FHS3>;
    close(FHS3);
    $first = '' unless defined $first;
    ok($first =~ /BATsh/, "S3: $doc header contains BATsh");
}

END { end_testing() }
