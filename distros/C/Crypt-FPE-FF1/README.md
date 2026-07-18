# Crypt::FPE::FF1

A Perl XS binding to a C implementation of NIST FF1 Format-Preserving Encryption https://github.com/mysto/clang-fpe/ .

## Installation

You’ll need Perl’s development headers, `ExtUtils::MakeMaker`, and OpenSSL installed.

```bash
git clone git@github.com:unilinkgroup/FPE_PP1.git
cd FPE_PP1
perl Makefile.PL
make
make test
sudo make install
#testing...
perl -Mblib -MCrypt::FPE::FF1 -e '
  my $ff1 = Crypt::FPE::FF1->new(
    key_hex=>"EF4359D8D580AA4F7F036D6F04FC6A94",
    tweak_hex=>"D8E7920AFA330A73",
    radix=>10,
  );
  print $ff1->encrypt("890121234567890000"), "\n";
'
#expect 318181603547192051  
```

## Usage
```perl
my $fmt = Crypt::FPE::FF1::Format->new(
  key_hex   => "EF4359D8D580AA4F7F036D6F04FC6A94", #we'll want this to be an environmental variable stored only in prod
  tweak_hex => "D8E7920AFA330A73",
);
```
