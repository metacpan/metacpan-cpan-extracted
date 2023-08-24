#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test2::V0;

use App::sdview::Parser::Markdown;
use App::sdview::Output::Markdown;

sub dotest ( $name, $in_md )
{
   my @p = App::sdview::Parser::Markdown->new->parse_string( $in_md );
   my $output = App::sdview::Output::Markdown->new;
   my $out_md = $output->generate( @p );

   is( $out_md, $in_md, "Generated Markdown for $name" );
}

dotest "Headings", <<"EOMARKDOWN";
# Heading

## Content

Contents here
EOMARKDOWN

dotest "Formatting", <<"EOMARKDOWN";
**bold**

*italic*

`code` `code_with_unders`

[link](target://)
EOMARKDOWN

dotest "Verbatim", <<"EOMARKDOWN";
# EXAMPLE

```
use v5.14;
use warnings;
say "Hello, world";
```
EOMARKDOWN

dotest "Bullet lists", <<"EOMARKDOWN";
* First
* Second
* Third
EOMARKDOWN

dotest "Bullet lists", <<"EOMARKDOWN";
1. First
2. Second
3. Third
EOMARKDOWN

dotest "Table", <<"EOMARKDOWN";
| Heading | Here |
| ------- | ---- |
| Data in | Columns |

| Left | Centre | Right |
| ---- | :----: | ----: |
EOMARKDOWN

done_testing;
