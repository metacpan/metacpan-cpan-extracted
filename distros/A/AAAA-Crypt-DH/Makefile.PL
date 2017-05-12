use if ! ( grep { $_ eq '.' } @INC ), qw[lib .];
use strict;
use inc::Module::Install;
name 'AAAA-Crypt-DH';
author 'Chris Williams';
version_from 'lib/AAAA/Crypt/DH.pm';
abstract_from 'lib/AAAA/Crypt/DH.pm';
readme_from 'lib/AAAA/Crypt/DH.pm';
license 'perl';
perl_version '5.006';
build_requires 'Test::More' => 0.47;
eval { assertlibs lib => 'gmp', header => 'gmp.h'; };
unless ($@) {
  requires 'Math::BigInt::GMP' => 1.24;
}
else {
  requires 'Math::BigInt::Pari' => 1.13;
}
auto_license;
githubmeta;
auto_provides;
WriteAll();
