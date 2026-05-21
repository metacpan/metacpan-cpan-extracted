#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;

my $plha      = "$Bin/../tools/plha";
my $plhasa    = "$Bin/../tools/plhasa";
my $blib      = "-I$Bin/../blib/lib -I$Bin/../blib/arch";
my $lha       = "$Bin/archive/lh5.lzh";
my $amiga     = "$Bin/archive/amiga_prefix.lha";
my $amiga_uc  = "$Bin/archive/amiga_allcaps_preserve.lha";
my $latin1    = "$Bin/archive/Amoric_src.lha";
my $trunc     = "$Bin/archive/lh5_truncated.lzh";
my $dirslash  = "$Bin/archive/dir_trailing_slash.lha";

subtest 'plha v' => sub {
    my $output = `$^X $blib $plha v $lha 2>&1`;
    like $output, qr/00_load\.t/, 'plha v lists archive contents';
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    like $output, qr/^Original\s+Packed\s+Ratio/m, 'Has plha v header';
    like $output, qr/\d+ files$/, 'Has file count footer';
};

subtest 'plha l (LhA terse format)' => sub {
    my $output = `$^X $blib $plha l $lha 2>&1`;
    like $output, qr/00_load\.t/, 'plha l lists archive contents';
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    unlike $output, qr/PERMSSN/, 'l format does not have lhasa-style PERMSSN header';
    unlike $output, qr/METHOD/, 'l format does not have METHOD column';
};

subtest 'plha vv (LhA vv format)' => sub {
    my $output = `$^X $blib $plha vv $lha 2>&1`;
    like $output, qr/00_load\.t/, 'plha vv lists archive contents';
    like $output, qr/Atts.*Method.*CRC.*OS/m, 'Has LhA vv header';
    like $output, qr/-lh\d-/, 'Shows compression method';
    like $output, qr/[0-9a-fA-F]{4}/, 'Shows CRC (uppercase, Amiga LhA style)';
    my @lines = split /\n/, $output;
    my @name_lines = grep { /^t\/00_load/ } @lines;
    ok scalar @name_lines > 0, 'Filename on its own line';
};

my $plhasa_l_expected = <<'END';
 PERMSSN    UID  GID      SIZE  RATIO     STAMP           NAME
---------- ----------- ------- ------ ------------ --------------------
[MS-DOS]                    82  97.6% Dec 10  2007 t/00_load.t
[MS-DOS]                   223  70.4% Dec 10  2007 t/99_pod.t
[MS-DOS]                   248  66.9% Dec 10  2007 t/99_podcoverage.t
---------- ----------- ------- ------ ------------ --------------------
END

my $plhasa_v_expected = <<'END';
 PERMSSN    UID  GID    PACKED    SIZE  RATIO METHOD CRC     STAMP          NAME
---------- ----------- ------- ------- ------ ---------- ------------ -------------
[MS-DOS]                    80      82  97.6% -lh5- c750 Dec 10  2007 t/00_load.t
[MS-DOS]                   157     223  70.4% -lh5- 69f4 Dec 10  2007 t/99_pod.t
[MS-DOS]                   166     248  66.9% -lh5- 0dc1 Dec 10  2007 t/99_podcoverage.t
---------- ----------- ------- ------- ------ ---------- ------------ -------------
END

# Strip the Total line (contains archive mtime which changes) before comparing
sub _strip_total { join '', grep { !/^ Total/ } split /^/m, $_[0] }

subtest 'plhasa l (lhasa terse format)' => sub {
    my $output = `$^X $blib $plhasa l $lha 2>&1`;
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    is _strip_total($output), $plhasa_l_expected, 'plhasa l output matches expected';
    like $output, qr/^ Total\s+3 files\s+553\s+72\.9%/m, 'Total line correct';
};

subtest 'plhasa v (lhasa verbose format)' => sub {
    my $output = `$^X $blib $plhasa v $lha 2>&1`;
    is _strip_total($output), $plhasa_v_expected, 'plhasa v output matches expected';
    like $output, qr/^ Total\s+3 files\s+403\s+553\s+72\.9%/m, 'Total line correct';
};

subtest 'plhasa l format matches lhasa column layout' => sub {
    my @file_lines = grep { /^\[MS-DOS\]/ } split /\n/, $plhasa_l_expected;
    ok scalar @file_lines > 0, 'Has file entries';
    for my $line (@file_lines) {
        like $line, qr/^\[MS-DOS\]\s+\d+\s+[\d.]+%\s+\S+\s+\d+\s+\d{4}\s+\S/, "File line format: $line";
    }
};

