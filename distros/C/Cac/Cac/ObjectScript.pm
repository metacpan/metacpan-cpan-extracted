package Cac::ObjectScript;

use 5.006;
use strict;
use warnings;
use bytes;
  
use XSLoader;
XSLoader::load Cac unless $Cac::xs_loaded++; # this is in cacperl.xs :)

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = ( );
our @EXPORT = qw();
our $VERSION = 1.83;

use Filter::Simple ();
use Digest::MD5 "md5_hex";
use Cac::Global;
use Cac::Routine;
use Cac::Util;


# this is a political statement :)
sub michael_moore_for_president($$) {
   my ($expr,$type) = @_;
   my %bind;
   my @bind;
   my $md5 = md5_hex "$VERSION$expr"; # API may change, so we force recompile on version change
   my $rtn = substr "CPERL$md5", 0, 30;

   for(;;) {
      last unless $expr =~ m/\G[^:]*:([a-zA-Z][a-zA-Z0-9]*)/gx;
      push @bind, $1 unless $bind{$1}++;
   }
   
   unless(defined Gget "rOBJ", $rtn) {
      # ok, we need to generate COS this can be slow - make sure that at least we are fast :)
      my @lines;
      my $ni = $expr;
      my $code;
      $ni =~ s/\n/\\n/g;
      push @lines, "$rtn ; automagically generated by " . __PACKAGE__ . " $VERSION",
                   " ;      MD5: $md5",
                   " ;     Type: ".($type eq ":" ? "Statement" : "Expression"),
                   " ;    Input: \"$ni\"",
                   " Q";
      for my $i (0..$#bind) {
        $expr =~ s/\s*:$bind[$i]\s*/b$i/gx;
      }
      
      if($type eq '?') {
         # it's an expression
         $code = "Q ($expr)";
      } else {
         # it's a statement
         $code = "$expr  Q 0";
      }
      push @lines, "CODE(".join(",", map { "b$_" } (0..$#bind)).") $code";

      compileMAC($rtn, @lines);
   }
   return " +(&Cac::Routine::Call(".join(",", "'CODE'", "'$rtn'", map { "\$$_" } @bind)."))".($type eq ':' ? ";" : "");
}



Filter::Simple::FILTER sub { 
                              $_ =~ s/<([?:])\s*(.*?)\s*:>/michael_moore_for_president $2, $1/ge;
                           };


=head1 NAME

Cac::ObjectScript - Source Filter for embedding ObjectScript expressions in Perl

=head1 SYNOPSIS

 use Cac::ObjectScript;
 my $a = 1;
 $a = <? :a +1:>:
 <:K ^foobar(:a):>
 no Cac::ObjectScript; # disable source filter

=head1 DESCRIPTION
 
This module allows you to embed ObjectScript expressions
enclosed in "<?" ...  ":>" or ObjectScript statements in "<:" ... ":>"

The expressions are not evaluated, they are compiled into ObjectScript
functions for everlasting speed.

You can use bind variables using C<:var > notation.

Generated routines are named C<CPERLxxxxxxxxxxxxxxxxxxxxxxxxx>
where each C<x> stands for a hexadecimal digit.

This is currently the md5sum (except last 7 digits) over the version
of this module and the expression. 

Anyway this may change (do not rely on that :), but I gurarantee that I only
generate routines named "CPERL*".

If you just want to evaluate a Cache-String (i.e: a non constant expression)
use C<CacEval $string> of the C<Cac> package.

You could also the following instead:

 my $eval = "K GeorgeBush"; # this is a political statement :)
 <: @:eval:>

but it doesn't look so fine :)
If you got this, you've probably understand that module.

If you insist to write order-loops, try something like this:

 my $a="";
 do {
      $a = <?$order(^rOBJ(:a)):>;
      print "$a\n";
    } while length $a;

=head1 EXPORTS

 none.

=head1 BUGS

 Design: This Module creates a routine for every <[:?] ...  :> expression.
         It should create a single routine for each Perl source file.
         (The current design "eats" routine-buffers)
         I'm going to change that but that's not too high on my priority list.
         (Finding a girlfriend is :)

=head1 SEE ALSO

L<Cac>, L<Cac::Global>, L<Cac::Routine>, L<Cac::Util>, L<Cac::Bind>.

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>
 http://hello-penguin.com

=cut

1;
__END__
