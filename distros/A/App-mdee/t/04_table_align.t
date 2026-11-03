use strict;
use warnings;
use Test::More;
use open qw(:std :encoding(utf-8));

use lib '.';
use t::Util;

# Unit tests for parse_separator
use_ok('App::Greple::md');

sub parse_separator { App::Greple::md::parse_separator(@_) }

# Right-aligned column
{
    my $block = "| A | B |\n|---|---:|\n| a | b |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [2], "right-aligned column");
    is_deeply($center, [], "no center-aligned column");
    unlike($block, qr/:/, "colons stripped from separator");
}

# Center-aligned column
{
    my $block = "| A | B |\n|---|:---:|\n| a | b |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [], "no right-aligned column");
    is_deeply($center, [2], "center-aligned column");
}

# Left-aligned (explicit) — no option generated
{
    my $block = "| A | B |\n|:---|:---|\n| a | b |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [], "left-aligned: no right");
    is_deeply($center, [], "left-aligned: no center");
}

# Mixed alignment
{
    my $block = "| L | C | R | D |\n|:---|:---:|---:|---|\n| a | b | c | d |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [3], "mixed: right column");
    is_deeply($center, [2], "mixed: center column");
}

# No separator line
{
    my $block = "| A | B |\n| a | b |\n| c | d |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [], "no separator: no right");
    is_deeply($center, [], "no separator: no center");
}

# Multiple right-aligned columns
{
    my $block = "| A | B | C |\n|---:|---:|---:|\n| a | b | c |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [1,2,3], "multiple right-aligned columns");
}

# Default (no colon) generates no options
{
    my $block = "| A | B | C |\n|---|---|---|\n| a | b | c |\n";
    my($right, $center) = parse_separator(\$block);
    is_deeply($right, [], "default: no right");
    is_deeply($center, [], "default: no center");
}

# Integration test: aligned table via greple
my $test_md = 't/test.md';

SKIP: {
    skip "$test_md not found", 3 unless -f $test_md;

    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; $_ };
    my $out = run("'-Mmd::config(colorize=0,table=1,rule=1)' $test_md")->stdout;
    my @lines = map { $strip->($_) } split /\n/, $out;

    # Find aligned table by looking for "Left" header
    my ($header_idx) = grep { $lines[$_] =~ /Left.*Center.*Right.*Default/ } 0..$#lines;
    ok(defined $header_idx, "aligned table found in output");

    SKIP: {
        skip "aligned table not found", 2 unless defined $header_idx;

        # Data rows: index +2 (header, separator, first data)
        my $row1 = $lines[$header_idx + 2];

        my $V = "\x{2502}";  # │

        # Right column: values should be right-aligned (leading spaces)
        like($row1, qr/${V}\s+c\s*${V}/, "right-aligned column has leading spaces");

        # Center column: values should have spaces on both sides
        like($row1, qr/${V}\s+b\s+${V}/, "center-aligned column has balanced spaces");
    }
}

# Escaped pipe (\|) inside a cell is not a column separator.  It is shown
# as written for now; backslash escapes are not processed yet.
{
    use File::Temp qw(tempfile);
    my($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    binmode $fh, ':utf8';
    print $fh "| A | B |\n|---|---|\n| x \\| y | z |\n| long cell text | w |\n";
    close $fh;
    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; $_ };
    my $out = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1)' $file")->stdout);
    my @lines = split /\n/, $out;
    my $V = "\x{2502}";
    like($lines[2], qr/x \\\| y\s*${V}\s*z/, "escaped pipe stays in the cell");
    is(scalar(() = $lines[2] =~ /${V}/g), 1, "the row has a single column separator");
    unlike($lines[1], qr/\x{2524}/, "separator row has no stray right border");

    # the same with cell wrapping
    my($fh2, $file2) = tempfile(SUFFIX => '.md', UNLINK => 1);
    binmode $fh2, ':utf8';
    print $fh2 "| A | B |\n|---|---|\n| x \\| y " . ("word " x 12) . "| z |\n| p | q |\n";
    close $fh2;
    my $wrapped = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40,table_cell_mark=\x{b7})' $file2")->stdout);
    like($wrapped, qr/x \\\| y/, "escaped pipe stays in the cell of a wrapped table");
    is(scalar(() = (split /\n/, $wrapped)[2] =~ /${V}/g), 1, "the wrapped row has a single column separator");

    # and without trimming (-s is replaced by the same regex)
    my $notrim = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0)' $file")->stdout);
    like((split /\n/, $notrim)[2], qr/^${V} x \\\| y\s*${V} z\s*${V}$/, "escaped pipe stays in the cell without trimming");
}

