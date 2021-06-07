# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use lib '.';
use inc::Module::Install;

use File::Spec;
use Config;

name('Crypt-OpenSSL-PKCS12');
license('perl');
perl_version('5.006');
all_from('PKCS12.pm');

homepage 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
repository 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
bugtracker 'https://github.com/dsully/perl-crypt-openssl-pkcs12/issues';

test_requires 'Test::Pod::Coverage' => '1.08';
test_requires 'Pod::Coverage' => '0.19';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec::Functions' => '0'; # in core

requires_external_cc();

if ($^O ne 'MSWin32' and my $prefix = `brew --prefix --installed openssl 2>@{[File::Spec->devnull]}`) {
  chomp $prefix;
  inc "-I$prefix/include";
  libs "-L$prefix/lib -lcrypto -lssl";
} else {
  inc '-I/usr/local/opt/openssl/include -I/usr/local/include/openssl -I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';
  libs '-L/usr/local/opt/openssl/lib -L/usr/local/lib -L/usr/lib -L/usr/local/ssl/lib -lcrypto -lssl';
}

if ($Config::Config{myuname} =~ /darwin/i) {
    cc_optimize_flags('-O2 -g -Wall -Werror -Wno-deprecated-declarations');
} else {
    cc_optimize_flags('-O2 -g -Wall -Werror');
}

auto_install();
WriteAll();
