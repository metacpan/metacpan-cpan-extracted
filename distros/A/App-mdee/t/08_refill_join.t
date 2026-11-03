use strict;
use warnings;
use utf8;
use Test::More;
use open qw(:std :encoding(utf-8));

# Unit tests for refill_block: joins the lines of one paragraph the way
# ansifold's fill_up does, keeping the break after a hard break and
# before a list marker, horizontal rule or footnote definition line.
use_ok('App::Greple::md');

sub refill_block { App::Greple::md::refill_block(@_) }

my @cases = (
    [ 'plain lines',          [ 'para line one', 'para line two' ], 0,
                              [ 'para line one para line two' ] ],
    [ 'trailing single space', [ 'ends with space ', 'next' ], 0,
                              [ 'ends with space next' ] ],
    [ 'spaces inside the line', [ 'a  b', 'c' ], 0,
                              [ 'a  b c' ] ],
    [ 'many spaces inside the line', [ 'a' . (' ' x 5000) . 'b', 'c' ], 0,
                              [ 'a' . (' ' x 5000) . 'b c' ] ],
    [ 'hard break (spaces)',  [ 'hard  ', 'kept', 'joined' ], 0,
                              [ 'hard  ', 'kept joined' ] ],
    [ 'hard break (backslash)', [ 'back\\', 'kept' ], 0,
                              [ 'back\\', 'kept' ] ],
    [ 'escaped backslash at the end is not a break', [ 'lit \\\\', 'joined' ], 0,
                              [ 'lit \\\\ joined' ] ],
    [ 'three backslashes end with a break', [ 'lit \\\\\\', 'kept' ], 0,
                              [ 'lit \\\\\\', 'kept' ] ],
    [ 'japanese',             [ '日本語の', '段落。', '続き' ], 0,
                              [ '日本語の段落。続き' ] ],
    [ 'english and japanese', [ 'English and', '日本語' ], 0,
                              [ 'English and 日本語' ] ],
    [ 'list item with lazy line', [ '- item one', '  continued', 'lazy' ], 0,
                              [ '- item one continued lazy' ] ],
    [ 'blockquote depth 1',   [ '> quote a', '> quote b', 'lazy' ], 1,
                              [ '> quote a quote b lazy' ] ],
    [ 'blockquote depth 2',   [ '> > deep a', '> > deep b' ], 2,
                              [ '> > deep a deep b' ] ],
    [ 'pandoc #. list',       [ '#. auto one', '   cont', '#. auto two' ], 0,
                              [ '#. auto one cont', '#. auto two' ] ],
    [ 'horizontal rule',      [ 'Text', '***' ], 0,
                              [ 'Text', '***' ] ],
    [ 'table rows',           [ 'before table', '| C | D |', '|---|---|', '| 3 | 4 |' ], 0,
                              [ 'before table', '| C | D |', '|---|---|', '| 3 | 4 |' ] ],
    [ 'line after table rows', [ '| C | D |', '|---|---|', '| 3 | 4 |', 'after table' ], 0,
                              [ '| C | D |', '|---|---|', '| 3 | 4 |', 'after table' ] ],
    [ 'crlf lines',           [ "crlf a\r", "crlf b\r" ], 0,
                              [ "crlf a crlf b\r" ] ],
    [ 'crlf hard break',      [ "hard  \r", "kept\r" ], 0,
                              [ "hard  \r", "kept\r" ] ],
    [ 'definition list',      [ 'Term', ': def a', 'def b', ': def c' ], 0,
                              [ 'Term', ': def a def b', ': def c' ] ],
    [ 'footnote definitions', [ '[^a]: note a', '[^b-1]: note b', 'more b' ], 0,
                              [ '[^a]: note a', '[^b-1]: note b more b' ] ],
    [ 'footnote after text',  [ 'text', '[^a]: note a' ], 0,
                              [ 'text', '[^a]: note a' ] ],
    [ 'footnote definitions in a quote', [ '> [^a]: note a', '> [^b]: note b' ], 1,
                              [ '> [^a]: note a', '> [^b]: note b' ] ],
    [ 'footnote reference at the start of a line', [ 'text', '[^a] and more' ], 0,
                              [ 'text [^a] and more' ] ],
    [ 'link text at the start of a line', [ 'text', '[a]: not a footnote' ], 0,
                              [ 'text [a]: not a footnote' ] ],
);

for my $case (@cases) {
    my($name, $lines, $depth, $want) = @$case;
    my @got = refill_block([ @$lines ], $depth);
    is_deeply(\@got, $want, $name);
}

done_testing;
