use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use Encode qw(decode_utf8);
use Text::ANSI::Fold::Util qw(ansi_width);

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
# Do not ask the terminal for its background color: the reply of a
# busy terminal can come after termcolor gave up and shows up as input.
$ENV{TERM_LUMINANCE} = 100;

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
    like($out, qr/^greple '-Mmd::config\(mode=/m, '--dryrun shows the greple command line');
    like($out, qr/ \\\n    \| nup /, '--dryrun joins the stages with |');
    unlike($out, qr/run_greple/, '--dryrun shows commands, not function names');
};

# Test: mode option
subtest 'mode option' => sub {
    my $out_light = `$mdee --mode=light -s cat $test_md 2>&1`;
    my $out_dark = `$mdee --mode=dark -s cat $test_md 2>&1`;
    isnt($out_light, $out_dark, 'light and dark modes produce different output');
    # TERM_LUMINANCE decides the mode without asking the terminal
    my $dark = `TERM_LUMINANCE=10 $mdee -n $test_md 2>&1`;
    like($dark, qr/^greple '-Mmd::config\(mode=dark/m, 'TERM_LUMINANCE below 50 selects dark mode');
    my $light = `TERM_LUMINANCE=90 $mdee -n $test_md 2>&1`;
    like($light, qr/^greple '-Mmd::config\(mode=light/m, 'TERM_LUMINANCE of 50 or more selects light mode');
};

# Test: no-nup option
subtest 'no-nup option' => sub {
    my $out = `$mdee -d --dryrun --no-nup $test_md 2>&1`;
    unlike($out, qr/run_nup/, '--no-nup excludes nup from pipeline');
};

# Test: no-fold option
subtest 'no-fold option' => sub {
    my $out = `$mdee -ddn --no-fold $test_md 2>&1`;
    my ($greple_line) = $out =~ /^(debug: greple .*)$/m;
    unlike($greple_line // '', qr/fold=1\b/, '--no-fold excludes fold from greple');
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
    unlike($ddn, qr/fold=1\b/, '-f disables fold');
    unlike($ddn, qr/run_nup/, '-f disables nup');
    like($ddn, qr/table=1/, '-f keeps table enabled');
};

# Test: style option
subtest 'style option' => sub {
    my $nup = `COLUMNS=200 $mdee -d --dryrun --style=nup $test_md 2>&1`;
    like($nup, qr/run_nup/, '--style=nup includes nup');

    my $nup_ddn2 = `COLUMNS=200 $mdee -ddn --style=nup $test_md 2>&1`;
    like($nup_ddn2, qr/fold=1\b/, '--style=nup includes fold');

    my $nup_ddn = `COLUMNS=200 $mdee -ddn --style=nup $test_md 2>&1`;
    like($nup_ddn, qr/table=1/, '--style=nup includes table');

    my $pager = `$mdee -d --dryrun --style=pager $test_md 2>&1`;
    unlike($pager, qr/run_nup/, '--style=pager excludes nup');
    like($pager, qr/run_pager/, '--style=pager includes pager');

    my $pager_ddn2 = `$mdee -ddn --style=pager $test_md 2>&1`;
    like($pager_ddn2, qr/fold=1\b/, '--style=pager includes fold');

    my $pager_ddn = `$mdee -ddn --style=pager $test_md 2>&1`;
    like($pager_ddn, qr/table=1/, '--style=pager includes table');

    my $cat = `$mdee -d --dryrun --style=cat $test_md 2>&1`;
    unlike($cat, qr/run_nup/, '--style=cat excludes nup');

    my $cat_ddn = `$mdee -ddn --style=cat $test_md 2>&1`;
    like($cat_ddn, qr/fold=1\b/, '--style=cat includes fold');
    like($cat_ddn, qr/table=1/, '--style=cat includes table');

    my $filter_ddn = `$mdee -ddn --style=filter $test_md 2>&1`;
    unlike($filter_ddn, qr/fold=1\b/, '--style=filter excludes fold');
    unlike($filter_ddn, qr/run_nup/, '--style=filter excludes nup');
    like($filter_ddn, qr/table=1/, '--style=filter includes table');

    my $raw_ddn = `$mdee -ddn --style=raw $test_md 2>&1`;
    unlike($raw_ddn, qr/fold=1\b/, '--style=raw excludes fold');
    unlike($raw_ddn, qr/table=1/, '--style=raw excludes table');
    like($raw_ddn, qr/table=0/, '--style=raw sends table=0');
    unlike($raw_ddn, qr/run_nup/, '--style=raw excludes nup');

    my $bogus = `$mdee --dryrun --style=bogus $test_md 2>&1`;
    like($bogus, qr/unknown style/, '--style=bogus produces error');
};

# Test: plain option
subtest 'plain option' => sub {
    my $out = `$mdee -d --dryrun -p $test_md 2>&1`;
    unlike($out, qr/run_nup/, '-p excludes nup');
    like($out, qr/run_pager/, '-p includes pager');

    my $ddn = `$mdee -ddn -p $test_md 2>&1`;
    like($ddn, qr/fold=1\b/, '-p includes fold');
    like($ddn, qr/table=1/, '-p includes table');
};

# Test: style override
subtest 'style override' => sub {
    my $ddn = `$mdee -ddn -f --fold $test_md 2>&1`;
    like($ddn, qr/fold=1\b/, '-f --fold enables fold');
    unlike($ddn, qr/run_nup/, '-f --fold keeps nup disabled');

    my $out2 = `$mdee -d --dryrun -p --no-fold $test_md 2>&1`;
    like($out2, qr/run_pager/, '-p --no-fold keeps pager');
    my $ddn2 = `$mdee -ddn -p --no-fold $test_md 2>&1`;
    unlike($ddn2, qr/fold=1\b/, '-p --no-fold disables fold');
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

    # + (CommonMark bullet) should fold with the continuation indented
    # under the text; without the md fold the output is still folded,
    # but from the start of the line
    my @plus = map { s/\e\[[\d;]*[mK]//gr }
        $fold_lines->("+ " . join(' ', ('word') x 30) . "\n");
    ok(@plus > 1, '+ list item is folded');
    is(scalar(grep { !/^  \S/ } @plus[1..$#plus]), 0,
       '+ list item continuation lines are indented');
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
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light $test_md 2>&1`;
        like($out, qr/run_pager/, 'default[style]=pager adds pager');
        unlike($out, qr/run_nup/, 'default[style]=pager removes nup');
    }

    # Settings in config.sh take precedence over the default themes
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "md_config+=(table_cell_mark=+)\n";
        print $fh "pass_md+=(--cm 'emphasis_mark=sub{\"@@\"}')\n";
        close $fh;
        my $md = File::Spec->rel2abs('t/table_wrap.md');
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -s cat -w 40 $md 2>&1`;
        like(decode_utf8($out), qr/\x{2502}\+the quick/m, 'md_config in config.sh overrides the default markcell theme');
        my $bold = `XDG_CONFIG_HOME=$tmpdir $mdee -s cat $test_md 2>&1`;
        like($bold, qr/@@/, 'pass_md in config.sh overrides the default nomark theme');
    }

    # Test default[width]
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[width]=40\n";
        close $fh;
        my $out = `COLUMNS=200 XDG_CONFIG_HOME=$tmpdir $mdee -ddn --mode=light $test_md 2>&1`;
        like($out, qr/debug: nup .*-w 40/, 'default[width]=40 sets the output width');
        like($out, qr/fold_width=33\b/, 'default[width]=40 gives a fold width of 33');
    }

    # Test default[fold_width]
    {
        open my $fh, '>', "$config_dir/config.sh" or die;
        print $fh "default[fold_width]=40\n";
        close $fh;
        my $out = `COLUMNS=200 XDG_CONFIG_HOME=$tmpdir $mdee -ddn --mode=light $test_md 2>&1`;
        like($out, qr/fold_width=40\b/, 'default[fold_width]=40 sets fold width');
        unlike($out, qr/debug: nup .*-w /, 'default[fold_width] does not set the output width');
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
        my $out = `COLUMNS=200 XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light -s nup -w 200 $test_md 2>&1`;
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

    # Test --theme and --no-theme skip default[theme]: the result must
    # differ from what default[theme] gives
    {
        open my $fh, q(>), "$config_dir/config.sh" or die;
        print $fh "default[theme]='warm'\n";
        close $fh;
        my $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --no-theme $test_md 2>&1`;
        unlike($out, qr/Coral/, q(--no-theme skips default[theme]));
        $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --theme=hashed $test_md 2>&1`;
        unlike($out, qr/Coral/, q(--theme skips default[theme]));
        like($out, qr/hashed\.h3=1/, q(--theme still adds to the built-in default));
        open $fh, q(>), "$config_dir/config.sh" or die;
        print $fh "default[theme]='hashed'\n";
        close $fh;
        $out = `XDG_CONFIG_HOME=$tmpdir $mdee -d --dryrun --mode=light --theme=warm $test_md 2>&1`;
        like($out, qr/Coral/, q(the theme given with --theme is applied));
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

subtest 'share theme doubleline' => sub {
    plan skip_all => 'share/theme/doubleline.sh not found' unless -f 'share/theme/doubleline.sh';
    my @vars = qw(TERM_PROGRAM KITTY_WINDOW_ID ALACRITTY_WINDOW_ID KONSOLE_VERSION WT_SESSION VTE_VERSION);
    delete local @ENV{@vars};
    local $ENV{TERM} = 'xterm-256color';
    my $h4 = sub {
	my($opt, %env) = @_;
	local @ENV{keys %env} = values %env;
	scalar `$mdee -s cat $opt $test_md`;
    };
    my @good = (
	[ TERM_PROGRAM => 'iTerm.app' ], [ TERM_PROGRAM => 'ghostty' ],
	[ TERM_PROGRAM => 'vscode' ],    [ TERM_PROGRAM => 'WezTerm' ],
	[ KITTY_WINDOW_ID => 1 ],  [ ALACRITTY_WINDOW_ID => 1 ],
	[ KONSOLE_VERSION => 230000 ], [ WT_SESSION => 'x' ], [ VTE_VERSION => 5200 ],
    );
    my @bad = (
	[ TERM_PROGRAM => 'Apple_Terminal' ], [ TERM_PROGRAM => 'tmux' ],
	[ TERM_PROGRAM => 'unknown' ], [ VTE_VERSION => 5199 ],
    );
    like($h4->('', @$_), qr/4:2;1m#* ?Heading 4/, "double underline with @$_") for @good;
    unlike($h4->('', @$_), qr/4:2/, "no double underline with @$_") for @bad;
    unlike($h4->(''), qr/4:2/, 'no double underline without the variables');
    unlike($h4->('--no-theme', TERM_PROGRAM => 'iTerm.app'), qr/4:2/, 'no double underline without the theme');
    unlike($h4->('', TERM => $_, KITTY_WINDOW_ID => 1), qr/4:2/, "no double underline in TERM=$_") for qw(screen-256color tmux-256color);
};

subtest 'share themes markcell and markwrap' => sub {
    plan skip_all => 'share/theme/markcell.sh not found' unless -f 'share/theme/markcell.sh';
    my $md = File::Spec->rel2abs('t/table_wrap.md');
    my $item = decode_utf8(scalar `$mdee -s cat -w 40 --no-theme --theme=markcell $md`);
    is($?, 0, 'markcell theme loads successfully');
    like($item, qr/^ k1\s+\x{2502}\x{2023}the quick/m, 'markcell marks the first line of the cells in the wrapped column');
    like($item, qr/^ key\s+\x{2502} description/m, 'markcell leaves the header row alone');
    unlike($item, qr/\x{203A}/, 'markcell alone has no continuation mark');
    my $wrap = decode_utf8(scalar `$mdee -s cat -w 40 --no-theme --theme=markwrap $md`);
    is($?, 0, 'markwrap theme loads successfully');
    like($wrap, qr/\x{2502}\x{203A}\S/, 'markwrap marks continuation lines');
    unlike($wrap, qr/\x{2023}/, 'markwrap alone has no first-line mark');
    my $both = decode_utf8(scalar `$mdee -s cat -w 40 --theme=markwrap $md`);
    like($both, qr/\x{2502}\x{2023}the quick/m, 'default plus markwrap keeps the first-line mark');
    like($both, qr/\x{2502}\x{203A}\S/, 'default plus markwrap adds the continuation mark');
    my $none = decode_utf8(scalar `$mdee -s cat -w 40 --no-theme $md`);
    unlike($none, qr/\x{2023}|\x{203A}/, '--no-theme uses no mark');
};

subtest 'table wrap' => sub {
    my $md = File::Spec->rel2abs('t/table_wrap.md');
    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; s/\e\]8;;[^\e]*\e\\//g; $_ };
    my $tlines = sub { grep { /[\x{2502}\x{253C}]/ } map { $strip->($_) } split /\n/, decode_utf8(shift) };
    my @t = $tlines->(scalar `$mdee -s cat -w 40 $md`);
    ok(@t > 6, 'wide table is wrapped');
    ok(!(grep { ansi_width($_) > 40 } @t), 'table fits in --width');
    my @off = $tlines->(scalar `$mdee -s cat -w 40 --config table_width=0 $md`);
    ok((grep { ansi_width($_) > 40 } @off), '--config table_width=0 disables wrapping');
    my $cell = `$mdee -s cat -w 40 --config table_cell=0:10 $md`;
    isnt($cell, scalar `$mdee -s cat -w 40 $md`, '--config table_cell changes the layout');
    my $dry = `$mdee -ddn -s cat -w 40 $md 2>&1`;
    like($dry, qr/table_width=40/, 'table_width is passed to the md module');
};

# Test: parallel option (files side by side)
subtest q(parallel option) => sub {
    my $help = `$mdee --help 2>&1`;
    like($help, qr/--parallel/, q(--help shows --parallel option));

    my $short = `COLUMNS=200 $mdee -ddn -V $test_md $test_md 2>&1`;
    like($short, qr/debug: nup .*-V .*--pane=2/, q(-V is the short form of --parallel));
    my $catv = `COLUMNS=200 $mdee -ddn --cat-v $test_md 2>&1`;
    like($catv, qr/run_cat_v/, q(--cat-v still works without a short option));

    my $two = `COLUMNS=200 $mdee -ddn --parallel $test_md $test_md 2>&1`;
    like($two, qr/debug: nup .*-V .*--pane=2 .*- --pages/, q(--parallel runs nup -V with one pane per file));
    like($two, qr/fold_width=93\b/, q(--parallel folds to the pane width));

    my $three = `COLUMNS=200 $mdee -ddn --parallel $test_md $test_md $test_md 2>&1`;
    like($three, qr/--pane=3/, q(three files give three panes));
    like($three, qr/fold_width=59\b/, q(fold width follows the pane count));

    my $pane = `COLUMNS=200 $mdee -ddn --parallel -C1 $test_md $test_md 2>&1`;
    like($pane, qr/-V .*--pane=1 .*- --pages/, q(-C overrides the pane count));

    my $one = `COLUMNS=200 $mdee -ddn --parallel $test_md 2>&1`;
    unlike($one, qr/debug: nup .*-V/, q(--parallel with a single file is ignored));

    my $plain = `COLUMNS=200 $mdee -ddn $test_md $test_md 2>&1`;
    unlike($plain, qr/debug: nup .*-V/, q(without --parallel nup runs as before));
};

# Test: filename option (file name label from greple)
# Test: table style option
subtest q(table style option) => sub {
    my $help = `$mdee --help 2>&1`;
    like($help, qr/--table-style=/, q(--help shows --table-style option));
    like(`COLUMNS=200 $mdee -ddn --ts=3line $test_md 2>&1`, qr/debug: greple .*table_style=3line/, q(--ts is short for --table-style));

    my $default = `COLUMNS=200 $mdee -ddn $test_md 2>&1`;
    unlike($default, qr/table_style=/, q(no table_style parameter by default));

    for my $style (qw(3line simple)) {
	my $out = `COLUMNS=200 $mdee -ddn --table-style=$style $test_md 2>&1`;
	like($out, qr/debug: greple .*table_style=$style/, qq(--table-style=$style is passed to the md module));
    }
    for my $style (qw(lattice pipe)) {
	my $out = `COLUMNS=200 $mdee -ddn --table-style=$style $test_md 2>&1`;
	unlike($out, qr/table_style=/, qq(--table-style=$style is the default));
    }

    for my $style (qw(grid unknown)) {
	my $bad = `$mdee -n --table-style=$style $test_md 2>&1`;
	like($bad, qr/--table-style: lattice, 3line or simple expected/, qq(--table-style=$style is rejected));
    }
};

subtest q(widen theme) => sub {
    my $out = `COLUMNS=200 $mdee -n -t widen $test_md 2>&1`;
    like($out, qr/--begin '&widen\(chars=2460-24FF:1F5D1\)' --/, q(gives the function and the characters to the md module));

    my $tmp = tempdir(CLEANUP => 1);
    mkdir "$tmp/mdee";
    open my $fh, q(>), "$tmp/mdee/config.sh" or die;
    print $fh "widen_chars+=(3248-324F)\n";
    close $fh;
    $out = `XDG_CONFIG_HOME=$tmp COLUMNS=200 $mdee -n -t widen $test_md 2>&1`;
    like($out, qr/chars=3248-324F:2460-24FF:1F5D1\)/, q(widen_chars of config.sh is added));
};

subtest q(pass_md in config.sh) => sub {
    my $tmp = tempdir(CLEANUP => 1);
    mkdir "$tmp/mdee";
    open my $fh, q(>), "$tmp/mdee/config.sh" or die;
    print $fh "pass_md+=(--begin 'sub{ s/a/b/ }')\nmd_config+=(tick_open=x)\n";
    close $fh;
    my $out = `XDG_CONFIG_HOME=$tmp COLUMNS=200 $mdee -n $test_md 2>&1`;
    is(() = $out =~ /--begin 'sub\{ s\/a\/b/g, 1, q(pass_md of config.sh is given once));
    is(() = $out =~ /tick_open=x/g, 1, q(md_config of config.sh is given once));
};

subtest q(theme name with a path) => sub {
    my $tmp = tempdir(CLEANUP => 1);
    mkdir "$tmp/mdee";
    mkdir "$tmp/mdee/theme";
    open my $fh, q(>), "$tmp/evil.sh" or die;
    print $fh "touch $tmp/run\n";
    close $fh;
    open $fh, q(>), "$tmp/mdee/theme/good.sh" or die;
    print $fh "touch $tmp/good\n";
    close $fh;
    my $out = `XDG_CONFIG_HOME=$tmp $mdee -n -t ../../evil $test_md 2>&1`;
    isnt($?, 0, q(a name with a slash is an error));
    like($out, qr/theme not found/, q(as a theme not found));
    ok(!-e "$tmp/run", q(the file does not run));
    `XDG_CONFIG_HOME=$tmp $mdee -n -t good $test_md 2>&1`;
    is($?, 0, q(a theme in the directory is fine));
    ok(-e "$tmp/good", q(and runs));
};

subtest q(filename option) => sub {
    my $help = `$mdee --help 2>&1`;
    like($help, qr/--\[no-\]filename/, q(--help shows --filename option));

    my $default = `COLUMNS=200 $mdee -ddn -V $test_md $test_md 2>&1`;
    unlike($default, qr/debug: greple .* -h /, q(file names are shown by default));

    my $none = `COLUMNS=200 $mdee -ddn -V --no-filename $test_md $test_md 2>&1`;
    like($none, qr/debug: greple .* -h /, q(--no-filename passes -h to greple));
};

# Test: run-in and run-out
subtest q(runin and runout options) => sub {
    my $help = `$mdee --help 2>&1`;
    like($help, qr/--runlen/, q(--help shows --runlen option));

    my $default = `COLUMNS=200 $mdee -ddn $test_md 2>&1`;
    like($default, qr/debug: nup .*--runin=4 --runout=4/, q(nup gets run-in 4 by default));
    like($default, qr/fold_width=93\b/, q(default fold width leaves run-in 4));
    like($default, qr/fold_runin=4,fold_runout=4\b/, q(the md module gets run-in 4 by default));

    my $two = `COLUMNS=200 $mdee -ddn --runlen=2 $test_md 2>&1`;
    like($two, qr/debug: nup .*--runin=2 --runout=2/, q(--runlen sets run-in and run-out));
    like($two, qr/fold_width=95\b/, q(fold width follows the run-in));
    like($two, qr/fold_runin=2,fold_runout=2\b/, q(the md module gets the same run-in));

    my $mix = `COLUMNS=200 $mdee -ddn --runlen=4 --runout=1 $test_md 2>&1`;
    like($mix, qr/debug: nup .*--runin=4 --runout=1/, q(a later --runout overrides --runlen));

    like($default, qr/debug: nup .*--boundary=word/, q(nup gets --boundary=word by default));
    my $none = `COLUMNS=200 $mdee -ddn --boundary=none $test_md 2>&1`;
    like($none, qr/debug: nup .*--boundary=none/, q(--boundary=none is passed to nup));
    my $bad = `$mdee -n --boundary=foo $test_md 2>&1`;
    like($bad, qr/--boundary: word, space or none expected/, q(--boundary rejects other values));

    my $later = `COLUMNS=200 $mdee -ddn --runout=1 --runlen=4 $test_md 2>&1`;
    like($later, qr/debug: nup .*--runin=4 --runout=4/, q(--runlen overrides earlier --runout));
};

# Test: output width option (-w) and --fold-width
subtest q(refill option) => sub {
    my $out = `COLUMNS=200 $mdee -n --refill $test_md 2>&1`;
    like($out, qr/^greple .*refill=1/m, q(--refill passes refill=1 to the md module));
    $out = `COLUMNS=200 $mdee -n -r $test_md 2>&1`;
    like($out, qr/^greple .*refill=1/m, q(-r is --refill));
    $out = `COLUMNS=200 $mdee -n $test_md 2>&1`;
    unlike($out, qr/refill=/, q(refill is off by default));
    $out = `$mdee --help 2>&1`;
    like($out, qr/\[no-\]refill/, q(--help shows --refill option));

    # no parser works: a pandoc that always fails on PATH, and a
    # CommonMark.pm and a Markdown/Perl.pm that die ahead in PERL5LIB;
    # --refill stops before running anything
    my $bin = tempdir(CLEANUP => 1);
    open my $fh, q(>), "$bin/pandoc" or die;
    print $fh "#!/bin/sh\nexit 1\n";
    close $fh;
    chmod 0755, "$bin/pandoc";
    open $fh, q(>), "$bin/CommonMark.pm" or die;
    print $fh "die q(not here);\n";
    close $fh;
    mkdir "$bin/Markdown";
    open $fh, q(>), "$bin/Markdown/Perl.pm" or die;
    print $fh "die q(not here);\n";
    close $fh;
    my $lib = join ':', $bin, grep { defined and length } $ENV{PERL5LIB};
    $out = `PATH=$bin:$ENV{PATH} PERL5LIB=$lib COLUMNS=200 $mdee -n --refill $test_md 2>&1`;
    isnt($? >> 8, 0, q(--refill fails without a parser));
    like($out, qr/requires .*pandoc/, q(the error names the parsers));
    unlike($out, qr/^greple/m, q(the pipeline is not shown));

    # default[refill] in config.sh
    my $tmpdir = tempdir(CLEANUP => 1);
    mkdir "$tmpdir/mdee";
    open $fh, q(>), "$tmpdir/mdee/config.sh" or die;
    print $fh "default[refill]=1\n";
    close $fh;
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n $test_md 2>&1`;
    like($out, qr/^greple .*refill=1/m, q(default[refill]=1 turns refill on));
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n --no-refill $test_md 2>&1`;
    unlike($out, qr/refill=/, q(--no-refill overrides default[refill]));
    open $fh, q(>), "$tmpdir/mdee/config.sh" or die;
    print $fh "default[refill]=0\n";
    close $fh;
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n $test_md 2>&1`;
    unlike($out, qr/refill=/, q(default[refill]=0 leaves refill off));

    # fatchap adds lines, which puts the folding of refill off, so it
    # turns off the default but not the option
    open $fh, q(>), "$tmpdir/mdee/config.sh" or die;
    print $fh "default[refill]=1\n";
    close $fh;
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n -t fatchap $test_md 2>&1`;
    unlike($out, qr/refill=/, q(fatchap turns off default[refill]));
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n -t fatchap -r $test_md 2>&1`;
    like($out, qr/^greple .*refill=1/m, q(--refill works with fatchap));
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n -t fatchap --no-refill $test_md 2>&1`;
    unlike($out, qr/refill=/, q(--no-refill works with fatchap));
    $out = `XDG_CONFIG_HOME=$tmpdir COLUMNS=200 $mdee -n -t warm $test_md 2>&1`;
    like($out, qr/^greple .*refill=1/m, q(other themes leave default[refill]));
};

subtest q(pane option with rows) => sub {
    my $run = sub { my $opt = shift; scalar `COLUMNS=200 $mdee -ddn $opt $test_md 2>&1` };

    my $cr = $run->('-C2,2');
    like($cr, qr/debug: nup .*--pane=2,2/, q(-C2,2 gives nup the columns and the rows));
    like($cr, qr/fold_width=93\b/, q(-C2,2 folds for two columns));

    like($run->('-C3'), qr/debug: nup .*--pane=3(?: |$)/m, q(-C3 is the columns alone));
    like($run->('-C2,2 -w 180'), qr/debug: nup .*--pane=2,2 - -w 180/,
         q(the rows are kept with -w));
    like($run->('-C2,3 -R1'), qr/debug: nup .*-R 1 .*--pane=2,3/,
         q(-R is given to nup with -C C,R));

    for my $bad (qw(2x2 a ,2 2,)) {
        like($run->("-C$bad"), qr/\Q$bad\E: invalid argument/, qq(-C$bad is an error));
    }
};

subtest q(output width option) => sub {
    my $help = `$mdee --help 2>&1`;
    like($help, qr/--fold-width/, q(--help shows --fold-width option));

    my $two = `COLUMNS=300 $mdee -ddn -w 180 $test_md 2>&1`;
    like($two, qr/debug: nup .*--pane=2 .*- -w 180/, q(-w gives nup the pane count and ansicolumn -w));
    like($two, qr/fold_width=83\b/, q(fold width is derived from -w and the pane count));
    like($two, qr/table_width=83\b/, q(table width follows the fold width));

    my $one = `COLUMNS=300 $mdee -ddn -w 100 $test_md 2>&1`;
    like($one, qr/debug: nup .*--pane=1 - --pages -w 100/, q(single column passes -w after --pages));
    like($one, qr/fold_width=93\b/, q(single column fold width is -w minus 7));

    my $par = `COLUMNS=300 $mdee -ddn -V -w 140 $test_md $test_md 2>&1`;
    like($par, qr/debug: nup .*-V --pane=2 - --pages -w 140/, q(--parallel passes -w to ansicolumn));
    like($par, qr/fold_width=63\b/, q(--parallel fold width follows -w));

    my $cat = `COLUMNS=300 $mdee -ddn -s cat -w 40 $test_md 2>&1`;
    like($cat, qr/fold_width=40\b/, q(without nup -w is the fold width));

    my $fold = `COLUMNS=300 $mdee -ddn -w 180 --fold-width=60 $test_md 2>&1`;
    like($fold, qr/fold_width=60\b/, q(--fold-width overrides the derived fold width));
    like($fold, qr/table_width=60\b/, q(--fold-width also sets the table width));
    like($fold, qr/debug: nup .*- -w 180/, q(--fold-width keeps the output width));

    my $plain = `COLUMNS=300 $mdee -ddn $test_md 2>&1`;
    unlike($plain, qr/debug: nup .*-w /, q(without -w nup gets no width));
    like($plain, qr/fold_width=93\b/, q(without -w the fold width comes from the terminal));
};

# Test: output device (-T) and output file (-o)
subtest 'device and output' => sub {
    plan skip_all => 'ansi2pdf 0.1.3 is not available'
        unless (`ansi2pdf --geometry -p a4p 2>/dev/null` // '') =~ /^\d+ \d+$/;
    plan skip_all => 'nup 1.13 is not available'
        unless (`nup -T a4p --geometry 2>/dev/null </dev/null` // '') =~ /^\d+ \d+ pdf$/;
    my $geom = sub {
        my($cols) = `ansi2pdf -C1 --no-border -L @_ --geometry` =~ /^(\d+) /;
        $cols;
    };
    my $fold = sub { my($cols, $panes) = @_; my $w = int($cols / $panes) - 3 - 4; qr/fold_width=$w\b/ };
    my $run = sub { my $opt = shift; `COLUMNS=100 TERM_LUMINANCE=10 $mdee -d --dryrun $opt $test_md 2>&1` };

    # the paper takes the place of the terminal
    my $a4 = $run->('-T a4');
    my $w = $geom->('-p a4');
    cmp_ok($w, '>', 170, 'A4 in landscape has room for two panes');
    like($a4, qr/\| nup .*-T a4\b/, '-T is given to nup');
    like($a4, $fold->($w, 2), '-T a4: the fold width comes from the paper');
    like($a4, qr/mode=light/, '-T a4: light mode on paper');
    unlike($a4, qr/less/, '-T a4: no pager');
    like($run->('-T a4 --mode=dark'), qr/mode=dark/, '--mode is kept');

    # one pane goes through nup as well
    my $a4p = $run->('-T a4p');
    my $wp = $geom->('-p a4p');
    cmp_ok($wp, '<', 170, 'A4 in portrait has room for one pane');
    like($a4p, qr/\| nup .*-T a4p\b/, '-T a4p is given to nup');
    like($a4p, $fold->($wp, 1), '-T a4p: the fold width comes from the paper');
    unlike($a4p, qr/--no-paginate|less/, '-T a4p: nup prints the single pane');

    # -o, and PDF by the name
    my $o = $run->('-o out.pdf');
    like($o, qr/\| nup .*-o out\.pdf\b/, '-o is given to nup');
    like($o, $fold->($geom->(), 2), '-o out.pdf: the default paper');
    like($o, qr/mode=light/, '-o out.pdf: light mode');

    # lines of a page and columns
    my $w80 = $geom->('-p a4 -l 80');
    like($run->('-T a4 -P 80'), $fold->($w80, int($w80 / 85)), '-P sets the lines of a sheet');
    like($run->('-T a4 -P 40 -G 2x2'), $fold->($w80, int($w80 / 85)), '-P with rows');
    like($run->('-T a4 -P 40 -R 2'), $fold->($w80, int($w80 / 85)), '-P with -R');
    like($run->('-T a4 -w 300 -C3'), $fold->(300, 3), '-w is kept');

    # the terminal
    my $tty = $run->('-T tty');
    like($tty, qr/mode=dark/, '-T tty: mode of the terminal');
    like($tty, $fold->(100, 1), '-T tty: width of the terminal');
    my $txt = $run->('-o out.txt');
    like($txt, qr/\| nup .*-o out\.txt\b/, '-o out.txt is given to nup');
    like($txt, qr/mode=dark/, '-o out.txt: mode of the terminal');
    unlike($txt, qr/--no-paginate|less/, '-o out.txt: no pager');

    # errors
    like($run->('-T a4 -f'), qr/need|nup/i, '-T needs nup');
    isnt($? >> 8, 0, '-T with -f fails');
    $run->('-T nosuch');
    isnt($? >> 8, 0, 'unknown paper fails');
};

done_testing;
