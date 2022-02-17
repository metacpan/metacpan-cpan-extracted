#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use App::sdview::Parser::Man;

my $parser = App::sdview::Parser::Man->new;
isa_ok( $parser, "App::sdview::Parser::Man", '$parser' );

ok( App::sdview::Parser::Man->can_parse_file( "Example.3" ),  'Parser can handle .3 file' );
ok( App::sdview::Parser::Man->can_parse_file( "Example.3.gz" ), 'Parser can handle .3.gz file' );

subtest "Basic" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
.SH Heading
The heading paragraph here.
.SS Content
The content with \\fBbold\\fP and \\f(CWcode\\fP in it.
EOMAN

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

subtest "Formatting" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
.PP
.B bold
\\fBbold\\fP
.PP
.I italic
\\fIitalic\\fP
.PP
\\f(CWcode->with->arrows\\fP
EOMAN

   is( scalar @p, 3, 'Received 3 paragraphs' );

   is( $p[0]->text, "bold bold", 'bold text' );
   ok( $p[0]->text->get_tag_at( 0, "B" ), 'bold tag' );

   is( $p[1]->text, "italic italic", 'italic text' );
   ok( $p[1]->text->get_tag_at( 0, "I" ), 'italic tag' );

   is( $p[2]->text, "code->with->arrows", 'code text' );
   ok( $p[2]->text->get_tag_at( 0, "C" ), 'code tag' );
};

subtest "Verbatim trimming" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
EXAMPLE
.EX
use v5.14;
use warnings;
say "Hello, world";
.EE
EOMAN

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->text, "EXAMPLE", 'p[0] text' );

   is( $p[1]->text, qq(use v5.14;\nuse warnings;\nsay "Hello, world";), 'p[1] text' );
};

subtest "Indented" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
.RS 4
This plain paragraph is indented
.RE
EOMAN

   is( scalar @p, 1, 'Received 1 paragraphs' );

   is( $p[0]->type, "plain", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );
   is( $p[0]->text, "This plain paragraph is indented", 'p[0] text' );
};

subtest "Bullet lists" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
.IP \\(bu 4
First
.IP \\(bu
Second
.IP \\(bu 4
Third
EOMAN

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
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
=over 4

=item 1.

First

=item 2.

Second

=item 3.

Third

=back
EOMAN

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
} if 0; # TODO: nroff/man doesn't really define a way to do numbered lists

subtest "Definition lists" => sub {
   my @p = App::sdview::Parser::Man->new->parse_string( <<"EOMAN" );
.TP
First
The first item
.TP
Second
The second item
.TP
Third
The third item
.IP
Has two paragraphs
EOMAN

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-text", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );

   my @items = $p[0]->items;

   is( scalar @items, 4, '4 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->term, "First", 'items[0] term' );
   is( $items[0]->text, "The first item", 'items[0] text' );

   is( $items[1]->type, "item",  'items[1] type' );
   is( $items[1]->term, "Second", 'items[1] term' );
   is( $items[1]->text, "The second item", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->term, "Third", 'items[2] term' );
   is( $items[2]->text, "The third item", 'items[2] text' );

   is( $items[3]->type, "plain", 'items[3] type' );
   is( $items[3]->text, "Has two paragraphs", 'items[3] text' );
};

done_testing;
