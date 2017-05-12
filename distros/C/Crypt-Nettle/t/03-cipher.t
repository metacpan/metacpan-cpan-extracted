# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03-cipher.t'

#########################

use strict;
use warnings;
use Test;
use ExtUtils::testlib;
use Crypt::Nettle::Cipher;
use MIME::Base64;
use bytes;

#########################

# i generated this with:

# for key in 0 deadbeef ffffffff; do printf "  '%s' => {\n" "$key";  for secret in '0123456789abcdef0123456789abcdef' '________________________________' 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; do printf "    '%s' => {\n" "$secret"; for  algo in aes camellia; do for len in 128 192 256 ; do printf "      '%s%s' => '%s',\n" $algo $len $(printf '%s' "$secret" | openssl enc "-$algo-$len-ecb" -K "$key" -nopad -nosalt | base64 -w 0); done ; done ;  printf "      'cast128' => '%s',\n" "$(printf '%s' "$secret" | openssl enc "-cast5-ecb" -K "$key" -nopad -nosalt | base64 -w 0)";  printf "    },\n"; done; printf "  },\n"; done


# FIXME: i'm only testing AES, CAMELLIA, and CAST here.  should try to test more!

# FIXME: i'm only testing ECB mode.  We should test CTR and CBC modes as well!

