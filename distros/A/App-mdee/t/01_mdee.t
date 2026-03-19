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

# Isolate tests from user's ~/.config/mdee/config.sh
use File::Temp qw(tempdir);
my $empty_config = tempdir(CLEANUP => 1);
$ENV{XDG_CONFIG_HOME} = $empty_config;

# Check if mdee exists
ok(-x $mdee, 'mdee is executable');

# Test: help option
subtest 'help option' => sub {
    my $out = `$mdee --help 2>&1`;
    like($out, qr/dee.*Markdown/i, '--help shows description');
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
    my $out = `COLUMNS=200 $mdee --dryrun $test_md 2>&1`;
    like($out, qr/greple/, '--dryrun shows greple command');
    like($out, qr/nup/, '--dryrun shows nup command');
};

# Test: mode option
subtest 'mode option' => sub {
    my $out_light = `$mdee --mode=light -s cat $test_md 2>&1`;
    my $out_dark = `$mdee --mode=dark -s cat $test_md 2>&1`;
    isnt($out_light, $out_dark, 'light and dark modes produce different output');
};

# Test: no-nup option
subtest 'no-nup option' => sub {
    my $out = `$mdee --dryrun --no-nup $test_md 2>&1`;
    unlike($out, qr/run_nup/, '--no-nup excludes nup from pipeline');
};

