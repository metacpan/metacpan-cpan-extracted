use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix;
#
subtest 'Library Paths and Names' => sub {
    diag '.dll located on Win32: ' . Affix::locate_lib('ntdll')      if $^O eq 'MSWin32';
    diag '.dynlib/.bundle located on OSX: ' . Affix::locate_lib('m') if $^O eq 'darwin';
    if ( $^O eq 'linux' ) {
        diag 'libc located on Linux: ' .    ( Affix::locate_lib('c') // 'error' );
        diag 'libm v6 located on Linux: ' . ( Affix::locate_lib( 'm', 6 ) // 'error' );
        diag 'libm v4 located on Linux: ' . ( Affix::locate_lib( 'm', 4 ) // 'error' );
    }
    is Affix::locate_lib('fdsjklafjklkaf'), undef, 'missing lib returns undef';
    is Affix::locate_lib("{ './lib/Non Standard Naming Scheme' }"),
        './lib/Non Standard Naming Scheme', q[{ './lib/Non Standard Naming Scheme' }];
};
done_testing;