# key -> cleartext -> algorithm -> ciphertext
my $ciphers = {
  '0' => {
    '0123456789abcdef0123456789abcdef' => {
      'aes128' => 'FPX+dGlm8pJlHCKIu/9GCRT1/nRpZvKSZRwiiLv/Rgk=',
      'aes192' => 'VAuhOrO8xcaLJZhKON6Z3FQLoTqzvMXGiyWYSjjemdw=',
      'aes256' => 'uMMzGtqcnpOzXOYBwDQNrbjDMxranJ6Ts1zmAcA0Da0=',
      'camellia128' => 'WJ3mFua227sR8qEjht3WoFid5hbmttu7EfKhI4bd1qA=',
      'camellia192' => 'ZtOzFqft8hYo0Qeyw3ChYWbTsxan7fIWKNEHssNwoWE=',
      'camellia256' => 'wz550k7ACrEGTuo/iIGjcsM+edJOwAqxBk7qP4iBo3I=',
      'cast128' => 'AgErxAPAImxRPiOHi4rECAIBK8QDwCJsUT4jh4uKxAg=',
    },
    '________________________________' => {
      'aes128' => 'vl0hoii4uzOEz1YOYSGe4L5dIaIouLszhM9WDmEhnuA=',
      'aes192' => '1MBpeGBtac/kP/vsfipDwNTAaXhgbWnP5D/77H4qQ8A=',
      'aes256' => '1ofX420A5l606zs6+Bd2G9aH1+NtAOZetOs7OvgXdhs=',
      'camellia128' => 'zi1YQCOVEGPJPRppKWAPLM4tWEAjlRBjyT0aaSlgDyw=',
      'camellia192' => 'pC2/k6TjF9QbfHj6Q161zqQtv5Ok4xfUG3x4+kNetc4=',
      'camellia256' => 'KLFoXrxeRdKP9N0JFSPBPyixaF68XkXSj/TdCRUjwT8=',
      'cast128' => 'MVtMoRQHNlExW0yhFAc2UTFbTKEUBzZRMVtMoRQHNlE=',
    },
    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' => {
      'aes128' => 'sX26cpATfV71XS7W3S9yy7F9unKQE31e9V0u1t0vcss=',
      'aes192' => 'er4z4nhhNhF7QxaMPFjwwHq+M+J4YTYRe0MWjDxY8MA=',
      'aes256' => 'Wwo/gOlgfKBTRmWaToiX41sKP4DpYHygU0Zlmk6Il+M=',
      'camellia128' => 'q8SeTMi1DNV4+CYSRnNYRqvEnkzItQzVePgmEkZzWEY=',
      'camellia192' => '2+a1BGrdVUX3LnNgRP06ddvmtQRq3VVF9y5zYET9OnU=',
      'camellia256' => 'iJ5YoiuDzOiimhUq8Bs1rYieWKIrg8zoopoVKvAbNa0=',
      'cast128' => 'W3gZ70Snjs1beBnvRKeOzVt4Ge9Ep47NW3gZ70Snjs0=',
    },
  },
  'deadbeef' => {
    '0123456789abcdef0123456789abcdef' => {
      'aes128' => 'J8irigIL+FjFEqlKkoUrqCfIq4oCC/hYxRKpSpKFK6g=',
      'aes192' => 'WYXL3tPORMV7otd83dJT8lmFy97TzkTFe6LXfN3SU/I=',
      'aes256' => 'aHuNBkMZtN10LFaOqPT782h7jQZDGbTddCxWjqj0+/M=',
      'camellia128' => 'vWkKE2JwRj4y/lZCcLqEUr1pChNicEY+Mv5WQnC6hFI=',
      'camellia192' => 'AE+DO5uh0LjWPY6/OV/L/ABPgzubodC41j2Ovzlfy/w=',
      'camellia256' => 'KfP76Kdxi/5G5xTAq2XclCnz++incYv+RucUwKtl3JQ=',
      'cast128' => 'pdrqdb9LyfyRbc2HctQnRKXa6nW/S8n8kW3Nh3LUJ0Q=',
    },
    '________________________________' => {
      'aes128' => 'aRqz/75E/tofvG1auUFmoGkas/++RP7aH7xtWrlBZqA=',
      'aes192' => 'X3geXxxnGERQPId4UbuZKF94Hl8cZxhEUDyHeFG7mSg=',
      'aes256' => 'Ui7t6WzzrPfNBX7b5vy741Iu7els86z3zQV+2+b8u+M=',
      'camellia128' => 'QbIujYiG//CHquJF61wPe0GyLo2Ihv/wh6riRetcD3s=',
      'camellia192' => 'xbbVQfLvFX56KpjzuLXOmMW21UHy7xV+eiqY87i1zpg=',
      'camellia256' => 'Sw1UNoUD4D1+n8a5o9U7AksNVDaFA+A9fp/GuaPVOwI=',
      'cast128' => 'XwA7FM4jm9xfADsUziOb3F8AOxTOI5vcXwA7FM4jm9w=',
    },
    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' => {
      'aes128' => 'fJjY9L5/3DMJ/gCrDGQ8ZHyY2PS+f9wzCf4AqwxkPGQ=',
      'aes192' => 'U3dhTTDuOyMj/spFMExiolN3YU0w7jsjI/7KRTBMYqI=',
      'aes256' => 'jJ0bZdvTowtTePLSjkpc+4ydG2Xb06MLU3jy0o5KXPs=',
      'camellia128' => 'QWG/Fp34d8ejSiyYGafzjUFhvxad+HfHo0osmBmn840=',
      'camellia192' => 'J1fn0/Z0BVOLBhJTPvn7LydX59P2dAVTiwYSUz75+y8=',
      'camellia256' => 'owNk1XEWS9CXEJFnMeNmF6MDZNVxFkvQlxCRZzHjZhc=',
      'cast128' => 'qOj5dcDNDRio6Pl1wM0NGKjo+XXAzQ0YqOj5dcDNDRg=',
    },
  },
  'ffffffff' => {
    '0123456789abcdef0123456789abcdef' => {
      'aes128' => 'pjc35DPKkVO5tJP5oit4LKY3N+QzypFTubST+aIreCw=',
      'aes192' => 'RSpBTLoLciJwk2Y6Im36nEUqQUy6C3IicJNmOiJt+pw=',
      'aes256' => 'EfOEOy6ksQj1SfyOUPoqthHzhDsupLEI9Un8jlD6KrY=',
      'camellia128' => 'RxparjLgNJMd/NEmxIfo2EcaWq4y4DSTHfzRJsSH6Ng=',
      'camellia192' => 'ZB+E+Gx+7sAq7cJBoy23sWQfhPhsfu7AKu3CQaMtt7E=',
      'camellia256' => '24biOgVlTJAGil4u7d3ag9uG4joFZUyQBopeLu3d2oM=',
      'cast128' => 'R6rrqdVlPMDvOvbbQ+V9UEeq66nVZTzA7zr220PlfVA=',
    },
    '________________________________' => {
      'aes128' => 'bs8KuDXk4jcY7rFSg2b1P27PCrg15OI3GO6xUoNm9T8=',
      'aes192' => 'q7q9GYNisbwY0KIROKkBy6u6vRmDYrG8GNCiETipAcs=',
      'aes256' => '6FmQT9kDXvxL/s0ih5nveOhZkE/ZA178S/7NIoeZ73g=',
      'camellia128' => 'MhLbhDU+PuwDZ0uOcCWM5zIS24Q1Pj7sA2dLjnAljOc=',
      'camellia192' => '+/BMaDcUGTIT0rE1+ws/LPvwTGg3FBkyE9KxNfsLPyw=',
      'camellia256' => 'kUOI2RbHaJ2//qbz9ja+C5FDiNkWx2idv/6m8/Y2vgs=',
      'cast128' => 'rZAcNW4AxbytkBw1bgDFvK2QHDVuAMW8rZAcNW4Axbw=',
    },
    'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' => {
      'aes128' => 'onduudVSnFyqTIZMCjlQb6J3brnVUpxcqkyGTAo5UG8=',
      'aes192' => 'LzpISFqAOJ40luJ9kYrmZi86SEhagDieNJbifZGK5mY=',
      'aes256' => '4xhRceBD8uyeZrT6g+t+u+MYUXHgQ/Lsnma0+oPrfrs=',
      'camellia128' => 'Rytc4GaMrrW3FsQhAA3Ai0crXOBmjK61txbEIQANwIs=',
      'camellia192' => 'ngubuFQHc289iTpPVkr79J4Lm7hUB3NvPYk6T1ZK+/Q=',
      'camellia256' => '8uD++vS4c28uMY9/Ya66JvLg/vr0uHNvLjGPf2GuuiY=',
      'cast128' => 'MAMTehXpNAMwAxN6Fek0AzADE3oV6TQDMAMTehXpNAM=',
    },
  },
};

