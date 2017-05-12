use strict;
use inc::Module::Install;

name 'Crypt-DH';
abstract 'Diffie-Hellman key exchange system';
author 'Benjamin Trott (cpan:BTROTT) <ben+cpan@stupidfool.org>';
author 'BinGOs - Chris Williams (cpan:BINGOS) <chris@bingosnet.co.uk>';
author 'Mithaldu - Christian Walde (cpan:MITHALDU) <walde.christian@googlemail.com>';
version_from 'lib/Crypt/DH.pm';
readme_from 'lib/Crypt/DH.pm';
license 'perl';
no_index directory => 't';

include 'ExtUtils::AutoInstall';

perl_version '5.006';
build_requires 'Test::More' => 0.47;
eval { assertlibs lib => 'gmp', header => 'gmp.h'; };
unless ($@) {
  requires 'Math::BigInt::GMP' => 1.24;
}
else {
  requires 'Math::BigInt::Pari' => 1.13;
}

requires('Math::BigInt' => '1.60');

githubmeta;
auto_include;
auto_install;

WriteAll;

