#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'Crypt::PBKDF2';
  use_ok 'Crypt::PBKDF2::Hash::HMACSHA1';
  use_ok 'Crypt::PBKDF2::Hash::HMACSHA2';
}

{
  my $orig = Crypt::PBKDF2->new(hash_class => 'HMACSHA1');
  my $orig_hasher = $orig->hasher;
  is ref $orig_hasher, 'Crypt::PBKDF2::Hash::HMACSHA1', 'Got the right hasher class';

  {
    my $clone = $orig->clone;
    my $clone_hasher = $clone->hasher;
    isnt $clone_hasher, $orig_hasher, 'Hasher was rebuilt';
    is ref $clone_hasher, 'Crypt::PBKDF2::Hash::HMACSHA1', 'Still the right class';
  }

  {
    my $clone = $orig->clone(hash_class => 'HMACSHA2');
    my $clone_hasher = $clone->hasher;
    isnt $clone_hasher, $orig_hasher, 'Hasher was rebuilt again';
    is ref $clone_hasher, 'Crypt::PBKDF2::Hash::HMACSHA2', 'Rebuilt under the right class';
  }
}

{
  my $hasher = Crypt::PBKDF2::Hash::HMACSHA1->new;
  my $orig = Crypt::PBKDF2->new(hasher => $hasher);
  is $orig->hasher, $hasher, 'Used the hasher we passed in';
  is $orig->clone->hasher, $hasher, 'Same hasher on clone';
  ok ! $orig->has_lazy_hasher, q{Hasher wasn't marked lazy-built};
}

done_testing;
