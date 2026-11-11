use strict;
use warnings;
use Test::More;
use open qw(:std :encoding(utf-8));
use File::Temp qw(tempfile);

use lib '.';
use t::Util;

# Front matter at the top of the file is shown as a code block: the
# body in meta_block, the delimiter lines in meta_mark, with no other
# markup.  The colors are replaced by marks to see which
# label each line gets.

sub md_file {
    my($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    print $fh shift;
    close $fh;
    $file;
}

my $marks = join ' ',
    q(--cm 'code_mark=sub{"<M:$_>"}'),
    q(--cm 'code_block=sub{"<B:$_>"}'),
    q(--cm 'horizontal_rule=sub{"<R:$_>"}'),
    q(--cm 'meta_mark=sub{"<MM:$_>"}'),
    q(--cm 'meta_block=sub{"<MB:$_>"}');

sub show {
    my($text, $config) = @_;
    my $opt = $config ? "'-Mmd::config($config)'" : '-Mmd';
    my $out = run("$opt $marks -- " . md_file($text))->stdout;
    $out =~ s/\e\[[\d;]*[mK]//g;
    $out;
}

is(show("---\ntitle: **x**\ntags:\n  - a\n---\n\n# Head\n"),
   "<MM:--->\n<MB:title: **x**\n><MB:tags:\n><MB:  - a\n><MM:--->\n\n# Head\n",
   'YAML front matter is a code block, without other markup');

is(show("---\ntitle: x\n...\ntext\n"),
   "<MM:--->\n<MB:title: x\n><MM:...>\ntext\n",
   'YAML front matter may end with ...');

is(show("+++\ntitle = \"x\"\n+++\n"),
   "<MM:+++>\n<MB:title = \"x\"\n><MM:+++>\n",
   'TOML front matter is a code block');

is(show("---\n\ntext\n\n---\n"),
   "<R:--->\n\ntext\n\n<R:--->\n",
   'a blank line after the first --- makes it a rule');

is(show("text\n\n---\ntitle: x\n---\n"),
   "text\n\n<R:--->\ntitle: x\n<R:--->\n",
   'front matter is only at the top');

is(show("---\ntitle: x\n---\n", 'front_matter=0'),
   "<R:--->\ntitle: x\n<R:--->\n",
   'front_matter=0 takes the lines as Markdown');

# meta_mark and meta_block color the front matter alone; when they
# are emptied it has the colors of code_block, with code_mark inside
# it on the delimiter lines
{
    my $text = "---\ntitle: x\n---\n\n```\ncode\n```\n";
    is(show($text),
       "<MM:--->\n<MB:title: x\n><MM:--->\n\n<M:```>\n<B:code\n><M:```>\n",
       'meta_mark and meta_block are for the front matter only');
    my $out = run(join ' ', "'-Mmd::config(meta_mark=,meta_block=)'",
                  $marks =~ s/ --cm 'meta_\w+=[^']*'//gr,
                  '--', md_file($text))->stdout;
    $out =~ s/\e\[[\d;]*[mK]//g;
    is($out,
       "<B:<M:--->>\n<B:title: x\n><B:<M:--->>\n\n<M:```>\n<B:code\n><M:```>\n",
       'without meta_mark and meta_block, code_mark inside code_block');
}

# A long line in the front matter is not folded, as a list item would be
my $long = join ' ', ('word') x 30;
my $folded = run("'-Mmd::config(fold=1,fold_width=40)' -- "
                 . md_file("---\ntags:\n  - $long\n---\n\n- $long\n"))->stdout;
$folded =~ s/\e\[[\d;]*[mK]//g;
like($folded, qr/^  - \Q$long\E$/m, 'a list item in the front matter is not folded');
unlike($folded, qr/^- \Q$long\E$/m, 'a list item below it is folded');

done_testing;