# Test: no-fold option
subtest 'no-fold option' => sub {
    my $out = `$mdee -ddn --no-fold $test_md 2>&1`;
    my ($greple_line) = $out =~ /^(debug: greple .*)$/m;
    unlike($greple_line // '', qr/foldlist=1\b/, '--no-fold excludes fold from greple');
};

# Test: no-table option
subtest 'no-table option' => sub {
    my $ddn = `$mdee -ddn --no-table $test_md 2>&1`;
    unlike($ddn, qr/table=1/, '--no-table excludes table=1 from config');
    like($ddn, qr/table=0/, '--no-table sends table=0 to config');

    # Verify actual behavior: table should NOT be formatted
    use Encode 'decode_utf8';
    my $out = decode_utf8(`$mdee --no-nup --no-fold --no-table $test_md 2>&1`);
    unlike($out, qr/\x{2502}/, '--no-table does not produce box-drawing chars');
};

# Test: filter option
subtest 'filter option' => sub {
    my $ddn = `$mdee -ddn -f $test_md 2>&1`;
    unlike($ddn, qr/foldlist=1\b/, '-f disables fold');
    unlike($ddn, qr/run_nup/, '-f disables nup');
    like($ddn, qr/table=1/, '-f keeps table enabled');
};

# Test: style option
subtest 'style option' => sub {
    my $nup = `COLUMNS=200 $mdee --dryrun --style=nup $test_md 2>&1`;
    like($nup, qr/run_nup/, '--style=nup includes nup');

    my $nup_ddn2 = `COLUMNS=200 $mdee -ddn --style=nup $test_md 2>&1`;
    like($nup_ddn2, qr/foldlist=1\b/, '--style=nup includes fold');

    my $nup_ddn = `COLUMNS=200 $mdee -ddn --style=nup $test_md 2>&1`;
    like($nup_ddn, qr/table=1/, '--style=nup includes table');

    my $pager = `$mdee --dryrun --style=pager $test_md 2>&1`;
    unlike($pager, qr/run_nup/, '--style=pager excludes nup');
    like($pager, qr/run_pager/, '--style=pager includes pager');

    my $pager_ddn2 = `$mdee -ddn --style=pager $test_md 2>&1`;
    like($pager_ddn2, qr/foldlist=1\b/, '--style=pager includes fold');

    my $pager_ddn = `$mdee -ddn --style=pager $test_md 2>&1`;
    like($pager_ddn, qr/table=1/, '--style=pager includes table');

    my $cat = `$mdee --dryrun --style=cat $test_md 2>&1`;
    unlike($cat, qr/run_nup/, '--style=cat excludes nup');

    my $cat_ddn = `$mdee -ddn --style=cat $test_md 2>&1`;
    like($cat_ddn, qr/foldlist=1\b/, '--style=cat includes fold');
    like($cat_ddn, qr/table=1/, '--style=cat includes table');

    my $filter_ddn = `$mdee -ddn --style=filter $test_md 2>&1`;
    unlike($filter_ddn, qr/foldlist=1\b/, '--style=filter excludes fold');
    unlike($filter_ddn, qr/run_nup/, '--style=filter excludes nup');
    like($filter_ddn, qr/table=1/, '--style=filter includes table');

    my $raw_ddn = `$mdee -ddn --style=raw $test_md 2>&1`;
    unlike($raw_ddn, qr/foldlist=1\b/, '--style=raw excludes fold');
    unlike($raw_ddn, qr/table=1/, '--style=raw excludes table');
    like($raw_ddn, qr/table=0/, '--style=raw sends table=0');
    unlike($raw_ddn, qr/run_nup/, '--style=raw excludes nup');

    my $bogus = `$mdee --dryrun --style=bogus $test_md 2>&1`;
    like($bogus, qr/unknown style/, '--style=bogus produces error');
};

# Test: plain option
subtest 'plain option' => sub {
    my $out = `$mdee --dryrun -p $test_md 2>&1`;
    unlike($out, qr/run_nup/, '-p excludes nup');
    like($out, qr/run_pager/, '-p includes pager');

    my $ddn = `$mdee -ddn -p $test_md 2>&1`;
    like($ddn, qr/foldlist=1\b/, '-p includes fold');
    like($ddn, qr/table=1/, '-p includes table');
};

# Test: style override
subtest 'style override' => sub {
    my $ddn = `$mdee -ddn -f --fold $test_md 2>&1`;
    like($ddn, qr/foldlist=1\b/, '-f --fold enables fold');
    unlike($ddn, qr/run_nup/, '-f --fold keeps nup disabled');

    my $out2 = `$mdee --dryrun -p --no-fold $test_md 2>&1`;
    like($out2, qr/run_pager/, '-p --no-fold keeps pager');
    my $ddn2 = `$mdee -ddn -p --no-fold $test_md 2>&1`;
    unlike($ddn2, qr/foldlist=1\b/, '-p --no-fold disables fold');
};

# Test: width option
subtest 'width option' => sub {
    # Use actual execution: narrow width should produce more lines than wide
    my $narrow = `$mdee -s cat --width=30 $test_md 2>&1`;
    my $wide   = `$mdee -s cat --width=200 $test_md 2>&1`;
    my @narrow_lines = split /\n/, $narrow;
    my @wide_lines   = split /\n/, $wide;
    ok(@narrow_lines > @wide_lines, '--width=30 produces more lines than --width=200');
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

# Test: list marker patterns in fold
subtest 'list marker patterns' => sub {
    use File::Temp qw(tempfile);
    my $long = "x" x 80;

    # Helper: count output lines from fold
    my $fold_lines = sub {
        my ($input) = @_;
        my ($fh, $tmp) = tempfile(SUFFIX => '.md', UNLINK => 1);
        print $fh $input;
        close $fh;
        my $out = `$mdee --no-nup --no-table --fold --width=40 --mode=light $tmp 2>&1`;
        return split /\n/, $out;
    };

    # 1. (traditional) should fold
    ok($fold_lines->("1. $long\n") > 1, '1. list item is folded');

    # 1) (CommonMark paren) should fold
    ok($fold_lines->("1) $long\n") > 1, '1) list item is folded');

    # #. (Pandoc auto-number) should fold
    ok($fold_lines->("    #. $long\n") > 1, '#. list item is folded');

    # #) should fold
    ok($fold_lines->("    #) $long\n") > 1, '#) list item is folded');
};

# Test: md module table formatting (actual execution)
subtest 'md module table execution' => sub {
    # Run with table formatting enabled
    my $out = `$mdee --no-nup --no-fold --table $test_md 2>&1`;
    is($?, 0, 'mdee with table exits successfully');
    # Table should be formatted with aligned columns
    # The separator line |---|---|---| should have consistent dashes
    use Encode 'decode_utf8';
    like(decode_utf8($out), qr/─+┼─+┼─+/, 'table separator is formatted with box-drawing');
    # Check that ANSI sequences are present
    like($out, qr/\e\[/, 'output contains ANSI escape sequences');

    # --no-rule: ASCII separators instead of box-drawing
    my $norule = decode_utf8(`$mdee --no-nup --no-fold --table --no-rule $test_md 2>&1`);
    is($?, 0, 'mdee with --no-rule exits successfully');
    like($norule, qr/[-]+\|[-]+/, '--no-rule produces ASCII separator');
    unlike($norule, qr/[├┼┤─│]/, '--no-rule does not produce box-drawing chars');
};

# Test: combined execution (fold + table)
subtest 'combined execution' => sub {
    my $out = `$mdee --no-nup --fold --table --width=60 $test_md 2>&1`;
    is($?, 0, 'mdee with fold+table exits successfully');
    like($out, qr/\e\[/, 'output contains ANSI escape sequences');
    # Both table formatting and text should be present
    like($out, qr/greple.*Pattern matching/s, 'table content is present');
};

# Test: show option (verify actual output behavior)
subtest 'show option' => sub {
    # Helper: check if text has ANSI color directly applied
    # Markers and content may be colored separately (emphasis_mark),
    # so match ANSI before either the marker or the content.
    sub has_ansi_around {
        my ($out, $text) = @_;
        return $out =~ /\e\[[0-9;]*m\Q$text\E/;
    }
    sub has_bold_coloring {
        my ($out) = @_;
        # Markers (**) are colored with emphasis_mark, content with bold
        return $out =~ /\e\[[0-9;]*m\*\*.*bold text.*\*\*/;
    }
    sub has_italic_coloring {
        my ($out) = @_;
        return $out =~ /\e\[[0-9;]*m_.*italic text.*_/;
    }

    # Default: bold should be colored (--no-theme to test with markers visible)
    my $default = `$mdee -f --no-theme $test_md 2>&1`;
    ok(has_bold_coloring($default), 'default has bold formatting');

    # --show bold=0: bold should NOT be colored
    my $no_bold = `$mdee -f --no-theme --show bold=0 $test_md 2>&1`;
    ok(!has_bold_coloring($no_bold), '--show bold=0 disables bold');

    # --show italic=0: italic should NOT be colored
    my $no_italic = `$mdee -f --no-theme --show italic=0 $test_md 2>&1`;
    ok(!has_italic_coloring($no_italic), '--show italic=0 disables italic');

    # --show all= disables all formatting
    my $all_off = `$mdee -f --no-theme '--show=all=' $test_md 2>&1`;
    ok(!has_bold_coloring($all_off), '--show all= disables bold');

    # --show all= --show bold: only bold colored
    my $only_bold = `$mdee -f --no-theme '--show=all=' --show=bold $test_md 2>&1`;
    ok(has_bold_coloring($only_bold), '--show all= --show bold enables bold');
    ok(!has_italic_coloring($only_bold), '--show all= --show bold disables italic');

    # unknown field should error
    my $unknown = `$mdee --dryrun --show unknown $test_md 2>&1`;
    like($unknown, qr/unknown field/, '--show unknown produces error');
};

# Test: config file defaults
subtest 'config file defaults' => sub {
    use File::Temp qw(tempdir);
    my $tmpdir = tempdir(CLEANUP => 1);
    my $config_dir = "$tmpdir/mdee";
    mkdir $config_dir;

    # Test default[style]
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[style]='pager'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee --dryrun --mode=light $test_md 2>&1`;
        like($out, qr/run_pager/, 'default[style]=pager adds pager');
        unlike($out, qr/run_nup/, 'default[style]=pager removes nup');
    }

    # Test default[width]
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[width]=40\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -ddn --mode=light $test_md 2>&1`;
        like($out, qr/foldwidth=40\b/, 'default[width]=40 sets fold width');
    }

    # Test default[base_color]
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[base_color]='Crimson'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -dd --dryrun --mode=light $test_md 2>&1`;
        like($out, qr/base_color=.*Crimson/, 'default[base_color]=Crimson is passed via config');
    }

    # Test command-line overrides config defaults
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[style]='pager'\ndefault[width]=40\n";
        close $fh;
        my $out = `COLUMNS=200 XDG_CONFIG_HOME=$tmpdir $mdee --dryrun --mode=light -s nup -w 120 $test_md 2>&1`;
        like($out, qr/run_nup/, '-s nup overrides default[style]=pager');
    }

    # Test custom theme defined in config.sh
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh <<'CONF';
theme_light[base]='<DarkCyan>=y25'
theme_dark[base]='<DarkCyan>=y80'
CONF
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light $test_md 2>&1`;
        like($out, qr/DarkCyan/, 'custom theme from config.sh is loaded');
    }

    # Test theme partial override in config.sh
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "theme_light[base]='<Crimson>=y25'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light $test_md 2>&1`;
        like($out, qr/Crimson/, 'theme partial override in config.sh works');
    }

    # Test default[theme] with single theme
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[theme]='warm'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light $test_md 2>&1`;
        is($?, 0, 'default[theme]=warm loads successfully');
        like($out, qr/Coral/, 'default[theme]=warm applies Coral base color');
    }

    # Test default[theme] with comma-separated themes
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[theme]='warm,hashed'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light $test_md 2>&1`;
        is($?, 0, 'default[theme]=warm,hashed loads successfully');
        like($out, qr/Coral/, 'default[theme]=warm,hashed applies warm');
        like($out, qr/hashed\.h3=1/, 'default[theme]=warm,hashed applies hashed');
    }

    # Test --theme skips default[theme] (flag set by callback)
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[theme]='warm'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --no-theme --theme=warm $test_md 2>&1`;
        like($out, qr/Coral/, '--no-theme --theme=warm applies warm');
        unlike($out, qr/###/, '--no-theme --theme=warm skips hashed');
    }

    # Test --base-color overrides config theme override
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "theme_light[base]='<Crimson>=y25'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -dd --dryrun --mode=light -B Ivory $test_md 2>&1`;
        like($out, qr/base_color=.*Ivory/, '--base-color overrides config theme override');
        unlike($out, qr/base_color=.*Crimson/, '--base-color takes priority over config');
    }
};

# Test: external theme file loading
subtest 'external theme file' => sub {
    use File::Temp qw(tempdir);
    my $tmpdir = tempdir(CLEANUP => 1);
    my $theme_dir = "$tmpdir/mdee/theme";
    system("mkdir -p $theme_dir") == 0 or die "mkdir failed";

    # Create a test theme file (modifies theme_light/theme_dark)
    open my $fh, '>', "$theme_dir/testtheme.sh" or die;
    print $fh <<'THEME';
theme_light[base]='<Crimson>=y25'
theme_dark[base]='<Crimson>=y80'
THEME
    close $fh;

    # Test loading external theme
    my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --theme=testtheme $test_md 2>&1`;
    is($?, 0, 'external theme loads successfully');
    like($out, qr/Crimson/, 'external theme base color is applied');

    # Test dark mode with external theme (inherits from light)
    my $dark = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=dark --theme=testtheme $test_md 2>&1`;
    is($?, 0, 'external dark theme loads successfully');
    like($dark, qr/Crimson/, 'external dark theme has base color');

    # Test --theme=FILE (file path direct loading)
    my $out_file = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --theme=$theme_dir/testtheme.sh $test_md 2>&1`;
    is($?, 0, '--theme=FILE loads successfully');
    like($out_file, qr/Crimson/, '--theme=FILE applies theme colors');

    # Test nonexistent theme produces error
    my $err = `XDG_CONFIG_HOME=$tmpdir $mdee --dryrun --mode=light --theme=nonexistent $test_md 2>&1`;
    isnt($?, 0, 'nonexistent theme fails');
    like($err, qr/theme not found/, 'nonexistent theme produces error');
};

# Test: share directory theme loading (warm theme)
subtest 'share theme warm' => sub {
    my $share = File::Spec->rel2abs('share/theme/warm.sh');
    plan skip_all => 'share/theme/warm.sh not found' unless -f $share;
    my $out = `$mdee -d --dryrun --mode=light --theme=warm $test_md 2>&1`;
    is($?, 0, 'warm theme loads successfully');
    like($out, qr/Coral/, 'warm theme uses Coral base color');
};

done_testing;
