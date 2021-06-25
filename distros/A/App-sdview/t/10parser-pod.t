#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use App::sdview::Parser::Pod;

my $parser = App::sdview::Parser::Pod->new;
isa_ok( $parser, "App::sdview::Parser::Pod", '$parser' );

ok( App::sdview::Parser::Pod->can_parse_file( "Example.pm" ),  'Parser can handle .pm file' );
ok( App::sdview::Parser::Pod->can_parse_file( "Example.pod" ), 'Parser can handle .pod file' );

subtest "Basic" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=head1 Heading

The heading paragraph here.

=head2 Content

The content with B<bold> and C<code> in it.

EOPOD

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
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=pod

B<bold> B<< bold >>

I<italic> I<< italic >>

C<code> C<< code->with->arrows >>

L<link|target://>
EOPOD

   is( scalar @p, 4, 'Received 4 paragraphs' );

   is( $p[0]->text, "bold bold", 'bold text' );
   ok( $p[0]->text->get_tag_at( 0, "B" ), 'bold tag' );

   is( $p[1]->text, "italic italic", 'italic text' );
   ok( $p[1]->text->get_tag_at( 0, "I" ), 'italic tag' );

   is( $p[2]->text, "code code->with->arrows", 'code text' );
   ok( $p[2]->text->get_tag_at( 0, "C" ), 'code tag' );

   is( $p[3]->text, "link", 'link text' );
   is_deeply( $p[3]->text->get_tag_at( 0, "L" ), { target => "target://" }, 'link tag' );
};

subtest "Verbatim trimming" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=head1 EXAMPLE

   use v5.14;
   use warnings;
   say "Hello, world";

EOPOD

   is( scalar @p, 2, 'Received 2 paragraphs' );

   is( $p[0]->text, "EXAMPLE", 'p[0] text' );

   is( $p[1]->text, qq(use v5.14;\nuse warnings;\nsay "Hello, world";), 'p[1] text' );
};

subtest "Bullet lists" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=over 4

=item *

First

=item *

Second

=item *

Third

=back
EOPOD

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
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=over 4

=item 1.

First

=item 2.

Second

=item 3.

Third

=back
EOPOD

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

subtest "Definition lists" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=over 4

=item First

The first item

=item Second

The second item

=item Third

The third item

=back
EOPOD

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-text", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );

   my @items = $p[0]->items;

   is( scalar @items, 6, '6 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->text, "First", 'items[0] text' );

   is( $items[1]->type, "plain", 'items[1] type' );
   is( $items[1]->text, "The first item", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->text, "Second", 'items[2] text' );

   is( $items[3]->type, "plain", 'items[3] type' );
   is( $items[3]->text, "The second item", 'items[3] text' );

   is( $items[4]->type, "item",  'items[4] type' );
   is( $items[4]->text, "Third", 'items[4] text' );

   is( $items[5]->type, "plain", 'items[5] type' );
   is( $items[5]->text, "The third item", 'items[5] text' );
};

done_testing;
