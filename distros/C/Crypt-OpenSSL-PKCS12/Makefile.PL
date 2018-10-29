# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

BEGIN { push @INC, '.' unless $INC[-1] eq '.' }
use inc::Module::Install;

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

requires_external_cc();

inc '-I/usr/local/opt/openssl/include -I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';
libs '-L/usr/local/opt/openssl/lib -L/usr/lib -L/usr/local/lib -L/usr/local/ssl/lib -lcrypto -lssl';

if ($^O ne 'darwin') {
    cc_optimize_flags('-O2 -g -Wall -Werror');
}
else {
    cc_optimize_flags('-O2 -g -Wall -Werror -Wno-deprecated-declarations');
}

auto_install();
WriteAll();
