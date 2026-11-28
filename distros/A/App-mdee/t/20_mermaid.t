use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

use File::Temp qw(tempdir);

use lib '.';
use t::Util;

# image_types with mermaid: the diagrams of the fenced code blocks of
# mermaid are drawn by mermaid_command, a stub of mmdr here, and the
# rows of their images go below the closing fences.  mmdr has no
# options for the background and the scale, so the background is given
# in a file of -c, and the size of the diagram multiplied by the scale,
# which it is asked for first with --size.  Each diagram is drawn in a
# run of its own, from a .mmd file.  The stub fails on an option that
# mmdr does not have, tells 64x33.5 as the size of a diagram, writes a
# PNG of the size it is given (64x34 without), and logs its arguments
# and the file of -c.

$ENV{HOME} = my $dir = tempdir(CLEANUP => 1);
$ENV{TMPDIR} = "$dir/tmp";
mkdir "$dir/tmp";
my $cache = "$dir/tmp/mdee-mermaid-$>";

my $PH = "\x{10EEEE}";

my $log  = "$dir/log";
my $stub = "$dir/mmdr-stub";
$ENV{STUB_LOG} = $log;
{
    open my $fh, '>', $stub or die;
    print $fh "#!$^X\n", <<'STUB';
use strict;
use warnings;
my(%opt, $size);
while (@ARGV) {
    my $o = shift;
    if    ($o eq '--size')         { $size = 1 }
    elsif ($o =~ /^-[ioetcwH]$/)   { $opt{$o} = shift }
    else                           { exit 2 }
}
my $conf = '';
if (defined $opt{-c}) {
    open my $c, '<', $opt{-c} or exit 2;
    chomp($conf = do { local $/; <$c> });
}
open my $log, '>>', $ENV{STUB_LOG} or die;
print $log join(' ', map { "$_ $opt{$_}" } grep { defined $opt{$_} } qw(-i -o -e -t -w -H)),
    $size ? ' --size' : '', " conf=$conf\n";
close $log;
exit 1 if $ENV{FAIL};
$opt{-i} =~ /\.mmd$/ or exit 2;
open my $in, '<', $opt{-i} or die;
my $text = do { local $/; <$in> };
exit 1 if $text =~ /BAD/;
if ($size) {
    print $ENV{NOSIZE} ? "?\n" : qq({\n  "width": 64.0,\n  "height": 33.5\n}\n);
    exit 0;
}
my($w, $h) = ($opt{-w} // 64, $opt{-H} // 34);
open my $png, '>:raw', $opt{-o} or die;
print $png "\x89PNG\r\n\x1a\n", pack('N', 13), 'IHDR',
    pack('NNCCCCC', $w, $h, 8, 6, 0, 0, 0), "\0\0\0\0",
    pack('N', 0), 'IEND', "\xae\x42\x60\x82";
STUB
    close $fh;
    chmod 0755, $stub;
}
sub runs { my @l; if (open my $fh, '<', $log) { @l = <$fh> } @l }

sub md {
    my($name, $text) = @_;
    open my $fh, '>:encoding(utf-8)', "$dir/$name" or die;
    print $fh $text;
    close $fh;
    "$dir/$name";
}

my $tty = "$dir/tty";
my $base = 'mode=light';
my $term = "image_term=80x24:16x34,image_tty=$tty,image_align=left,mermaid_scale=3";
my $img  = "$term,mermaid_command=$stub";

sub mdee_out {
    my($cfg, $md) = @_;
    unlink $tty;
    run("'-Mmd::config($cfg)' $md")->stdout;
}
sub plain { (my $s = shift) =~ s/\e\[[0-9;]*[mK]//g; $s }

my $doc = md('doc.md', join '',
    "# Title\n\n",
    "```mermaid\nflowchart LR\n  A[入力] --> B\n```\n\n",
    "```perl\nprint 1;\n```\n\n",
    "```mermaid\nsequenceDiagram\n  A->>B: hi\n```\n\n",
    "```mermaid\nflowchart LR\n  A[入力] --> B\n```\n\n",
    "end\n");

# without mermaid in image_types, nothing changes and nothing is drawn
{
    my $out = mdee_out("$base,image_types=png:jpeg:gif,$img", $doc);
    unlike($out, qr/$PH/, 'off: no placeholder');
    is(scalar(runs()), 0, 'off: the command is not run');
}

# the rows of the images below the closing fences; each diagram in two
# runs, for its size and for the image, which is 192x101 (64x33.5 by
# the scale 3): 12 cells wide, 3 rows high
{
    my $out = mdee_out("$base,image_types=mermaid,$img", $doc);
    my @l = split /\n/, plain($out);
    my @fence = grep { $l[$_] eq '```' } keys @l;
    is(scalar @fence, 4, 'the code blocks are kept');
    for my $i (@fence[0, 2, 3]) {
	is(scalar(grep { /$PH/ } @l[$i + 1 .. $i + 3]), 3, "three rows below the fence at line $i");
	unlike($l[$i + 4], qr/$PH/, "no more rows below the fence at line $i");
    }
    unlike($l[$fence[1] + 1], qr/$PH/, 'no rows below a code block of perl');
    ok(-s $tty, 'the data of the images is sent');
    my @runs = runs();
    is(scalar @runs, 4, 'two runs for each diagram, the same one once');
    is(scalar(grep { /-i \S+\.mmd / } @runs), 4, 'from a .mmd file each');
    is(scalar(grep { / --size / } @runs), 2, 'the size is asked for');
    my($draw) = grep { !/ --size / } @runs;
    like($draw, qr/-e png -t default -w 192 -H 101 /, 'the default theme, and the size by the scale 3');
    like($draw, qr/conf=\{"themeVariables":\{"background":"white"\}\}$/, 'the background in the file of -c');
    is(scalar(() = glob "$cache/*.png"), 2, 'two diagrams are kept');
    is(scalar(grep { !/\.png$/ } glob "$cache/*"), 0, 'no temporary file is left');
    is((stat $cache)[2] & 0777, 0700, 'the cache is private to the user');
}

# drawn once: the second time comes from the cache
{
    unlink $log;
    my $out = mdee_out("$base,image_types=mermaid,$img", $doc);
    is(scalar(() = plain($out) =~ /^$PH/mg), 9, 'cache: the rows are there');
    is(scalar(runs()), 0, 'cache: the command is not run');
}

# the same diagram in another file comes from the cache as well
{
    unlink $log;
    my $md = md("another.md", "# Another\n\ntext\n\n```mermaid\nflowchart LR\n  A[入力] --> B\n```\n");
    like(mdee_out("$base,image_types=mermaid,$img", $md), qr/$PH/, "another file: the diagram is shown");
    is(scalar(runs()), 0, "another file: the command is not run");
}

# the dark mode, and the look by the config: drawn again
{
    unlink $log;
    mdee_out("mode=dark,image_types=mermaid,$img", $doc);
    my($draw) = grep { !/ --size / } runs();
    like($draw // '', qr/-t dark .*"background":"#0d1117"/, 'the dark theme on the dark background');
    unlink $log;
    mdee_out("$base,image_types=mermaid,$img,mermaid_theme=forest,mermaid_background=#fff,mermaid_scale=2", $doc);
    ($draw) = grep { !/ --size / } runs();
    like($draw // '', qr/-t forest -w 128 -H 67 .*"background":"#fff"/, 'mermaid_theme, mermaid_background, mermaid_scale');
}

# the scale is 1.5 by default: 96x51 (64x33.5 multiplied)
{
    unlink $log;
    mdee_out("$base,image_types=mermaid,image_term=80x24:16x34,image_tty=$tty,mermaid_command=$stub", $doc);
    my($draw) = grep { !/ --size / } runs();
    like($draw // "", qr/ -w 96 -H 51 /, "the scale 1.5 by default");
}

# with the scale 1 the size is not asked for
{
    unlink $log;
    mdee_out("$base,image_types=mermaid,$img,mermaid_scale=1", $doc);
    my @runs = runs();
    is(scalar @runs, 2, 'scale 1: one run for each diagram');
    unlike($runs[0], qr/ -w | --size /, 'scale 1: no size');
}

# a size that is not told: the diagram is drawn in its own size
{
    unlink $log;
    local $ENV{NOSIZE} = 1;
    my $md = md('nosize.md', "```mermaid\ngraph TD\n  N1 --> N2\n```\n");
    my $out = mdee_out("$base,image_types=mermaid,$img", $md);
    like($out, qr/$PH/, 'no size: drawn');
    my($draw) = grep { !/ --size / } runs();
    unlike($draw, qr/ -w /, 'no size: no -w');
}

# the command with -c of its own is given no other
{
    unlink $log;
    my $own = md('own.json', qq({"themeVariables":{"background":"#123456"}}\n));
    my $md = md('own.md', "```mermaid\ngraph TD\n  O1 --> O2\n```\n");
    my $out = mdee_out("$base,image_types=mermaid,$term,mermaid_command=$stub -c $own", $md);
    like($out, qr/$PH/, 'own -c: drawn');
    is(scalar(grep { !/#123456/ } runs()), 0, 'own -c: the file of the command is used');
}

# the command with a width of its own is not asked for the size
{
    unlink $log;
    my $md = md('width.md', "```mermaid\ngraph TD\n  W1 --> W2\n```\n");
    mdee_out("$base,image_types=mermaid,$term,mermaid_command=$stub -w 320", $md);
    my @runs = runs();
    is(scalar @runs, 1, 'own -w: one run');
    like($runs[0], qr/ -w 320 conf=/, 'own -w: the width of the command, and no -H');
}

# a command with a space in its path, quoted
{
    mkdir "$dir/with space";
    symlink $stub, "$dir/with space/mmdr" or die;
    my $md = md('space.md', "```mermaid\ngraph TD\n  S --> T\n```\n");
    my $out = mdee_out("$base,image_types=mermaid,$term,mermaid_command=\"$dir/with space/mmdr\"", $md);
    like($out, qr/$PH/, 'a quoted path with a space');
}

# a diagram that fails is not shown, the other is, and it is tried
# again the next time
{
    unlink $log;
    my $md = md('bad.md', join '',
	"```mermaid\nBAD\n```\n\n",
	"```mermaid\ngraph TD\n  G1 --> G2\n```\n");
    my $out = mdee_out("$base,image_types=mermaid,$img", $md);
    is(scalar(() = plain($out) =~ /^$PH/mg), 3, 'bad: the other diagram is shown');
    is(scalar(grep { -z } glob "$cache/*.png"), 0, 'bad: nothing is kept for it');
    unlink $log;
    mdee_out("$base,image_types=mermaid,$img", $md);
    ok(scalar(runs()) > 0, 'bad: tried again');
}

# a block of mermaid inside an HTML comment is not drawn
{
    unlink $log;
    my $md = md('comment.md', "<!--\n```mermaid\ngraph TD\n  E --> F\n```\n-->\n\ntext\n");
    my $out = mdee_out("$base,image_types=mermaid,$img", $md);
    unlike($out, qr/$PH/, 'comment: not drawn');
    is(scalar(runs()), 0, 'comment: the command is not run');
}

# a <!-- inside a code block starts no comment
{
    my $md = md('incode.md', join '',
	"```html\n<!-- start\n```\n\n",
	"```mermaid\ngraph TD\n  I --> J\n```\n\n",
	"<!-- real -->\n");
    like(mdee_out("$base,image_types=mermaid,$img", $md), qr/$PH/, 'a <!-- in a code block hides no diagram');
}

# intact=image: the rows are joined by GS, below the closing fence
{
    my $out = mdee_out("$base,image_types=mermaid,$img,intact=image", $doc);
    my @l = split /\n/, plain($out);
    my @line = grep { /$PH/ } @l;
    is(scalar @line, 3, 'intact=image: one line for each diagram');
    like($line[0], qr/^(?:[^\x1D]*$PH[^\x1D]*\x1D){2}[^\x1D]*$PH[^\x1D]*$/, 'intact=image: three rows joined by GS');
    my($i) = grep { $l[$_] =~ /$PH/ } keys @l;
    is($l[$i - 1], '```', 'intact=image: the closing fence is a line of its own');
}

# with refill, the paragraph below a diagram is joined and folded, and
# the rows are not folded
SKIP: {
    require App::Greple::md::Blocks;
    App::Greple::md::Blocks::available() or skip 'no parser for refill', 2;
    my $md = md('refill.md', join '',
	"```mermaid\nflowchart LR\n  A[入力] --> B\n```\n\n",
	"aaaa bbbb cccc\ndddd eeee ffff\n\nend\n");
    my $out = mdee_out("$base,image_types=mermaid,$img,refill=1,fold=1,fold_width=10", $md);
    my @l = split /\n/, plain($out);
    my @text = grep { /[a-f]{4}/ } @l;
    is_deeply([ map { s/\h+$//r } @text ], [ 'aaaa bbbb', 'cccc dddd', 'eeee ffff' ],
	      'refill: the paragraph below the diagram is joined and folded');
    # 12 cells reduced to the fold width
    is(scalar(grep { /$PH/ && !/^(?:$PH.{2}){10}$/ } @l), 0, 'refill: the rows are not folded');
}

# a paragraph above a diagram stays where it is: the rows are counted
# from the line of the closing fence
SKIP: {
    App::Greple::md::Blocks::available() or skip 'no parser for refill', 1;
    my $md = md('above.md', join '',
	"# Title\n\n",
	"aaaa bbbb cccc\ndddd eeee ffff\n\n",
	"```mermaid\nflowchart LR\n  A[入力] --> B\n```\n\nend\n");
    my $out = mdee_out("$base,image_types=mermaid,$img,refill=1,fold=1,fold_width=10", $md);
    my @text = grep { /[a-f]{4}/ } split /\n/, plain($out);
    is_deeply([ map { s/\h+$//r } @text ], [ 'aaaa bbbb', 'cccc dddd', 'eeee ffff' ],
	      'refill: the paragraph above the diagram is joined and folded');
}

# an unwritable cache: the text is shown, without the diagram
SKIP: {
    skip 'root can write anywhere', 2 if $> == 0;
    local $ENV{TMPDIR} = "$dir/ro";
    mkdir "$dir/ro"; mkdir "$dir/ro/mdee-mermaid-$>";
    chmod 0500, "$dir/ro/mdee-mermaid-$>";
    my $md = md('ro.md', "```mermaid\ngraph TD\n  R --> O\n```\n\nafter\n");
    my $out = mdee_out("$base,image_types=mermaid,$img", $md);
    like($out, qr/after/, 'unwritable cache: the text is shown');
    unlike($out, qr/$PH/, 'unwritable cache: no diagram');
    chmod 0700, "$dir/ro/mdee-mermaid-$>";
}

# in a shared /tmp, a symbolic link in place of the directory is not
# used, and the files that the system has cleaned up are drawn again
{
    local $ENV{TMPDIR} = "$dir/link";
    mkdir "$dir/link"; mkdir "$dir/other";
    symlink "$dir/other", "$dir/link/mdee-mermaid-$>" or die;
    my $md = md("link.md", "```mermaid\ngraph TD\n  L --> K\n```\n");
    unlike(mdee_out("$base,image_types=mermaid,$img", $md), qr/$PH/, "a symbolic link: no diagram");
    is(scalar(() = glob "$dir/other/*"), 0, "a symbolic link: nothing is written there");
}
{
    unlink glob "$cache/*.png";
    unlink $log;
    my $out = mdee_out("$base,image_types=mermaid,$img", $doc);
    is(scalar(() = plain($out) =~ /^$PH/mg), 9, "cleaned up: the rows are there");
    ok(scalar(runs()) > 0, "cleaned up: drawn again");
}

done_testing;
