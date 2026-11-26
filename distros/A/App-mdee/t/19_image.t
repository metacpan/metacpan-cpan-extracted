use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

use File::Temp qw(tempdir);
use MIME::Base64 qw(encode_base64);

use lib '.';
use t::Util;

# image_types=png:jpeg:gif: a line which is an image and nothing else is followed
# by the rows of the image, drawn by the Unicode placeholders of the
# kitty graphics protocol: U+10EEEE with the row and the column as
# combining characters, and the id of the image as the color.  The
# data of the image goes to the terminal (image_tty) by APC.  The size
# of the terminal is given by image_term here, as there is none.

$ENV{HOME} = my $dir = tempdir(CLEANUP => 1);

my $PH = "\x{10EEEE}";
# the first of the combining characters for row and column numbers
my @D = map { chr hex } qw(0305 030D 030E 0310 0312);

# a PNG which says it is W x H: only its header is read
sub png {
    my($file, $w, $h) = @_;
    open my $fh, '>:raw', $file or die;
    print $fh "\x89PNG\r\n\x1a\n", pack('N', 13), 'IHDR',
	pack('NNCCCCC', $w, $h, 8, 6, 0, 0, 0), "\0\0\0\0",
	pack('N', 0), 'IEND', "\xae\x42\x60\x82";
    close $fh;
}
png("$dir/a.png", 64, 68);	# 4 cells wide, 2 rows high in 16x34 cells

sub md {
    my($name, $text) = @_;
    open my $fh, '>:encoding(utf-8)', "$dir/$name" or die;
    print $fh $text;
    close $fh;
    "$dir/$name";
}

my $tty = "$dir/tty";
my $base = 'mode=light';
my $img  = "image_types=png:jpeg:gif,image_term=80x24:16x34,image_tty=$tty";

sub mdee_out {
    my($cfg, $md) = @_;
    unlink $tty;
    run("'-Mmd::config($cfg)' $md")->stdout;
}
sub sent { open my $fh, '<:raw', $tty or return ''; local $/; <$fh> }

my $doc = md('doc.md', "# Title\n\n![logo](a.png)\n\ntext with ![inline](a.png) in it\n\nend\n");

# without image_types, nothing changes
{
    my $off = mdee_out($base, $doc);
    unlike($off, qr/$PH/, 'off: no placeholder');
    is(sent(), '', 'off: nothing sent');
    is(mdee_out("$base,image_types=,image_term=80x24:16x34,image_tty=$tty", $doc), $off,
       'off: the output is the same with the other image parameters');
}

