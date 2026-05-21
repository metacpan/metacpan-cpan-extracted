######################################################################
# 9080-cheatsheets.t  doc/ cheat sheet quality checks.
#
# Checks:
#   S1  Native script present for expected languages
#   S2  Section numbers are consecutive [1..N]
#   S3  Header line format: product name + [XX] lang-name
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
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

# Languages expected to use non-Latin native scripts
my %native_script = map { $_ => 1 }
    qw(JA ZH TW KO TH HI BN MY KM MN NE SI UR FR TR VI);

for my $doc (@doc_files) {
    my $path = "$ROOT/$doc";
    my $lang = '';
    $lang = $1 if $doc =~ /\.([A-Z]{2})\.txt$/;

    # S1: native script
    if ($lang && $native_script{$lang}) {
        local *FHS1;
        open FHS1, "< $path" or do {
            ok(0, "S1 - native script present: $doc (cannot open)");
            ok(1, "S2 - section numbers: $doc (skipped)");
            ok(1, "S3 - header format: $doc (skipped)");
            next;
        };
        my $found = 0;
        while (<FHS1>) {
            if (/[^\x00-\x7F]/) { $found = 1; last }
        }
        close FHS1;
        ok($found, "S1 - native script present: $doc");
    }
    else {
        ok(1, "S1 - native script not required: $doc");
    }

    # S2: section numbers consecutive
    local *FHS2;
    open FHS2, "< $path" or do {
        ok(0, "S2 - section numbers: $doc (cannot open)");
        ok(1, "S3 - header format: $doc (skipped)");
        next;
    };
    my @secs;
    while (<FHS2>) {
        if (/^\[\s*(\d+)\./) { push @secs, $1 + 0 }
    }
    close FHS2;
    my $s2 = 1;
    if (@secs) {
        for my $i (0 .. $#secs) {
            if ($secs[$i] != $i + 1) { $s2 = 0; last }
        }
    }
    ok($s2, "S2 - section numbers consecutive: $doc"
        . (!$s2 ? " (got: @secs)" : ''));

    # S3: header format
    local *FHS3;
    open FHS3, "< $path" or do {
        ok(0, "S3 - header format: $doc (cannot open)");
        next;
    };
    my $header = '';
    while (<FHS3>) {
        if (/CSV::LINQ/) { $header = $_; last }
    }
    close FHS3;
    my $s3 = ($header =~ /CSV::LINQ/ && $header =~ /\[([A-Z]{2})\]/);
    ok($s3, "S3 - header contains product name and [XX] lang code: $doc");
}

END { end_testing() }
