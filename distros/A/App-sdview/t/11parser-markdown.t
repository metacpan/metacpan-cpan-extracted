#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use App::sdview::Parser::Markdown;

my $parser = App::sdview::Parser::Markdown->new;
isa_ok( $parser, [ "App::sdview::Parser::Markdown" ], '$parser' );

ok( App::sdview::Parser::Markdown->can_parse_file( "Example.md" ), 'Parser can handle .md file' );

subtest "Basic" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
# Heading

The heading paragraph here.

## Content

The content with **bold** and `code` in it.
EOMARKDOWN

   is( scalar @p, 4, 'Received 4 paragraphs' );

   is( $p[0]->type, "head1", 'p[0] type' );
   is( $p[0]->text, "Heading", 'p[0] text' );

   is( $p[1]->type, "plain", 'p[1] type' );
   is( $p[1]->text, "The heading paragraph here.", 'p[1] text' );

   is( $p[2]->type, "head2", 'p[2] type' );
   is( $p[2]->text, "Content", 'p[2] text' );

   is( $p[3]->type, "plain", 'p[3] type' );
   is( $p[3]->text, "The content with bold and code in it.", 'p[3] text' );
   is( [ sort $p[3]->text->tagnames ], [qw( bold monospace )], 'p[3] tags' );
};

subtest "Alternate headings" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
Heading
=======

The heading paragraph here.

Content
-------

The content with **bold** and `code` in it.
EOMARKDOWN

   is( scalar @p, 4, 'Received 4 paragraphs' );

   is( $p[0]->type, "head1", 'p[0] type' );
   is( $p[0]->text, "Heading", 'p[0] text' );

   is( $p[1]->type, "plain", 'p[1] type' );
   is( $p[1]->text, "The heading paragraph here.", 'p[1] text' );

   is( $p[2]->type, "head2", 'p[2] type' );
   is( $p[2]->text, "Content", 'p[2] text' );

   is( $p[3]->type, "plain", 'p[3] type' );
   is( $p[3]->text, "The content with bold and code in it.", 'p[3] text' );
};

subtest "Formatting" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
**bold** __bold__

*italic* _italic_

`code` `code_with_unders`

[link](target://)

~~strikethrough~~
EOMARKDOWN

   is( scalar @p, 5, 'Received 5 paragraphs' );

   is( $p[0]->text, "bold bold", 'bold text' );
   ok( $p[0]->text->get_tag_at( 0, "bold" ), 'bold tag' );

   is( $p[1]->text, "italic italic", 'italic text' );
   ok( $p[1]->text->get_tag_at( 0, "italic" ), 'italic tag' );

   is( $p[2]->text, "code code_with_unders", 'code text' );
   ok( $p[2]->text->get_tag_at( 0, "monospace" ), 'code tag' );

   is( $p[3]->text, "link", 'link text' );
   is( $p[3]->text->get_tag_at( 0, "link" ), { uri => "target://" }, 'link tag' );

   is( $p[4]->text, "strikethrough", 'strikethrough text' );
   ok( $p[4]->text->get_tag_at( 0, "strikethrough" ), 'strikethrough tag' );
};

subtest "HTML entities get decoded" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
Some content with non-breaking&nbsp;spaces in it.

Text &ndash; with HTML entities
EOMARKDOWN

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->type, "plain", 'p[0] type' );
   is( $p[0]->text, "Some content with non-breaking\xA0spaces in it.", 'p[0] text' );

   is( $p[1]->text, "Text \x{2013} with HTML entities", 'p[1] text' );
};

subtest "Verbatim language" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOPOD" );
# EXAMPLE

```perl
use v5.14;
use warnings;
say "Hello, world";
```

EOPOD

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->text, "EXAMPLE", 'p[0] text' );

   is( $p[1]->text, qq(use v5.14;\nuse warnings;\nsay "Hello, world";), 'p[1] text' );
   is( $p[1]->language, "perl", 'p[1] language' );
};

subtest "Verbatim trimming" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOPOD" );
# EXAMPLE

    use v5.14;
    use warnings;
    say "Hello, world";

EOPOD

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->text, "EXAMPLE", 'p[0] text' );

   is( $p[1]->text, qq(use v5.14;\nuse warnings;\nsay "Hello, world";), 'p[1] text' );
};

subtest "Bullet lists" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
* First
* Second

* Third
EOMARKDOWN

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-bullet", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );

   my @items = $p[0]->items;

   is( scalar @items, 3, '3 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->text, "First", 'items[0] text' );

   is( $items[1]->type, "item",   'items[1] type' );
   is( $items[1]->text, "Second", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->text, "Third", 'items[2] text' );
};

subtest "Numbered lists" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
1. First
2. Second

3. Third
EOMARKDOWN

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-number", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );
   is( $p[0]->initial, 1, 'p[0] initial' );

   my @items = $p[0]->items;

   is( scalar @items, 3, '3 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->text, "First", 'items[0] text' );

   is( $items[1]->type, "item",   'items[1] type' );
   is( $items[1]->text, "Second", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->text, "Third", 'items[2] text' );

   @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
4. Fourth
4. Fifth
EOMARKDOWN

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-number", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );
   is( $p[0]->initial, 4, 'p[0] initial' );
};

subtest "Table" => sub {
   my @p = App::sdview::Parser::Markdown->new->parse_string( <<"EOMARKDOWN" );
| Heading | Here |
|---------|------|
|Data in  |Columns|

| Left | Centre | Right |
| :--- |  :---: |  ---: |
EOMARKDOWN

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->type, "table", 'p[0] type' );

   my @rows = $p[0]->rows;

   is( scalar @rows, 2, 'table contains 2 rows' );

   my @cols = $rows[0]->@*;

   is( $cols[0]->type,  "table-cell", 'cells[0][0] type' );
   is( $cols[0]->text,  "Heading",    'cells[0][0] text' );
   is( $cols[0]->align, "left",       'cells[0][0] align' );

   is( $cols[1]->type, "table-cell", 'cells[0][1] type' );
   is( $cols[1]->text, "Here",       'cells[0][1] text' );

   @cols = $rows[1]->@*;

   is( $cols[0]->type, "table-cell", 'cells[1][0] type' );
   is( $cols[0]->text, "Data in",    'cells[1][0] text' );

   is( $cols[1]->type, "table-cell", 'cells[1][1] type' );
   is( $cols[1]->text, "Columns",    'cells[1][1] text' );

   @rows = $p[1]->rows;
   @cols = $rows[0]->@*;

   is( $cols[0]->text,  "Left",   'col[0] text' );
   is( $cols[0]->align, "left",   'col[0] align' );
   is( $cols[1]->text,  "Centre", 'col[1] text' );
   is( $cols[1]->align, "centre", 'col[1] align' );
   is( $cols[2]->text,  "Right",  'col[2] text' );
   is( $cols[2]->align, "right",  'col[2] align' );
};

done_testing;
