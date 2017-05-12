# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use inc::Module::Install;

name('Crypt-OpenSSL-PKCS12');
license('perl');
perl_version('5.005');
all_from('PKCS12.pm');

homepage 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
repository 'https://github.com/dsully/perl-crypt-openssl-pkcs12';
bugtracker 'https://github.com/dsully/perl-crypt-openssl-pkcs12/issues';

test_requires 'Test::Pod::Coverage' => '1.08';
test_requires 'Pod::Coverage' => '0.19';
test_requires 'Test::More' => '0.47';

requires_external_cc();

cc_inc_paths('/usr/include/openssl', '/usr/local/include/ssl', '/usr/local/ssl/include');
cc_lib_paths('/usr/lib', '/usr/local/lib', '/usr/local/ssl/lib');

cc_lib_links('crypto');
cc_optimize_flags('-O2 -g -Wall -Werror');

auto_install();
WriteAll();