# Spaces after the last pipe of a row do not end the table (GFM ignores
# them).  Such a row stayed unformatted between two tables.
{
    use File::Temp qw(tempfile);
    my($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    binmode $fh, ':utf8';
    print $fh "| A | B |\n|---|---|\n| 1 | a |\n| 2 | b | \n| 3 | c |\n";
    close $fh;
    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; $_ };
    my $V = "\x{2502}";
    for my $trim (1, 0) {
	my $out = $strip->(run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=$trim)' $file")->stdout);
	my @lines = split /\n/, $out;
	is(scalar @lines, 5, "table_trim=$trim: one table of five lines");
	unlike($out, qr/^\|/m, "table_trim=$trim: no row is left as written");
	is(length($lines[3]), length($lines[2]), "table_trim=$trim: the row with trailing space has the same width");
    }
}

# Table styles without column separators
{
    my $strip = sub { local $_ = shift; s/\e\[[0-9;]*[mK]//g; $_ };
    my $table = sub {
	my $config = shift;
	my $out = $strip->(run("'-Mmd::config(colorize=0,table=1,$config)' $test_md")->stdout);
	my @lines = split /\n/, $out;
	my($h) = grep { $lines[$_] =~ /Left.*Center.*Right.*Default/ } 0..$#lines;
	(\@lines, $h);
    };
    my $H = "\x{2500}";

    # 3line: a full-width rule above the header, below the header per
    # column, and a full-width rule below the table
    my($l, $h) = $table->("table_style=3line");
    ok(defined $h, "aligned table found in 3line style");
    SKIP: {
	skip "table not found", 5 unless defined $h;
	like($l->[$h - 1], qr/^${H}+$/, "3line: a full-width rule above the header");
	like($l->[$h + 1], qr/^${H}+( ${H}+){3}\s*$/, "3line: the header rule is drawn per column");
	like($l->[$h + 4], qr/^${H}+$/, "3line: a full-width rule below the table");
	unlike(join("\n", @$l[$h .. $h + 3]), qr/[\x{2502}\x{253C}|]/, "3line: no column separators");
	like($l->[$h + 2], qr/\s+c\s+d/, "3line: right alignment is kept");
    }

    # simple: nothing above the header, per-column rules below the
    # header and below the table
    ($l, $h) = $table->("table_style=simple");
    ok(defined $h, "aligned table found in simple style");
    SKIP: {
	skip "table not found", 4 unless defined $h;
	unlike($l->[$h - 1] // '', qr/$H/, "simple: no rule above the header");
	like($l->[$h + 1], qr/^${H}+( ${H}+){3}\s*$/, "simple: the header rule is drawn per column");
	is($l->[$h + 4], $l->[$h + 1], "simple: the same rule below the table");
	unlike(join("\n", @$l[$h .. $h + 3]), qr/[\x{2502}\x{253C}|]/, "simple: no column separators");
    }

    # rule=0 draws the rules in ASCII in all styles
    for my $style (qw(3line simple)) {
	($l, $h) = $table->("table_style=$style,rule=0");
	ok(defined $h, "aligned table found in $style style without rule");
	SKIP: {
	    skip "table not found", 2 unless defined $h;
	    like($l->[$h + 1], qr/^-+( -+){3}\s*$/, "$style: ASCII header rule with rule=0");
	    unlike(join("\n", @$l[$h - 1 .. $h + 4]), qr/$H/, "$style: no box-drawing rule with rule=0");
	}
    }

    # lattice is the default, and pipe is another name of it
    my($d) = $table->("table=1");
    for my $style (qw(lattice pipe)) {
	($l, $h) = $table->("table_style=$style");
	is_deeply($l, $d, "table_style=$style is the default");
    }
}

done_testing;
