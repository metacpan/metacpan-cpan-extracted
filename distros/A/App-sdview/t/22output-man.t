#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test::More;

use App::sdview::Parser::Man;
use App::sdview::Output::Man;

sub dotest ( $name, $in_man )
{
   my @p = App::sdview::Parser::Man->new->parse_string( $in_man );
   my $output = App::sdview::Output::Man->new;
   my $out_man = $output->generate( @p );

   is( $out_man, $in_man, "Generated man for $name" );
}

dotest "Headings", <<"EOMAN";
.SH Head1
.SS Head2
Contents here
EOMAN

dotest "Formatting", <<"EOMAN";
.PP
\\fBbold\\fP
.PP
\\fIitalic\\fP
.PP
\\f(CWcode\\->with\\->arrows\\fP
EOMAN

dotest "Verbatim", <<"EOMAN";
.SH EXAMPLE
.EX
use v5.14;
use warnings;
say "Hello, world";
.EE
EOMAN

dotest "Bullet lists", <<"EOMAN";
.IP \\(bu
First
.IP \\(bu
Second
.IP \\(bu
Third
EOMAN

0 and # TODO: nroff/man doesn't really define a way to do numbered lists
dotest "Numbered lists", <<"EOMAN";
=over 4

=item 1.

First

=item 2.

Second

=item 3.

Third

=back
EOMAN

dotest "Definition lists", <<"EOMAN";
.TP
First
The first item
.TP
=item Second
The second item
.TP
=item Third
The third item
.IP
Has two paragraphs
EOMAN

done_testing;
