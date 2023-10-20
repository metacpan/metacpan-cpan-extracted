#!/usr/bin/perl

use v5.26;
use warnings;
use utf8;
use experimental 'signatures';

use Test2::V0;

# We don't have a "HTML" input, but we can input from POD or Markdown and test
# that we get some expected output
use App::sdview::Parser::Pod 0.13;
use App::sdview::Parser::Markdown 0.13;
use App::sdview::Output::HTML;

sub dotest ( $name, $format, $in, $out_html )
{
   my $parserclass = "App::sdview::Parser::" . ucfirst($format);
   my @p = $parserclass->new->parse_string( $in );
   my $output = App::sdview::Output::HTML->new;
   my $html = $output->generate( @p );

   is( $html, $out_html, "Generated HTML for $name" );
}

dotest "Headings", pod => <<"EOPOD",
=head1 Head1

=head2 Head2

Contents here
EOPOD
<<"EOHTML";
<h1>Head1</h1>
<h2>Head2</h2>
<p>Contents here</p>
EOHTML

dotest "Formatting (from Pod)", pod => <<"EOPOD",
=pod

B<bold> B<< <bold> >>

I<italic>

C<code> C<< code->with->arrows >>

L<link|target://> L<Module::Here>

U<underline>
EOPOD
<<"EOHTML";
<p><strong>bold</strong> <strong>&lt;bold&gt;</strong></p>
<p><em>italic</em></p>
<p><tt>code</tt> <tt>code-&gt;with-&gt;arrows</tt></p>
<p><a href="target://">link</a> <a href="https://metacpan.org/pod/Module::Here">Module::Here</a></p>
<p><u>underline</u></p>
EOHTML

# POD can't do strikethrough so we'll ask Markdown
dotest "Formatting (from Markdown)", markdown => <<"EOMARKDOWN",
~~strikethrough~~
EOMARKDOWN
<<"EOHTML";
<p><s>strikethrough</s></p>
EOHTML

dotest "Verbatim", pod => <<"EOPOD",
=head1 EXAMPLE

    use v5.14;
    use warnings;
    say "Hello, world";
EOPOD
<<"EOHTML";
<h1>EXAMPLE</h1>
<pre>
use v5.14;
use warnings;
say &quot;Hello, world&quot;;</pre>
EOHTML

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
<<"EOHTML";
<ul>
  <li>First</li>
  <li>Second</li>
  <li>Third</li>
</ul>
EOHTML

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
<<"EOHTML";
<ol>
  <li>First</li>
  <li>Second</li>
  <li>Third</li>
</ol>
EOHTML

dotest "Definition lists", pod => <<"EOPOD",
=over 4

=item First

The first item

=item Second

The second item

=item Third

The third item

Has two paragraphs

=back
EOPOD
<<"EOHTML";
<dl>
  <dt>First</dt>
  <dd>The first item</dd>
  <dt>Second</dt>
  <dd>The second item</dd>
  <dt>Third</dt>
  <dd>The third item</dd>
  <p>Has two paragraphs</p>
</dl>
EOHTML

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
<<"EOHTML";
<ul>
  <li>Item</li>
  <ul>
    <li>Inner item</li>
  </ul>
</ul>
EOHTML

dotest "Tables", markdown => <<"EOMARKDOWN",
| Heading | Here |
|---------|------|
|Data in  |Columns|

| Left | Centre | Right |
| :--- |  :---: |  ---: |
| XX   |   XX   |    XX |
EOMARKDOWN
<<"EOHTML";
<table>
  <tr>
    <th>Heading</th>
    <th>Here</th>
  </tr>
  <tr>
    <td>Data in</td>
    <td>Columns</td>
  </tr>
</table>
<table>
  <tr>
    <th>Left</th>
    <th style="text-align: center;">Centre</th>
    <th style="text-align: right;">Right</th>
  </tr>
  <tr>
    <td>XX</td>
    <td style="text-align: center;">XX</td>
    <td style="text-align: right;">XX</td>
  </tr>
</table>
EOHTML

done_testing;
