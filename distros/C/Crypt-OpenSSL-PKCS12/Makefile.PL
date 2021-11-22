# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use lib '.';
use inc::Module::Install;

use File::Spec;
use Config;

name('Crypt-OpenSSL-PKCS12');
license('perl');
perl_version('5.008');
all_from('PKCS12.pm');

homepage 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
repository 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
bugtracker 'https://github.com/dsully/perl-crypt-openssl-pkcs12/issues';

test_requires 'Test::Pod::Coverage' => '1.08';
test_requires 'Pod::Coverage' => '0.19';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec::Functions' => '0'; # in core

requires_external_cc();

if ($^O ne 'MSWin32' and my $prefix = `brew --prefix --installed openssl\@1.1 2>@{[File::Spec->devnull]}`) {
  chomp $prefix;
  inc "-I$prefix/include";
  libs "-L$prefix/lib -lcrypto -lssl";
} else {
  inc '-I/usr/local/opt/openssl@1.1/include -I/usr/local/include/openssl -I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';
  libs '-L/usr/local/opt/openssl@1.1/lib -L/usr/local/lib -L/usr/lib -L/usr/local/ssl/lib -lcrypto -lssl';
}

my $cc_option_flags = '-O2 -g -Wall -Werror';

if ($Config::Config{gccversion} =~ /llvm/i) {
  $cc_option_flags .= ' -Wno-deprecated-declarations'; # -Wno-incompatible-pointer-types-discards-qualifiers -Wno-compound-token-split-by-macro
  if ($Config::Config{perl_version} <= 20) {
    $cc_option_flags .= ' -Wno-error=pointer-bool-conversion';
  }
}

auto_install();
WriteAll();
