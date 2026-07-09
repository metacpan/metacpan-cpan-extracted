use strict;
use warnings;
use Test::More;
use MIME::Base64 "decode_base64";

use Crypt::Sodium::XS::kem;

plan skip_all => 'no kem available' unless Crypt::Sodium::XS::kem->available;

use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

my %test_pk;
$test_pk{default} = decode_base64('
6javBLSATiehjVGUwhe2rFgcybp9NJRdt5NjpzyBO0RLX4dgIEVwE4YyS3Fuh+EqS8POItdh9uch
c9uX/BKhL+V26pxkJNW8a7GY/wC0M2aQS9oKLkklj+NmkcdgYFxIARs+JQdU8pszf+xGwoIRgvIb
Z9lKtMVM9BgOXzRQzsUXICVrMXylzFQ6LJubqHRsyaux9viY47S6DeoYM6UrNwV3LOIT/ltwKwRt
rEs0Bjy1Trs0AA2AyomzMqogGMtEIZfLLLVaEtrK53EbNPG+v5u8w4nJary9JLwUsLuMIRGVhaIT
CTUznlAllMMJsBN/X+oSiZY0X4ZTzxIRG7KWTjDDARKZxVaSduJY2OF4Fnw3StcL0UBXYVsOl3un
mFg8AAgWPsAkADepSWE0lARXFIK5k6c4vcW8BcBXNLPJwhBkj0jI7kSa59qT4zWzhbBQdppNEEqZ
J0W9ghBi4RC7gBKWXufDobKiH3s8mDiID1Ury7C8STIdKgmb3/HKZPnBTEgWVaVL37OeChhatrTM
P4pZVoJcMIIVUKJAlITPJ6w69tKh79ajPDBLsWFReyJQcKR53RxXzbSXlnAHtDxFScqwI7tFqQJi
e0uPvnYkNQJmlfusjEqbBOy6caPGcqNezDhUoTU2AWkdhVp65cwlSrHIjADE8cgg+aRhMEtYXnCM
V/dkQPGPpJQlEFlOJEeKr3IedQu+WrN/2qWJlaCJUnyoMJUa6INsafawd9a+VpMkcZwIrDyiYgOU
WckC1yZioSSde6OYEhVV/Ey82OdcwYYekOiO6uUw4TOfOvGYsZR63HpLvAKm0TxtI/YyhskgtQo6
vah/DQSX15AbxOIBqPSkgVQ/BoFttLiqKemqpmJzOiFyVgNoXLobsSha4Kiko6MIw7x5HiNqQcCP
7RHC61Ys76FEu+QejJI6p3HLEmrMPOUYAstKSxy0/sYV1aSPm6EVlagMw/BbiUsVWHKn8fcbSRKL
5VayjyJD8QEp3QAXE4qIs2esy6OLwdSfU8FNrqUpxWWlxpsuSNC7H1G5pdSBbUsdKAIqENJsrbkD
bJOK6iepsrGjpvM6f4iKGORg+qJFU5hKKNoOHjgJR5ATobJBBkq8NCZFpEQxgkIPF8u/YDAWY2TB
DztbM2N+45dJQjufx4ZazfBQIrNtrWhP5EAgyrxaYNgOAC0gDFxmqOuPRkRJOfVR5xBfr3yv3kCM
4tMZHeVq80ofLafASjfNixdckBsuh6dqbahvkCHKv1tKwyG7W2McLwUyuvEx9UQZ3nmdj+sVj3uv
48Z0gofLJzWeIBN5YIuH7lRwlSAK23xmSSOhZ/dm+fpUrru96UG3PIKO2SK0spyGaMW4osWctOyW
I9QK+YPCSFiK6gt+WdQ0bzWI7hO8jQwA05hylbCRY7a5GzWpLIka+9MXU+AQ4Ww7Qnw5a+a9f5C+
oZkcL+SbiEkxKeSVxMBN1PcgoepqADLF8OuxX6ofktKxcLNsL7pOi5tcLknJ9+YHfRiKlQCII5qJ
CAZUwCXNUMO7x2aEckBPYkzuiDHUxNJN3TByOHN9URIO+8QD6tMaXMRqgE8Mrp/Uliqr3TUEj+Fb
CODr1QauKyYJOhDt75C3lqbJGw==
');
$test_pk{mlkem768} = decode_base64('
mIvL7uKix8wvtGvCWZIOs7JDRQs0+Wl841Grk8C8t1KFHbF6QpyzbdfAw9XPEPVE57YMNPSHLlDD
9eRvIfSEo1Sb/HG0rjOTPGEdzQxqUXgtthcMhSU8v0O0r1BxXNuX7SCLQ+y19WkVQuPH2jNLYwAQ
/MagLRtqNPJ4o5mtCTkzRJywI+R1fxYVeqY6myAebdWEAaaqOvtUsds0sTA3jhMnuZMli0WTJrst
6QTPi2ijxqrI9pU4eYlSQlxWmJqNLHdLf7V9TQxNYwFbOqC0rNyuPAV4C8K+1BxcwfiQsMRc6wLB
7qRHqDomRBZD1DcSd3PLupdE3YIDeUC3pRRf2NuO67y7rsF0tuxNkZiCIBN4ngKWj9pzcGd19SwR
1See6+q5rrArInWsQ7scsBNlXbEIrUhTPqKPEYB4EiWuU5zKSdMutzWP6IEdrXdb+LZoDKA8o+xV
0SVrCWYBZdKKiLhEonekf9pCxFNcXdBzTYGfTApwWma/ocR6j6V4nzNsh0XCD1AS66eYqyVpZ5S1
LQMghFFl6PwyHipjEghtddMFRWAVL2pX20mXrFe9F3ZBUiEj6fxqvZyI6HOhomKs+CZEy6eA4QZn
wrEPu5vFUxuoSgmcSlE2d7F6eMsLjZqQI3US9xUinFerBBOXMeY9h7dSMdEqtAY1PWKY4pMpu9eZ
zth88eldvTatMpW5g+l3Y9yFvEtihthsmXVoK0AiPDUJ1/zGboC+McEgjrkpDHNtHnRD8sfHyYAt
1purHxhbL2FoiNYlNmSj6jpq/vhXUqAFxRrCCxPGaSYd65YAdmYcCUGyoBqFj3csWHk1Uvyyk1g5
aHgRuiRVgBAaHnAEfaGHK7JxuQit3YS65VdYK3C8qUfPfYu+5eKkb+RlXJlCKMRQN2WM1BspgPg8
hnVJVJyGjHlYfDqADUBys9WuRKmcX+qEywAqV3d/wqmLmDZVVsKjCQxUyImZ8QQTIxdVg+csroFH
frtB3hFHKBiSvNKWR0ade/uQdBkCJ6I4xqBYSyhpq+ISM3uET6gf4fMmSCfJvCe1Y6EiHGcxcZZ2
q7WsunewioQRPqc9GgRCx4wm2LhvzCYAM/AYkOWfaLCVJlgm8IKfMrCsfPZkFcF5K/eNSmOKvXXC
c6RSrxeIhmKSZLRp9zg6BxkAQKZ4yFkcuAWaAzRX8yHJj4q8T1cW0pGu75sXwYgrOIPO3peQ48cK
O3wF5hdajuN8NqCYIUe5RRWMvnw6adyHkdIZL9eeLikGixhz5WIT49wQHunFjgFPTGN1/NQqu0PF
ZFirZnBJ9Xin+HUqBHRso8nDTywGMoWiqqdDUGTDa7B0zDhs3pxaZyeY7wzH6mKtP/Odqbxwg4Ah
w0xBNaJgPDyoVsxy9LMGy2h0Y5XPYqqBYbxYaFnDK7h0xihXZfBfvVBTKxkB6PObcAWgZjASOJaa
ruKhA+ZY74QX6FlpPAlR76kNstpg3DoyA3Uc8EK2QFWIH3SKBddnhfhYW5AdQUogY0ynfNkRFkDI
Aha0Bgux7WsyeLVst+0LmnW4dpWd1JQ5thTfPMacZOhzwXPfSuMHdXgAV6Q=
');
$test_pk{xwing} = decode_base64('
6javBLSATiehjVGUwhe2rFgcybp9NJRdt5NjpzyBO0RLX4dgIEVwE4YyS3Fuh+EqS8POItdh9uch
c9uX/BKhL+V26pxkJNW8a7GY/wC0M2aQS9oKLkklj+NmkcdgYFxIARs+JQdU8pszf+xGwoIRgvIb
Z9lKtMVM9BgOXzRQzsUXICVrMXylzFQ6LJubqHRsyaux9viY47S6DeoYM6UrNwV3LOIT/ltwKwRt
rEs0Bjy1Trs0AA2AyomzMqogGMtEIZfLLLVaEtrK53EbNPG+v5u8w4nJary9JLwUsLuMIRGVhaIT
CTUznlAllMMJsBN/X+oSiZY0X4ZTzxIRG7KWTjDDARKZxVaSduJY2OF4Fnw3StcL0UBXYVsOl3un
mFg8AAgWPsAkADepSWE0lARXFIK5k6c4vcW8BcBXNLPJwhBkj0jI7kSa59qT4zWzhbBQdppNEEqZ
J0W9ghBi4RC7gBKWXufDobKiH3s8mDiID1Ury7C8STIdKgmb3/HKZPnBTEgWVaVL37OeChhatrTM
P4pZVoJcMIIVUKJAlITPJ6w69tKh79ajPDBLsWFReyJQcKR53RxXzbSXlnAHtDxFScqwI7tFqQJi
e0uPvnYkNQJmlfusjEqbBOy6caPGcqNezDhUoTU2AWkdhVp65cwlSrHIjADE8cgg+aRhMEtYXnCM
V/dkQPGPpJQlEFlOJEeKr3IedQu+WrN/2qWJlaCJUnyoMJUa6INsafawd9a+VpMkcZwIrDyiYgOU
WckC1yZioSSde6OYEhVV/Ey82OdcwYYekOiO6uUw4TOfOvGYsZR63HpLvAKm0TxtI/YyhskgtQo6
vah/DQSX15AbxOIBqPSkgVQ/BoFttLiqKemqpmJzOiFyVgNoXLobsSha4Kiko6MIw7x5HiNqQcCP
7RHC61Ys76FEu+QejJI6p3HLEmrMPOUYAstKSxy0/sYV1aSPm6EVlagMw/BbiUsVWHKn8fcbSRKL
5VayjyJD8QEp3QAXE4qIs2esy6OLwdSfU8FNrqUpxWWlxpsuSNC7H1G5pdSBbUsdKAIqENJsrbkD
bJOK6iepsrGjpvM6f4iKGORg+qJFU5hKKNoOHjgJR5ATobJBBkq8NCZFpEQxgkIPF8u/YDAWY2TB
DztbM2N+45dJQjufx4ZazfBQIrNtrWhP5EAgyrxaYNgOAC0gDFxmqOuPRkRJOfVR5xBfr3yv3kCM
4tMZHeVq80ofLafASjfNixdckBsuh6dqbahvkCHKv1tKwyG7W2McLwUyuvEx9UQZ3nmdj+sVj3uv
48Z0gofLJzWeIBN5YIuH7lRwlSAK23xmSSOhZ/dm+fpUrru96UG3PIKO2SK0spyGaMW4osWctOyW
I9QK+YPCSFiK6gt+WdQ0bzWI7hO8jQwA05hylbCRY7a5GzWpLIka+9MXU+AQ4Ww7Qnw5a+a9f5C+
oZkcL+SbiEkxKeSVxMBN1PcgoepqADLF8OuxX6ofktKxcLNsL7pOi5tcLknJ9+YHfRiKlQCII5qJ
CAZUwCXNUMO7x2aEckBPYkzuiDHUxNJN3TByOHN9URIO+8QD6tMaXMRqgE8Mrp/Uliqr3TUEj+Fb
CODr1QauKyYJOhDt75C3lqbJGw==
');

for my $alg (Crypt::Sodium::XS::kem->primitives) {
  my $kem = Crypt::Sodium::XS->kem(primitive => $alg);

  for my $blen (qw(CIPHERTEXTBYTES PUBLICKEYBYTES SECRETKEYBYTES
                SHAREDSECRETBYTES SEEDBYTES)) {
    ok($kem->$blen > 0, "$blen > 0 ($alg)");
  }

  my $seed = "\1" . ("\0" x ($kem->SEEDBYTES - 1));
  my ($pk, $sk) = $kem->keypair($seed);
  ok($sk->length == $kem->SECRETKEYBYTES, "correct length seeded secret key ($alg)");
  ok(length($pk) == $kem->PUBLICKEYBYTES, "correct length seeded pubkey ($alg)");
  ok($test_pk{$alg} eq $pk, "pubkey matches with test seed ($alg)");

  ($pk, $sk) = $kem->keypair;
  ok($sk->length == $kem->SECRETKEYBYTES, "correct length secret key ($alg)");
  ok(length($pk) == $kem->PUBLICKEYBYTES, "correct length pubkey ($alg)");

  my ($ct, $ss) = $kem->enc($pk);
  ok(length($ct) == $kem->CIPHERTEXTBYTES, "correct length ciphertext ($alg)");
  ok($ss->size == $kem->SHAREDSECRETBYTES, "correct length enc secret ($alg)");

  my $ss2 = $kem->dec($ct, $sk);
  ok($ss->size == $kem->SHAREDSECRETBYTES, "correct length dec secret ($alg)");
  ok($ss2->memcmp($ss), "shared secret matches ($alg)");

}

done_testing();
