# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use lib 't/lib';
use App::rlibperl::Tester;
use Test::More;

plan tests => 1;

{
  my $tree = named_tree( 'parent' );

  # this can't be portable...
  my $out = qx!perl -e "print qq[foo\$/bar\$/]" | $tree->{rlibperl} -pe "tr/aeiou/AEIOU/"!;

  is $out, "fOO$/bAr$/", 'STDIN piped transparently';
}