# the rows of the image
{
    my $out = mdee_out("$base,$img", $doc);
    my @l = split /\n/, $out;
    my($i) = grep { $l[$_] =~ /logo/ } keys @l;
    ok(defined $i, 'the line of the image is kept');
    my @rows = @l[$i + 1, $i + 2];
    my($color) = $rows[0] =~ /^(\e\[38;2;\d+;\d+;\d+m)/;
    ok($color, 'a row has the id of the image as its color');
    for my $r (0, 1) {
	(my $cells = $rows[$r]) =~ s/\e\[[0-9;]*m//g;
	is($cells, join('', map { $PH . $D[$r] . $D[$_] } 0 .. 3), "row $r: 4 cells with row and column");
    }
    unlike($l[$i + 3] // '', qr/$PH/, 'two rows, no more');
    is(scalar(() = $out =~ /$PH/g), 8, 'the inline image has no rows');

    my($r, $g, $b) = $color =~ /(\d+);(\d+);(\d+)m/;
    my $id = ($r << 16) | ($g << 8) | $b;
    my $sent = sent();
    like($sent, qr/^\e_Ga=T,U=1,i=$id,f=100,q=2,c=4,r=2,m=0;/, 'the image is sent with its id and size');
    open my $fh, '<:raw', "$dir/a.png" or die;
    my $data = encode_base64(do { local $/; <$fh> }, '');
    like($sent, qr/;\Q$data\E\e\\$/, 'the data of the image is sent');
}

# image_osc=1: each row tells the file of the image, for ansi2pdf
{
    unlike(mdee_out("$base,$img", $doc), qr/\e\]7771;/, 'no OSC by default');
    my @rows = grep { /$PH/ } split /\n/, mdee_out("$base,$img,image_osc=1", $doc);
    is(scalar @rows, 2, 'image_osc=1: two rows');
    like($_, qr/^\e\]7771;i=\d+,c=4,r=2;\Q$dir\E\/a\.png\e\\/, 'image_osc=1: a row begins with the OSC')
	for @rows;
}

# intact=image: the line of the image and its rows are joined by GS,
# for ansicolumn --intact to keep them in one pane
{
    my $out = mdee_out("$base,$img,intact=image", $doc);
    my($line) = grep { /logo/ } split /\n/, $out;
    my @part = split /\x1D/, $line, -1;
    is(scalar @part, 3, 'intact=image: the line and two rows in one line');
    like($part[1], qr/$PH/, 'intact=image: the rows follow');
}

# what is not shown
{
    my $other = md('other.md', join "\n",
		   '![none](missing.png)', '',
		   '![web](https://example.com/a.png)', '',
		   '```', '![code](a.png)', '```', '');
    my $out = mdee_out("$base,$img", $other);
    unlike($out, qr/$PH/, 'a missing file, a URL and a code block: no image');
    is(sent(), '', 'nothing sent for them');
}

# an image which is not a PNG, by its content, is not taken as one
{
    open my $fh, '>', "$dir/fake.png" or die;
    print $fh "not an image\n";
    close $fh;
    my $out = mdee_out("$base,$img", md('fake.md', "![fake](fake.png)\n"));
    unlike($out, qr/$PH/, 'not an image: no rows');
}

# the HTML <img> of a README made from POD, and an image as a link
{
    my $out = mdee_out("$base,$img", md('html.md', join "\n",
	'<p><img src="a.png" width="100"></p>', '',
	'[![badge](a.png)](https://example.com/)', ''));
    is(scalar(() = $out =~ /$PH/g), 16, 'HTML <img> and a linked image: both shown');
}

# only the types in image_types are shown
{
    my $md = md('types.md', "![png](a.png)\n");
    unlike(mdee_out("$base,image_types=jpeg:gif,image_term=80x24:16x34,image_tty=$tty", $md),
	   qr/$PH/, 'a PNG is not shown without png in image_types');
    is(sent(), '', 'nothing sent for it');
    like(mdee_out("$base,image_types=png,image_term=80x24:16x34,image_tty=$tty", $md),
	 qr/$PH/, 'a PNG is shown with png alone');
}

# the HTML tags of a shown image are in code_info, as the info string
# of a code fence
{
    my $md = md('tag.md', join "\n",
	'<p><img src="a.png"></p>', '', '<p><img src="missing.png"></p>', '',
	'```{.note}', 'x', '```', '');
    my @l = split /\n/, mdee_out("$base,$img", $md);
    my($fence) = map { /^\e\[[0-9;]*m```\e\[m\e\[K(\e\[[0-9;]*m)\{\.note\}/ } @l;
    my($shown) = grep { /a\.png/ } @l;
    my($missing) = grep { /missing\.png/ } @l;
    ok($fence, 'the info string has a color');
    like($shown, qr/^\Q$fence\E<p><img/, 'shown: the tags in the color of the info string');
    like($missing, qr/^<p><img/, 'not shown: the tags as they are');
}

# so is the line of a Markdown image which is shown, as it is written
{
    my $md = md('mdtag.md', join "\n",
	'![logo](a.png)', '', '[![badge](a.png)](https://example.com/)', '',
	'![none](missing.png)', '', '```{.note}', 'x', '```', '');
    my @l = split /\n/, mdee_out("$base,$img", $md);
    my($fence) = map { /^\e\[[0-9;]*m```\e\[m\e\[K(\e\[[0-9;]*m)\{\.note\}/ } @l;
    my($logo)  = grep { /logo/ } @l;
    my($badge) = grep { /badge/ } @l;
    my($none)  = grep { /none/ } @l;
    like($logo, qr/^\Q$fence\E!\[logo\]\(a\.png\)\e\[m/, 'shown: the Markdown image in the color of the info string');
    like($badge, qr/^\Q$fence\E\[!\[badge\]\(a\.png\)\]\(https:\/\/example\.com\/\)/,
	 'shown: an image in a link too');
    unlike($none, qr/^\Q$fence\E/, 'not shown: the Markdown image as before');
}

# rows are limited by image_rows: the width goes down with them
{
    png("$dir/tall.png", 16, 340);	# 1 cell wide, 10 rows high
    my $out = mdee_out("$base,$img,image_rows=3", md('tall.md', "![tall](tall.png)\n"));
    my @rows = grep { /$PH/ } split /\n/, $out;
    is(scalar @rows, 3, 'image_rows: no more rows than given');
}

# with refill, the paragraph below an image is joined and folded, and
# the rows of the image are not folded
SKIP: {
    require App::Greple::md::Blocks;
    App::Greple::md::Blocks::available() or skip 'no parser for refill', 3;
    # three rows: with two, a wrong line number would hit the paragraph by chance
    png("$dir/three.png", 64, 102);
    my $md = md('refill.md', "![logo](three.png)\n\naaaa bbbb cccc\ndddd eeee ffff\n\nend\n");
    my $out = mdee_out("$base,$img,refill=1,fold=1,fold_width=10", $md);
    (my $plain = $out) =~ s/\e\[[0-9;]*m//g;
    my @l = split /\n/, $plain;
    my @text = grep { /[a-f]{4}/ } @l;
    is_deeply([ map { s/\h+$//r } @text ], [ 'aaaa bbbb', 'cccc dddd', 'eeee ffff' ],
	      'refill: the paragraph below the image is joined and folded');
    is(scalar(grep { /$PH/ } @l), 3, 'refill: the rows of the image stay');
    is(scalar(grep { /$PH/ && !/^(?:$PH.{2}){4}$/ } @l), 0, 'refill: the rows are not folded');
}

# an image on GitHub of the repository of the file is the file in it
{
    my $repo = "$dir/repo";
    mkdir $repo; mkdir "$repo/images";
    png("$repo/images/b.png", 32, 34);
    system(qw(git -C), $repo, qw(init -q)) == 0 or plan skip_all => 'git is not available';
    system(qw(git -C), $repo, qw(remote add origin https://github.com/owner/repo.git)) == 0 or die;
    my $md = "$repo/README.md";
    open my $fh, '>', $md or die;
    print $fh join "\n",
	'![b](https://raw.githubusercontent.com/owner/repo/main/images/b.png)', '',
	'![c](https://github.com/owner/repo/blob/main/images/b.png?raw=true)', '',
	'![d](https://raw.githubusercontent.com/other/repo/main/images/b.png)', '',
	'![e](https://raw.githubusercontent.com/owner/repo/main/../../a.png)', '';
    close $fh;
    my $out = mdee_out("$base,$img", $md);
    is(scalar(() = $out =~ /$PH/g), 4, 'GitHub URLs of the repository: 2 images of 2 cells');
}

done_testing;
