#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Crypt::Age::Simple qw< :x25519 :kdf >;

for my $text (undef, qw< scrypt argon2id argon2i argon2d scrypt$ln=1 >) {
   my $name = $text ? $text : '(no params)';
   subtest $name => sub {
      my $password = rand();

      my @args = ($password);
      push @args, "\$agex-$text" if defined($text);
      my $ckey = password_to_key(@args);

      my $cleartext = 'foo that bar!';

      {
         my $enctext = age_x25519_encrypt($ckey->{public}, $cleartext);
         ok length($enctext), 'generated some ciphertext';

         my $decrypted = age_x25519_decrypt($ckey->{secret}, $enctext);
         is $decrypted, $cleartext, 'decrypted as expected';
      }

      my $ckey2 = password_to_key($password);
      isnt $ckey->{public}, $ckey2->{public}, 'generated keys are different';

      my $ckey3 = password_to_key($password, $ckey->{phc});
      is $ckey->{public}, $ckey3->{public}, 'regenerated keys from same params';
      is $ckey->{secret}, $ckey3->{secret}, 'regenerated keys from same params';
   };
}

done_testing();
