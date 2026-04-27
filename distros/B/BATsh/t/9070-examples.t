######################################################################
#
# 9070-examples.t  eg/ example script checks
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
my @eg_files  = sort grep { m{^eg/.*\.batsh$} && -f "$ROOT/$_" } @manifest;

plan_skip('no eg/*.batsh files found') unless @eg_files;
plan_tests(scalar(@eg_files) * 3);

for my $rel (@eg_files) {
    my $path  = "$ROOT/$rel";
    my @lines = _slurp_lines($path);

    ok(-f $path, "E1: $rel exists");

    my $bad = 0;
    for my $line (@lines) {
        if ($line =~ /[^\x0A\x0D\x20-\x7E]/) { $bad++; last }
    }
    ok($bad == 0, "E2: $rel US-ASCII only");

    my $last = @lines ? $lines[-1] : '';
    ok($last =~ /\n\z/, "E3: $rel ends with newline");
}

END { end_testing() }
