#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Code::Crypt;
use Code::Crypt::Graveyard;

our $SUCCESS = 0;

eval(Code::Crypt::Graveyard->new(
   code => '$SUCCESS = 1',
   builders => [
      Code::Crypt->new(
         get_key => q{ $] },
         key => $],
         cipher => 'Crypt::DES',
      ),
      Code::Crypt->new(
         get_key => q{ $^O },
         key => $^O,
         cipher => 'Crypt::DES',
      ),
   ],
)->final_code);
ok($SUCCESS, 'Crypt successfully encrypted and decrypted');

done_testing();
