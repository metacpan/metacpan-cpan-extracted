#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test2::V0;
use Crypt::Cipher::Vigenere;

{ # instance creation
  my $v = Crypt::Cipher::Vigenere->new('LEMON');
  isa_ok($v, 'Crypt::Cipher::Vigenere');

  # simple test (Wikipedia article example)
  is($v->encode('ATTACKATDAWN'), 'LXFOPVEFRNHR', 'encode basic');
  $v->reset;
  is($v->decode('LXFOPVEFRNHR'), 'ATTACKATDAWN', 'decode basic');
}

{ # key is case-insensitive
  my $v = Crypt::Cipher::Vigenere->new('LeMoN');
  is($v->encode('ATTACKATDAWN'), 'LXFOPVEFRNHR', 'encode key case');
  $v->reset;
  is($v->decode('LXFOPVEFRNHR'), 'ATTACKATDAWN', 'decode key case');
}

{ # text is case-preserving
  my $v = Crypt::Cipher::Vigenere->new('LeMoN');
  is($v->encode('AttackAtDawn'), 'LxfopvEfRnhr', 'encode text case');
  $v->reset;
  is($v->decode('LxfopvEfRnhr'), 'AttackAtDawn', 'decode text case');
}

{ # text transparently passes through chars other than A-Z
  my $v = Crypt::Cipher::Vigenere->new('LeMoN');
  is($v->encode(q{⚔️ Attaque à l'aube!}), q{⚔️ Lxfodfi à x'ohmi!}, 'encode transparency');
  $v->reset;
  is($v->decode(q{⚔️ Lxfodfi à x'ohmi!}), q{⚔️ Attaque à l'aube!}, 'decode transparency');
}

# finish
done_testing();
