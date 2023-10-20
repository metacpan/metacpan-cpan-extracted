#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use v5.20;

use CodeGen::Cpppp::AntiCharacter;

my $anticomma= CodeGen::Cpppp::AntiCharacter->new(qr/,/, qr/\s*/);
my $antispace= CodeGen::Cpppp::AntiCharacter->new(qr/\s*/);
for (
   [ ','                     , $anticomma => '' ],
   [ ', '                    , $anticomma => ' ' ],
   [ ",\n\t"                 , $anticomma => "\n\t" ],
   [ "\n,\n,\n,\n"           , $anticomma => "\n,\n,\n\n" ],
   [ ",", ", ", " \n"        , $anticomma => ",  \n" ],
   [ "foo\n"                 , $antispace => "foo" ],
   [ "foo\n    "             , $antispace => "foo" ],
   [ "foo", ";\n", "\n   \n" , $antispace => "foo;" ],
) {
   my ($result, $anti, @steps)= reverse @$_;
   my $x= $anti;
   $x= $_ . $x for @steps;
   is( $x, $_->[-1] );
}

done_testing;