my $algos = {
              aes128 => [16, 16],
              aes192 => [24, 16],
              aes256 => [32, 16],
              arctwo40 => [5, 8],
              arctwo64 => [8, 8],
              arctwo128 => [16, 8],
              arctwo_gutmann128 => [16, 8],
              arcfour128 => [16, 0],
              camellia128 => [16, 16],
              camellia192 => [24, 16],
              camellia256 => [32, 16],
              cast128 => [16, 8],
              serpent128 => [16, 16],
              serpent192 => [24, 16],
              serpent256 => [32, 16],
              twofish128 => [16, 16],
              twofish192 => [24, 16],
              twofish256 => [32, 16],
              arctwo40 => [5, 8],
              arctwo64 => [8, 8],
              arctwo128 => [16, 8],
              arctwo_gutmann128 => [16, 8],
             };

my @modes = ( 'ecb', 'cbc', 'ctr' );

my $ciphertextcount = scalar(map({ keys(%$_) } map({ values(%$_) } values(%{$ciphers}))));
plan tests => ((7*scalar(keys(%{$algos}))) + $ciphertextcount + (scalar(@modes) + 1));

my $mode;
my $data;
my $algo;

my @reported_modes = sort(Crypt::Nettle::Cipher::modes_available());
@modes = sort(@modes);
while (@reported_modes) {
  my $modea = shift(@modes);
  my $modeb = shift(@reported_modes);
  ok($modea eq $modeb);
}
ok(0 == scalar(@modes));

for $algo (keys(%{$algos})) {
  my ($key_size, $block_size) = @{$algos->{$algo}};
  my $key = ' ' x $key_size;
  my $cipher = Crypt::Nettle::Cipher->new('encrypt', $algo, $key, 'ecb');
  ok($key_size == $cipher->key_size());
  ok($key_size == Crypt::Nettle::Cipher->key_size($algo));
  ok($block_size == $cipher->block_size());
  ok($block_size == Crypt::Nettle::Cipher->block_size($algo));
  ok(1 == $cipher->is_encrypt());
  ok('ecb' eq $cipher->mode());
  ok($algo eq $cipher->name());
}

my $key;
my $cleartext;

for $key (sort keys %{$ciphers}) {
  for $cleartext (sort keys %{$ciphers->{$key}}) {
    for $algo (sort keys %{$ciphers->{$key}->{$cleartext}}) {
      my $keylen = Crypt::Nettle::Cipher->key_size($algo);
      # apparently OpenSSL pads the key with zeros at the end:
      my $hexkey = $key.('0' x (($keylen*2) - length($key)));
      my $keyval =  pack('H*', $hexkey);

      my $encrypt = Crypt::Nettle::Cipher->new('encrypt', $algo, $keyval, 'ecb');
      my $decrypt = Crypt::Nettle::Cipher->new('encrypt', $algo, $keyval, 'ecb');
      next unless defined($encrypt) && defined($decrypt);
      my $target = $ciphers->{$key}->{$cleartext}->{$algo};
      my $ciphertext = $encrypt->process($cleartext);
      my $result = encode_base64($ciphertext);
      $result =~ s/\s//g; # strip all whitespace from the result.
      warn sprintf("(%s) %s : %s: \nT: %s\nR: %s\n", $algo, $key, $cleartext, $target, $result) unless ($target eq $result);
      ok($target eq $result);
    }
  }
}

