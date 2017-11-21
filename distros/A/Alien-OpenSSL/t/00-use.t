use strict;
use warnings;

use Test::More tests => 2;
use Text::ParseWords qw/shellwords/;

BEGIN { use_ok( 'Alien::OpenSSL' ); }

diag("Libs: ".Alien::OpenSSL->libs);
diag("Cflags: ".Alien::OpenSSL->cflags);
diag("Install type: ".Alien::OpenSSL->install_type);

my %libs = map { $_ => 1 } shellwords( Alien::OpenSSL->libs );
if ($^O eq 'MSWin32') {
	ok(1, 'Library defined') if ( defined($libs{'-lssl32'}) || defined($libs{'-lcrypto'}) || defined($libs{'libssl.lib'}) );
} else {
	ok(defined($libs{'-lcrypto'}), 'Libcrypto defined');
}
