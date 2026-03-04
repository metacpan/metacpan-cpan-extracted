use strict;
use warnings;
use Test::More;
use Test::Alien;

use_ok('Alien::MariaDB');

alien_ok 'Alien::MariaDB';

diag 'cflags: ' . Alien::MariaDB->cflags;
diag 'libs: ' . Alien::MariaDB->libs;
diag 'install_type: ' . Alien::MariaDB->install_type;

like(Alien::MariaDB->install_type, qr/^(system|share)$/, 'install_type is valid');

# On macOS share installs, the dylib uses @rpath install name but
# Test::Alien's xs_ok doesn't pass -Wl,-rpath to the linker.
# Temporarily set the install name to the absolute blib path so
# dlopen can find the library, then restore @rpath afterward.
my @_fixup;
if ($^O eq 'darwin' && Alien::MariaDB->install_type eq 'share') {
    like(Alien::MariaDB->libs, qr/-Wl,-rpath/, 'darwin share libs includes rpath');
    if (Alien::MariaDB->libs =~ /-L(\S+)/) {
        my $libdir = $1;
        for my $dylib (glob "$libdir/libmariadb*.dylib") {
            next if -l $dylib;
            (my $name = $dylib) =~ s{.*/}{};
            if (system('install_name_tool', '-id', $dylib, $dylib) == 0) {
                push @_fixup, [$dylib, $name];
                diag "fixup: $name -> $dylib";
            }
        }
    }
}

xs_ok { xs => do { local $/; <DATA> }, verbose => 1 }, with_subtest {
    ok(defined Foo::client_info(), 'mysql_get_client_info returns a value');
    diag 'client_info: ' . Foo::client_info();
};

# Restore @rpath install names for make install
for my $fix (@_fixup) {
    system('install_name_tool', '-id', "\@rpath/$fix->[1]", $fix->[0]) == 0
        or warn "install_name_tool restore failed for $fix->[0]: $?\n";
}

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mysql.h>

MODULE = Foo PACKAGE = Foo

const char *
client_info()
CODE:
    RETVAL = mysql_get_client_info();
OUTPUT:
    RETVAL
