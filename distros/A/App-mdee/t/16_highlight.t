use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));
use File::Temp qw(tempfile tempdir);
use File::Path qw(make_path);

BEGIN {
    eval { require Text::ANSI::Highlight; 1 }
        or plan skip_all => 'Text::ANSI::Highlight is not installed';
}

use lib '.';
use t::Util;

# The code in a fenced code block is shown in the colors of its
# language, by a highlighter of Text::ANSI::Highlight.  Here the
# highlighters are modules made for the test, found before the real
# ones: they know the languages c and perl, and put a color on each
# line, 31 by pandoc and 32 by sourcehighlight.
my $dir = tempdir(CLEANUP => 1);
{
    my $path = "$dir/lib/Text/ANSI/Highlight";
    make_path($path);
    for (['pandoc', 31], ['sourcehighlight', 32]) {
        my($name, $color) = @$_;
        open my $fh, '>', "$path/$name.pm" or die;
        print $fh <<"END";
package Text::ANSI::Highlight::$name;
sub language { \$_[0] =~ /^(?:c|perl)\$/ ? \$_[0] : undef }
sub markdown { 0 }
sub highlight { map { \$_->[1] =~ s/^(.+)\$/\\e[${color}m\$1\\e[0m/mgr } \@_ }
1;
END
        close $fh;
    }
    $ENV{PERL5LIB} = join ':', "$dir/lib", $ENV{PERL5LIB} // ();
}

sub md_file {
    my($fh, $file) = tempfile(SUFFIX => '.md', UNLINK => 1);
    print $fh shift;
    close $fh;
    $file;
}

# The colors of the md module are replaced by marks, to see which label
# each line gets; the colors of the highlighter are left, as ^[
my $marks = join ' ',
    q(--cm 'code_mark=sub{"<M:$_>"}'),
    q(--cm 'code_info=sub{"<I:$_>"}'),
    q(--cm 'code_block=sub{"<B:$_>"}');

sub show {
    my($text, $config) = @_;
    my $opt = $config ? "'-Mmd::config($config)'" : '-Mmd';
    my $out = run("$opt $marks -- " . md_file($text))->stdout;
    $out =~ s/\e\[K//g;
    $out =~ s/\e/^[/g;
    $out;
}

my $md = "```c\nint x;\n\nint y;\n```\n";

is(show($md),
   "<M:```><I:c>\n<B:^[[31mint x;^[[0m\n><B:\n><B:^[[31mint y;^[[0m\n><M:```>\n",
   'the code is in the colors of the highlighter, inside the code block');

is(show("```\nint x;\n```\n"), "<M:```>\n<B:int x;\n><M:```>\n",
   'no language: as it is');
is(show("```nosuchlanguage\nfoo\n```\n"), "<M:```><I:nosuchlanguage>\n<B:foo\n><M:```>\n",
   'a language which is not known: as it is');
is(show("```c\n```\n"), "<M:```><I:c>\n<M:```>\n", 'an empty block');

is(show("```c title=\"a.c\"\nint x;\n```\n"),
   "<M:```><I:c title=\"a.c\">\n<B:^[[31mint x;^[[0m\n><M:```>\n",
   'the language is the first word after the fence');

is(show("~~~perl\nmy \$x;\n~~~\n\ntext\n\n```c\nint x;\n```\n\n```\nplain\n```\n"),
   "<M:~~~><I:perl>\n<B:^[[31mmy \$x;^[[0m\n><M:~~~>\n\ntext\n\n"
   . "<M:```><I:c>\n<B:^[[31mint x;^[[0m\n><M:```>\n\n<M:```>\n<B:plain\n><M:```>\n",
   'blocks: each by its language, and the text between them as it was');

is(show("   ````c\n   int x; // ```\n   ````\n"),
   "<M:   ````><I:c>\n<B:^[[31m   int x; // ```^[[0m\n><M:   ````>\n",
   'a longer fence with an indent');

is(show("```c\nint x = \"日本語\";\n```\n"),
   "<M:```><I:c>\n<B:^[[31mint x = \"日本語\";^[[0m\n><M:```>\n",
   'wide characters');

# config: highlight
is(show($md, 'highlight=0'), "<M:```><I:c>\n<B:int x;\n><B:\n><B:int y;\n><M:```>\n",
   'highlight=0: as it is');
is(show($md, 'highlight=sourcehighlight'),
   "<M:```><I:c>\n<B:^[[32mint x;^[[0m\n><B:\n><B:^[[32mint y;^[[0m\n><M:```>\n",
   'highlight=sourcehighlight');
like(show($md, 'highlight=gnu'), qr/\Q<B:^[[32mint x;^[[0m\E/, 'highlight=gnu, the short name');
like(show($md, 'highlight=pandoc'), qr/\Q<B:^[[31mint x;^[[0m\E/, 'highlight=pandoc');
is(show($md, 'highlight=nosuchhighlighter'), "<M:```><I:c>\n<B:int x;\n><B:\n><B:int y;\n><M:```>\n",
   'a highlighter which is not there: as it is');

# The background of the code block goes on after the resets of the
# highlighter
{
    my $out = run("-Mmd -- " . md_file("```c\nint x;\n```\n"))->stdout;
    my($line) = $out =~ /^(.*int x;.*)$/m;
    like $line, qr/\e\[31mint x;\e\[0m/, 'real colors: the color of the highlighter';
    like $line, qr/\A\e\[48;[\d;]+m/, 'real colors: the background at the top of the line';
    (my $plain = $out) =~ s/\e\[[\d;]*[mK]//g;
    is $plain, "```c\nint x;\n```\n", 'real colors: the text is the same';
}

done_testing;
