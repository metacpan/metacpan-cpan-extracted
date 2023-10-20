#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

my $cpppp= CodeGen::Cpppp->new;

my @tests= (
   {  name => "basic substitutions",
      code => unindent(<<'C'),
      void Example$foo {
         int i= ${{ 1+1 }};
      }
C
      expect => {
         subst => [
            { pos => 12, len => 4, line => 1 },
            { pos => 29, len => 10, line => 2 },
         ],
      }
   },
   {  name => "basic column",
      code => unindent(<<'C'),
      int     x;
      $el_t*  y;
C
      expect => {
         subst => [
            { pos =>  8, len => 0, colgroup => 80001, follows_eval => F, line => 1 },
            { pos => 11, len => 5, line => 2 },
            { pos => 19, len => 0, colgroup => 80001, follows_eval => T, line => 2 },
         ],
      }
   }
);

for (@tests) {
   my $parsed= $cpppp->_parse_code_block($_->{code});
   like( $parsed, $_->{expect}, $_->{name} )
      or note explain($parsed);
}

done_testing;
