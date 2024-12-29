use v5.20;
use strict;
use utf8;
use Test::More;

use_ok("Crypt::URandom::Token");

like new_ok("Crypt::URandom::Token")->get(),
  qr/^[A-Za-z0-9]{44}$/, "44 alphanumeric chars (default)";

like new_ok("Crypt::URandom::Token" => [ alphabet => [ "a", "z" ] ])->get(),
  qr/^[az]{44}$/,  "44 chars, az alphabet as arrayref";

like new_ok("Crypt::URandom::Token" => [ alphabet => [ "A", "C", "G", "T" ], length => 8 ])->get(),
  qr/^[ACGT]{8}$/, "8 chars, ACGT alphabet as arrayref";

like new_ok("Crypt::URandom::Token" => [ alphabet => "ACGT", length => 8 ])->get(),
  qr/^[ACGT]{8}$/, "8 chars, alphabet as string";

like new_ok("Crypt::URandom::Token" => [{ alphabet => "ACGT", length => 8 }])->get(),
  qr/^[ACGT]{8}$/, "8 chars, alphabet as string, hashref constructor";

like new_ok("Crypt::URandom::Token" => [ alphabet => [ "a", "z" ] ])->get(),
  qr/^[az]{44}$/,  "44 custom chars, 2 char alphabet as arrayref";

done_testing();
