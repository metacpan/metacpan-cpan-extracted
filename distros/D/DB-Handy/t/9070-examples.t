######################################################################
# 9070-examples.t  eg/ example script quality checks.
#
# Checks:
#   E1  No shebang line
#   E2  CVE-2016-1238 mitigation (pop @INC)
#   E3  FindBin present
#   E4  Boilerplate order: strict -> warnings stub -> pop @INC -> FindBin
#   E5  Header comment filename matches actual filename
#   E6  Demonstrates comment lists only methods actually used in code
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
my @eg_files  = sort grep { m{^eg/.*\.pl$} && -f "$ROOT/$_" } @manifest;

plan_skip('no eg/*.pl files found') unless @eg_files;
plan_tests(scalar(@eg_files) * 6);

for my $eg (@eg_files) {
    my $path  = "$ROOT/$eg";
    my @lines = _slurp_lines($path);
    my $text  = join('', @lines);
    my $base  = $eg; $base =~ s{.*/}{};

    # E1: no shebang
    ok(!(@lines && $lines[0] =~ /^#!/),
       "E1 - eg/ no shebang: $eg");

    # E2: CVE-2016-1238 mitigation
    ok($text =~ /pop\s+\@INC/,
       "E2 - eg/ CVE-2016-1238 pop \@INC: $eg");

    # E3: FindBin present
    ok($text =~ /use\s+FindBin/,
       "E3 - eg/ FindBin present: $eg");

    # E4: boilerplate order
    my %bpos;
    for my $pair (
        [ 'strict',  qr/^use strict;/m                        ],
        [ 'wstub',   qr/\$INC\{.warnings\.pm.\}/              ],
        [ 'popinc',  qr/pop\s+\@INC/                          ],
        [ 'findbin', qr/use\s+FindBin/                        ],
    ) {
        my ($name, $re) = @$pair;
        if ($text =~ $re) { $bpos{$name} = length($`) }
        else              { $bpos{$name} = 999999 }
    }
    my $e4 = $bpos{strict}  < $bpos{wstub}
          && $bpos{wstub}   < $bpos{popinc}
          && $bpos{popinc}  < $bpos{findbin};
    ok($e4, "E4 - eg/ boilerplate order (strict..warnings..pop\@INC..FindBin): $eg");

    # E5: header comment filename matches
    my $comment_name = '';
    for my $line (@lines) {
        if ($line =~ /^#\s+(\S+\.pl)\s+-/) { $comment_name = $1; last }
    }
    ok($comment_name eq '' || $comment_name eq $base,
       "E5 - eg/ header comment filename matches: $eg"
       . ($comment_name && $comment_name ne $base
          ? " (comment='$comment_name' actual='$base')" : ''));

    # E6: Demonstrates comment lists only methods used in code
    my %demo_methods;
    for my $line (@lines) {
        if ($line =~ /^#\s+-\s+(.+)/) {
            my $desc = $1;
            for my $part (split /[\s:,\/]+/, $desc) {
                $demo_methods{$part}++ if $part =~ /^[A-Z][A-Za-z]+$/
                                      && $part ne 'FindBin'
                                      && length($part) > 2;
            }
        }
    }
    my %used_methods;
    for my $line (@lines) {
        next if $line =~ /^\s*#/;
        while ($line =~ /->([A-Z][A-Za-z]+)\(/g)   { $used_methods{$1}++ }
        while ($line =~ /\b(\w+)::(\w+)->([A-Z][A-Za-z]+)/g) { $used_methods{$3}++ }
    }
    # Base methods always exempt from Demonstrates requirement
    my %base_exempt = map { $_ => 1 }
        qw(From Select ToArray ToList FromLTSV new connect disconnect do prepare);
    my @phantom_demo = grep { !$used_methods{$_} && !$base_exempt{$_} }
                       sort keys %demo_methods;
    ok(!@phantom_demo,
       "E6 - eg/ Demonstrates only lists used methods: $eg"
       . (@phantom_demo ? " (not used: @phantom_demo)" : ''));
}

END { end_testing() }
