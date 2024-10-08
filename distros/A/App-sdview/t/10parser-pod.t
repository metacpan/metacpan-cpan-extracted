#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use App::sdview::Parser::Pod;

my $parser = App::sdview::Parser::Pod->new;
isa_ok( $parser, [ "App::sdview::Parser::Pod" ], '$parser' );

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
   is( [ sort $p[3]->text->tagnames ], [qw( bold monospace )], 'p[3] tags' );
};

subtest "Formatting" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=pod

B<bold> B<< bold >>

I<italic> I<< italic >>

C<code> C<< code->with->arrows >>

F<filename>

L<link|target://> L<Module::Here>

U<underline> U<< underline >>
EOPOD

   is( scalar @p, 6, 'Received 6 paragraphs' );

   is( $p[0]->text, "bold bold", 'bold text' );
   ok( $p[0]->text->get_tag_at( 0, "bold" ), 'bold tag' );

   is( $p[1]->text, "italic italic", 'italic text' );
   ok( $p[1]->text->get_tag_at( 0, "italic" ), 'italic tag' );

   is( $p[2]->text, "code code->with->arrows", 'code text' );
   ok( $p[2]->text->get_tag_at( 0, "monospace" ), 'code tag' );

   is( $p[3]->text, "filename", 'file text' );
   ok( $p[3]->text->get_tag_at( 0, "file" ), 'file tag' );

   is( $p[4]->text, "link Module::Here", 'link text' );
   is( $p[4]->text->get_tag_at( 0, "link" ), { uri => "target://" },
      'link tag' );
   is( $p[4]->text->get_tag_at( 5, "link" ), { uri => "https://metacpan.org/pod/Module::Here" },
      'link to metacpan' );

   is( $p[5]->text, "underline underline", 'underline text' );
   ok( $p[5]->text->get_tag_at( 0, "underline" ), 'underline tag' );
};

subtest "Formatted headings" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=head1 A B<Bold> Beginning
EOPOD

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "head1", 'p[0] type' );
   is( $p[0]->text, "A Bold Beginning", 'p[0] text' );
   is( [ sort $p[0]->text->tagnames ], [qw( bold )], 'p[0] tags' );
};

subtest "Non-breaking spaces" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=pod

Some content with S<non-breaking spaces> in it.
EOPOD

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "plain", 'p[0] type' );
   is( $p[0]->text, "Some content with non-breaking\xA0spaces in it.", 'p[0] text' );
};

subtest "Verbatim" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=head1 EXAMPLE

=for highlighter perl

   use v5.14;
   use warnings;
   say "Hello, world";

=for highlighter

   This should be plain text

=code perl

   perl

Z<>

   not perl
EOPOD

   is( scalar @p, 6, 'Received 6 paragraphs' );

   is( $p[0]->text, "EXAMPLE", 'p[0] text' );

   is( $p[1]->text, qq(use v5.14;\nuse warnings;\nsay "Hello, world";), 'p[1] text' );
   is( $p[1]->language, "perl", 'p[1] language' );

   is( $p[2]->text, qq(This should be plain text), 'p[2] text' );
   is( $p[2]->language, undef, 'p[2] language' );

   is( $p[3]->text, qq(perl), 'p[3] text' );
   is( $p[3]->language, "perl", 'p[3] language' );

   # p[4] is blank

   is( $p[5]->text, qq(not perl), 'p[5] text' );
   is( $p[5]->language, undef, 'p[5] language' );
};

subtest "Indented" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=over 4

This plain paragraph is indented

=back
EOPOD

   is( scalar @p, 1, 'Received 1 paragraphs' );

   is( $p[0]->type, "plain", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );
   is( $p[0]->text, "This plain paragraph is indented", 'p[0] text' );
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

=item Second I<item>

The second item

=item Third

The third item

Has two paragraphs

=back
EOPOD

   is( scalar @p, 1, 'Received 1 paragraph' );

   is( $p[0]->type, "list-text", 'p[0] type' );
   is( $p[0]->indent, 4, 'p[0] indent' );

   my @items = $p[0]->items;

   is( scalar @items, 4, '4 items' );

   is( $items[0]->type, "item",  'items[0] type' );
   is( $items[0]->term, "First", 'items[0] term' );
   is( $items[0]->text, "The first item", 'items[0] text' );

   is( $items[1]->type, "item",  'items[1] type' );
   is( $items[1]->term, "Second item", 'items[1] term' );
   is( [ $items[1]->term->tagnames ], [qw( italic )], 'items[1] term tags' );
   is( $items[1]->text, "The second item", 'items[1] text' );

   is( $items[2]->type, "item",  'items[2] type' );
   is( $items[2]->term, "Third", 'items[2] term' );
   is( $items[2]->text, "The third item", 'items[2] text' );

   is( $items[3]->type, "plain", 'items[3] type' );
   is( $items[3]->text, "Has two paragraphs", 'items[3] text' );
};

