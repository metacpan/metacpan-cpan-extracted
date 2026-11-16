use strict;
use warnings;
use Test::More;
use Test::Alien;

use_ok('Alien::MySQL');

alien_ok 'Alien::MySQL';

diag 'cflags: ' . Alien::MySQL->cflags;
diag 'libs: ' . Alien::MySQL->libs;
diag 'install_type: ' . Alien::MySQL->install_type;

like(Alien::MySQL->install_type, qr/^(system|share)$/, 'install_type is valid');

# Test::Alien omits -Wl,-rpath; point macOS dylib ID at blib temporarily
my @_fixup;
if ($^O ne 'MSWin32' && Alien::MySQL->install_type eq 'share') {
    like(Alien::MySQL->libs, qr/-Wl,-rpath/, 'share libs includes rpath');
}
if ($^O eq 'darwin' && Alien::MySQL->install_type eq 'share') {
    if (Alien::MySQL->libs =~ /-L(\S+)/) {
        my $libdir = $1;
        for my $dylib (glob "$libdir/libmysqlclient*.dylib") {
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
