use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;

# Skip tests on platforms without bash or with old bash
BEGIN {
    my $bash_check = `bash --version 2>&1`;
    if ($? != 0) {
        plan skip_all => 'bash is not available on this system';
    }
    if ($bash_check =~ /version (\d+)\.(\d+)/) {
        my ($major, $minor) = ($1, $2);
        if ($major < 4 || ($major == 4 && $minor < 3)) {
            plan skip_all => "bash 4.3+ required (found $major.$minor)";
        }
    }
}

# Skip if getoptlong.sh is not available
BEGIN {
    my $check = `command -v getoptlong.sh 2>/dev/null`;
    if ($? != 0) {
        plan skip_all => 'getoptlong.sh is not available in PATH';
    }
}

my $mdee = File::Spec->rel2abs('script/mdee');
my $test_md = File::Spec->rel2abs('t/test.md');

# Check if mdee exists
ok(-x $mdee, 'mdee is executable');

# Test: help option
subtest 'help option' => sub {
    my $out = `$mdee --help 2>&1`;
    like($out, qr/mdee.*Markdown/i, '--help shows description');
    like($out, qr/--mode/, '--help shows --mode option');
    like($out, qr/--theme/, '--help shows --theme option');
    like($out, qr/--filter/, '--help shows --filter option');
    like($out, qr/\[no-\]fold/, '--help shows --fold option');
    like($out, qr/\[no-\]table/, '--help shows --table option');
    like($out, qr/\[no-\]nup/, '--help shows --nup option');
};

# Test: version option
subtest 'version option' => sub {
    my $out = `$mdee --version 2>&1`;
    like($out, qr/^\d+\.\d+/, '--version shows version number');
};

# Test: dryrun option
subtest 'dryrun option' => sub {
    my $out = `$mdee --dryrun $test_md 2>&1`;
    like($out, qr/greple/, '--dryrun shows greple command');
    like($out, qr/nup/, '--dryrun shows nup command');
};

# Test: mode option
subtest 'mode option' => sub {
    my $out_light = `$mdee --dryrun --mode=light $test_md 2>&1`;
    my $out_dark = `$mdee --dryrun --mode=dark $test_md 2>&1`;
    isnt($out_light, $out_dark, 'light and dark modes produce different output');
};

# Test: no-nup option
subtest 'no-nup option' => sub {
    my $out = `$mdee --dryrun --no-nup $test_md 2>&1`;
    unlike($out, qr/\|\s*nup/, '--no-nup excludes nup from pipeline');
};

# Test: no-fold option
subtest 'no-fold option' => sub {
    my $out = `$mdee --dryrun --no-fold $test_md 2>&1`;
    unlike($out, qr/ansifold/, '--no-fold excludes ansifold from pipeline');
};

# Test: no-table option
subtest 'no-table option' => sub {
    my $out = `$mdee --dryrun --no-table $test_md 2>&1`;
    unlike($out, qr/ansicolumn/, '--no-table excludes ansicolumn from pipeline');
};

# Test: filter option
subtest 'filter option' => sub {
    my $out = `$mdee --dryrun -f $test_md 2>&1`;
    unlike($out, qr/ansifold/, '-f disables fold');
    unlike($out, qr/ansicolumn/, '-f disables table');
    unlike($out, qr/\|\s*nup/, '-f disables nup');
};

# Test: list-themes option
subtest 'list-themes option' => sub {
    my $out = `$mdee --list-themes 2>&1`;
    like($out, qr/Built-in themes/i, '--list-themes shows themes');
    like($out, qr/default/, '--list-themes shows default theme');
};

# Test: width option
subtest 'width option' => sub {
    my $out = `$mdee --dryrun --width=60 $test_md 2>&1`;
    like($out, qr/-sw60/, '--width=60 sets fold width');
};

# Test: tee module with fold (actual execution)
subtest 'tee fold execution' => sub {
    # Use a narrow width to force folding of long lines
    # Line 77 in test.md has a long description that should wrap
    my $out = `$mdee --no-nup --no-table --fold --width=40 $test_md 2>&1`;
    is($?, 0, 'mdee with fold exits successfully');
    # The long line should be wrapped, resulting in more lines than original
    my @lines = split /\n/, $out;
    ok(@lines > 10, 'fold produces wrapped output');
    # Check that ANSI sequences are present (greple highlighting worked)
    like($out, qr/\e\[/, 'output contains ANSI escape sequences');
};

# Test: tee module with table (actual execution)
subtest 'tee table execution' => sub {
    # Run with table formatting enabled
    my $out = `$mdee --no-nup --no-fold --table $test_md 2>&1`;
    is($?, 0, 'mdee with table exits successfully');
    # Table should be formatted with aligned columns
    # The separator line |---|---|---| should have consistent dashes
    like($out, qr/\|-+\|-+\|-+\|/, 'table separator is formatted');
    # Check that ANSI sequences are present
    like($out, qr/\e\[/, 'output contains ANSI escape sequences');
};

# Test: tee module combined (fold + table)
subtest 'tee combined execution' => sub {
    my $out = `$mdee --no-nup --fold --table --width=60 $test_md 2>&1`;
    is($?, 0, 'mdee with fold+table exits successfully');
    like($out, qr/\e\[/, 'output contains ANSI escape sequences');
    # Both table formatting and text should be present
    like($out, qr/greple.*Pattern matching/s, 'table content is present');
};

# Test: show option
subtest 'show option' => sub {
    # Count -E options in first greple command (before first pipe)
    sub count_patterns {
        my $out = shift;
        my ($first_cmd) = $out =~ /^(.*?)\s+\|/s;
        return () = ($first_cmd // '') =~ /-E/g;
    }

    # all fields enabled by default (16 patterns)
    my $default = `$mdee --dryrun $test_md 2>&1`;
    is(count_patterns($default), 16, 'default has 16 patterns');

    # --show italic=0 disables italic (14 patterns: 16 - 2 italic patterns)
    my $no_italic = `$mdee --dryrun --show italic=0 $test_md 2>&1`;
    is(count_patterns($no_italic), 14, '--show italic=0 removes 2 patterns');

    # --show bold=0 disables bold (14 patterns: 16 - 2 bold patterns)
    my $no_bold = `$mdee --dryrun --show bold=0 $test_md 2>&1`;
    is(count_patterns($no_bold), 14, '--show bold=0 removes 2 patterns');

    # --show all enables all fields (16 patterns)
    my $all = `$mdee --dryrun --show all $test_md 2>&1`;
    is(count_patterns($all), 16, '--show all has 16 patterns');

    # --show all= --show bold enables only bold (2 patterns)
    my $only_bold = `$mdee --dryrun '--show=all=' --show=bold $test_md 2>&1`;
    is(count_patterns($only_bold), 2, '--show all= --show bold has 2 patterns');

    # unknown field should error
    my $unknown = `$mdee --dryrun --show unknown $test_md 2>&1`;
    like($unknown, qr/unknown field/, '--show unknown produces error');
};

done_testing;
