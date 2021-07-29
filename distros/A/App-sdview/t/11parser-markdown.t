#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use App::sdview::Parser::Markdown;

my $parser = App::sdview::Parser::Markdown->new;
isa_ok( $parser, "App::sdview::Parser::Markdown", '$parser' );

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
   is_deeply( [ sort $p[3]->text->tagnames ], [qw( B C )], 'p[3] tags' );
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
EOMARKDOWN

   is( scalar @p, 4, 'Received 4 paragraphs' );

   is( $p[0]->text, "bold bold", 'bold text' );
   ok( $p[0]->text->get_tag_at( 0, "B" ), 'bold tag' );

   is( $p[1]->text, "italic italic", 'italic text' );
   ok( $p[1]->text->get_tag_at( 0, "I" ), 'italic tag' );

   is( $p[2]->text, "code code_with_unders", 'code text' );
   ok( $p[2]->text->get_tag_at( 0, "C" ), 'code tag' );

   is( $p[3]->text, "link", 'link text' );
   is_deeply( $p[3]->text->get_tag_at( 0, "L" ), { target => "target://" }, 'link tag' );
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

   my @items = $p[0]->items;

   is( scalar @items, 3, '3 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->text, "First", 'items[0] text' );

   is( $items[1]->type, "item",   'items[1] type' );
   is( $items[1]->text, "Second", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->text, "Third", 'items[2] text' );
};

done_testing;
