use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

# App::Greple::md::Blocks finds the paragraphs of a Markdown text with
# the CommonMark module or with pandoc.  Both must report the same
# lines, except for what libcmark does not know (definition lists).
use_ok('App::Greple::md::Blocks', qw(blocks available));

my @parsers = available();
@parsers or plan skip_all => 'neither the CommonMark module nor pandoc with sourcepos is available';
note "parsers: @parsers";

# [ name, text, paragraphs as "first-last/depth" ]
my @cases = (
    [ 'paragraph and rule',   "Text one\ntext two\n***\nafter\n",             [qw(1-2/0 4-4/0)] ],
    [ 'paragraph and fence',  "intro\n```\ncode\n```\n",                      [qw(1-1/0)] ],
    [ 'toml front matter',    "+++\ntitle = 1\n+++\n\npara\nmore\n",          [qw(1-3/0 5-6/0)] ],
    [ 'crlf',                 "a\r\nb\r\n\r\nc\r\n",                          [qw(1-2/0 4-4/0)] ],
    [ 'html block',           "<div>\nhtml\n</div>\n\npara\n",                [qw(5-5/0)] ],
    [ 'reference definition', "[ref]: http://x/\n\npara\n[a][ref]\n",         [qw(3-4/0)] ],
    [ 'list item, lazy line', "- item\n  cont\nlazy\n\n  para in item\n  two\n", [qw(1-3/0 5-6/0)] ],
    [ 'nested quotes',        "> q1\nq2\n> > deep\n> > more\n",               [qw(1-2/1 3-4/2)] ],
    [ 'setext heading',       "Setext\n=====\n\nx\ny\n",                      [qw(4-5/0)] ],
    [ 'heading and japanese', "# 見出し\n\n日本語の\n段落。\n",                [qw(3-4/0)] ],
);

for my $parser (@parsers) {
    for my $case (@cases) {
        my($name, $text, $want) = @$case;
        my @got = map { "$_->{first}-$_->{last}/$_->{depth}" }
                  grep { $_->{type} eq 'Para' or $_->{type} eq 'Plain' }
                  blocks($text, parser => $parser);
        is_deeply(\@got, $want, "$parser: $name");
    }
}

# Markdown::Perl is a required dependency, so mdperl is always there
ok((grep { $_ eq 'mdperl' } @parsers), 'mdperl is available');

# the default parser is the first available one
my @default = blocks("a\nb\n");
is(scalar @default, 1, 'default parser finds the paragraph');

eval { blocks("a\n", parser => 'foo') };
like($@, qr/foo/, 'an unknown parser dies');

done_testing;