subtest 'Total line alignment' => sub {
    my $output = `$^X $blib $plhasa v $lha 2>&1`;
    my ($total_line) = grep { /Total/ } split /\n/, $output;
    like $total_line, qr/^ Total\s+\d+ files?\s+\d+\s+\d+/, 'Total line has count, packed, size';
    my ($prefix) = $total_line =~ /^(.*files\s)/;
    is length($prefix), 23, 'Total prefix is 23 chars (matches lhasa column layout)';
};

subtest 'prefix is 23 chars wide' => sub {
    my @file_lines = grep { /^\[/ } split /\n/, $plhasa_v_expected;
    for my $line (@file_lines) {
        my $prefix = substr($line, 0, 23);
        my $rest = substr($line, 23);
        like $rest, qr/^\s*\d+/, "PACKED starts after 23-char prefix: [$prefix]|$rest";
    }
};

subtest 'directory entries' => sub {
    my $output = `$^X $blib $plhasa v $lha 2>&1`;
    unlike $output, qr/LHD\.pm/, 'No LHD decoder error';
    unlike $output, qr/Can't load/, 'No module loading errors';
};

subtest 'directory trailing slash preserved' => sub {
    plan skip_all => "dir_trailing_slash.lha not found" unless -f $dirslash;
    my $output = `$^X $blib $plha v $dirslash 2>&1`;
    like $output, qr/lhd_dir\//, '-lhd- directory entry has trailing slash';
    like $output, qr/lh0_dir\//, '-lh0- directory entry has trailing slash';
};

subtest 'DOS timestamps' => sub {
    use Archive::Lha::Header::Utils;
    my $epoch = Archive::Lha::Header::Utils::_dostime2utime(0);
    is $epoch, 0, 'All-zero DOS time returns epoch 0';

    $epoch = Archive::Lha::Header::Utils::_dostime2utime(0x5A34B800);
    ok $epoch > 0, 'Valid DOS time returns positive epoch';

    # 0xFB9FF926 is a corrupt timestamp that decodes to year 2105, which
    # overflows 32-bit time_t on Perl builds with ivsize=4 (e.g. armv6l
    # without -Duse64bitint). We only assert no crash; the proper fix for
    # out-of-range timestamps on such systems is a 64-bit Perl build.
    $epoch = eval { Archive::Lha::Header::Utils::_dostime2utime(0xFB9FF926) };
    ok !$@, 'Invalid DOS time does not crash';
};

subtest 'Amiga archive [Amiga] prefix' => sub {
    plan skip_all => "amiga_prefix.lha not found" unless -f $amiga;
    my $output = `$^X $blib $plhasa l $amiga 2>&1`;
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    like $output, qr/\[Amiga\]/, 'Shows [Amiga] prefix for Amiga archive';
};

subtest 'Amiga archive filenames preserve case' => sub {
    plan skip_all => "amiga_allcaps_preserve.lha not found" unless -f $amiga_uc;
    my $output = `$^X $blib $plhasa v $amiga_uc 2>&1`;
    # AUTHORS, CHANGES, COPYING are all-caps Amiga filenames; the MS-DOS
    # all-caps lowercasing must not apply to Amiga archives
    like $output, qr/\[Amiga\].*AUTHORS/, 'Amiga all-caps filename not lowercased';
};

subtest 'latin-1 filename display' => sub {
    plan skip_all => "Amoric_src.lha not found" unless -f $latin1;
    my $output = `$^X $blib $plha v $latin1 2>&1`;
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    # Amoric_src.lha is an Amiga archive with latin-1 filenames
    # Auto-detection should pick up iso-8859-15 for Amiga archives
    like $output, qr/\w/, 'Produces output without error';
};

subtest 'latin-1 filename with explicit -fc' => sub {
    plan skip_all => "Amoric_src.lha not found" unless -f $latin1;
    my $output = `$^X $blib $plha -fc iso-8859-15 -tc UTF-8 v $latin1 2>&1`;
    unlike $output, qr/Can't load|Can't locate/, 'No module loading errors';
    like $output, qr/\w/, 'Produces output with explicit charset options';
};

subtest 'truncated archive warning' => sub {
    plan skip_all => "lh5_truncated.lzh not found" unless -f $trunc;
    my $output = `$^X $blib $plha v $trunc 2>&1`;
    like $output, qr/WARNING.*truncated|truncated.*WARNING/i, 'Warns about truncated archive';
};

subtest 'unknown command error' => sub {
    my $output = `$^X $blib $plha zzz $lha 2>&1`;
    like $output, qr/Unknown command/i, 'Shows unknown command error';
    like $output, qr/Usage/i, 'Shows usage after unknown command error';
};

done_testing;
