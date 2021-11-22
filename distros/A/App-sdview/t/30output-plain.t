#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;
use experimental 'signatures';

use Test::More;

# We don't have a "plain" input, but we can input from POD or Markdown and test
# that we get some expected output
use App::sdview::Parser::Pod;
use App::sdview::Parser::Markdown;
use App::sdview::Output::Plain;

sub dotest ( $name, $format, $in, $out_text )
{
   my $parserclass = "App::sdview::Parser::" . ucfirst($format);
   my @p = $parserclass->new->parse_string( $in );
   my $output = App::sdview::Output::Plain->new;
   my $text = $output->generate( @p );

   is( $text, $out_text, "Generated text for $name" ) or
      diag( sprintf "Got: %v02X\nExp: %v02X\n", $text, $out_text );
}

dotest "Headings", pod => <<"EOPOD",
=head1 Head1

=head2 Head2

Contents here
EOPOD
<<"EOF";
Head1
  Head2
      Contents here
EOF

dotest "Formatting", pod => <<"EOPOD",
=pod

B<bold> B<< <bold> >>

I<italic>

C<code> C<< code->with->arrows >>

L<link|target://> L<Module::Here>
EOPOD
<<"EOF";
      bold <bold>

      italic

      code code->with->arrows

      link Module::Here
EOF

dotest "Verbatim", pod => <<"EOPOD",
=head1 EXAMPLE

    use v5.14;
    use warnings;
    say "Hello, world";
EOPOD
<<"EOF";
EXAMPLE
        use v5.14;
        use warnings;
        say "Hello, world";
EOF

dotest "Bullet lists", pod => <<"EOPOD",
=over 4

=item *

First

=item *

Second

=item *

Third

=back
EOPOD
<<"EOF";
      •   First

      •   Second

      •   Third
EOF

dotest "Numbered lists", pod => <<"EOPOD",
=over 4

=item 1.

First

=item 2.

Second

=item 3.

Third

=back
EOPOD
<<"EOF";
      1.  First

      2.  Second

      3.  Third
EOF

dotest "Definition lists", pod => <<"EOPOD",
=over 4

=item First

The first item

=item Second

The second item

=item Third

The third item

=back
EOPOD
<<"EOF";
      First
          The first item

      Second
          The second item

      Third
          The third item
EOF

dotest "Nested lists", pod => <<"EOPOD",
=over 4

=item *

Item

=over 4

=item *

Inner item

=back

=back
EOPOD
<<"EOF";
      •   Item

            •   Inner item
EOF

dotest "Tables", markdown => <<"EOMARKDOWN",
| Heading | Here |
|---------|------|
|Data in  |Columns|

| Left | Centre | Right |
| :--- |  :---: |  ---: |
| XX   |   XX   |    XX |
EOMARKDOWN
<<"EOF";
        ┌─────────┬─────────┐
        │ Heading │ Here    │
        ├─────────┼─────────┤
        │ Data in │ Columns │
        └─────────┴─────────┘
        ┌──────┬────────┬───────┐
        │ Left │ Centre │ Right │
        ├──────┼────────┼───────┤
        │ XX   │   XX   │    XX │
        └──────┴────────┴───────┘
EOF

done_testing;