subtest "Verbatim syntax autodetect" => sub {
   foreach (
      [ perl => "use v5.14;\nsay 'Hello, world'" ],
      [ perl => "\$result = somefunc(1, 2, 3);" ],
      [ perl => "my \$result = somefunc(1, 2);" ],
      [ undef,  "This is not perl code" ],
   ) {
      my ( $want_lang, $src ) = @$_;

      $src =~ s/^/   /mg;

      my @p = App::sdview::Parser::Pod->new->parse_string( "=pod\n\n" . $src );

      is( scalar @p, 1, 'Received 1 paragraphs' );

      is( $p[0]->language, $want_lang,
         ( $want_lang // "undef" ) . " language autodetected" );
   }
};

subtest "Table" => sub {
   my @p = App::sdview::Parser::Pod->new->parse_string( <<"EOPOD" );
=begin table md

| Heading | Here |
|---------|------|
|Data in  |Columns|

=end table

=begin table md

| Left | Centre | Right |
| :--- |  :---: |  ---: |

=end table

=begin table md

Bold | B<123>
Italic | I<456>

=end table

=begin table mediawiki

! A1
! A2
|-
| B1
| B2
|-
| C1 || C2

=end table

EOPOD

   is( scalar @p, 4, 'Received 4 paragraphs' );

   is( $p[0]->type, "table", 'p[0] type' );

   my @rows = $p[0]->rows;

   is( scalar @rows, 2, 'table contains 2 rows' );

   my @cells = $rows[0]->@*;

   is( $cells[0]->type,  "table-cell", 'cells[0][0] type' );
   is( $cells[0]->text,  "Heading",    'cells[0][0] text' );
   is( $cells[0]->align, "left",       'cells[0][0] align' );
   ok( $cells[0]->heading,             'cells[0][0] heading' );

   is( $cells[1]->type, "table-cell", 'cells[0][1] type' );
   is( $cells[1]->text, "Here",       'cells[0][1] text' );

   @cells = $rows[1]->@*;

   is( $cells[0]->type, "table-cell", 'cells[1][0] type' );
   is( $cells[0]->text, "Data in",    'cells[1][0] text' );
   ok( !$cells[0]->heading,           'cells[1][0] heading' );

   is( $cells[1]->type, "table-cell", 'cells[1][1] type' );
   is( $cells[1]->text, "Columns",    'cells[1][1] text' );

   @rows = $p[1]->rows;
   @cells = $rows[0]->@*;

   is( $cells[0]->text,  "Left",   'col[0] text' );
   is( $cells[0]->align, "left",   'col[0] align' );
   is( $cells[1]->text,  "Centre", 'col[1] text' );
   is( $cells[1]->align, "centre", 'col[1] align' );
   is( $cells[2]->text,  "Right",  'col[2] text' );
   is( $cells[2]->align, "right",  'col[2] align' );

   @rows = $p[2]->rows;
   my @col1 = map { $_->[1] } @rows;

   is( $col1[0]->text,  "123",                     'col1[0] text' );
   is( [ $col1[0]->text->tagnames ], [qw( bold )], 'col1[0] text tags' );
   ok( !$col1[0]->heading,                         'col1[0] heading' );
   is( $col1[1]->text,  "456",                       'col1[1] text' );
   is( [ $col1[1]->text->tagnames ], [qw( italic )], 'col1[1] text tags' );

   @rows = $p[3]->rows;
   is( $rows[0][0]->text, "A1", 'mediawiki cell A1' );
   ok( $rows[0][0]->heading,    'mediawiki cell A1 is heading' );
   is( $rows[0][1]->text, "A2", 'mediawiki cell A2' );
   ok( $rows[0][1]->heading,    'mediawiki cell A2 is heading' );
   is( $rows[1][0]->text, "B1", 'mediawiki cell B1' );
   is( $rows[1][1]->text, "B2", 'mediawiki cell B2' );
   is( $rows[2][0]->text, "C1", 'mediawiki cell C1' );
   is( $rows[2][1]->text, "C2", 'mediawiki cell C2' );
};

done_testing;
