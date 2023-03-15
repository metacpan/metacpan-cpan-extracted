use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Affix qw[:all];
use Test::More;
use Config;
$|++;
#
my $libfile
    = Affix::locate_lib( $^O eq 'MSWin32' ? 'msvcrt' :
        $^O eq 'darwin' ? '/usr/lib/libm.dylib' :
        $^O eq 'bsd'    ? '/usr/lib/libm.so' :
        $Config{archname} =~ /64/ ?
        -e '/lib64/libm.so.6' ?
        '/lib64/libm.so.6' :
            '/lib/x86_64-linux-gnu/libm.so.6' :
        '/lib/libm.so.6' );

#  "/usr/lib/system/libsystem_c.dylib", /* macos - note: not on fs w/ macos >= 11.0.1 */
#    "/usr/lib/libc.dylib",
#    "/boot/system/lib/libroot.so",       /* Haiku */
#    "\\ReactOS\\system32\\msvcrt.dll",   /* ReactOS */
#    "C:\\ReactOS\\system32\\msvcrt.dll",
#    "\\Windows\\system32\\msvcrt.dll",   /* Windows */
#    "C:\\Windows\\system32\\msvcrt.dll"
SKIP: {
    skip 'Cannot find math lib: ' . $libfile, 8 if $^O ne 'MSWin32' && !-f $libfile;
    diag 'Loading ' . $libfile . ' ...';
    my %loaders = (
        sin_default  => wrap( $libfile, 'sin', [ CC_DEFAULT,          Double ], Double ),
        sin_vararg   => wrap( $libfile, 'sin', [ CC_ELLIPSIS_VARARGS, Double ], Double ),
        sin_ellipsis => wrap( $libfile, 'sin', [ CC_ELLIPSIS,         Double ], Double ),
        sin_cdecl    => wrap( $libfile, 'sin', [ CC_CDECL,            Double ], Double ),
        sin_stdcall  => wrap( $libfile, 'sin', [ CC_STDCALL,          Double ], Double ),
        sin_fastcall => wrap( $libfile, 'sin', [ CC_FASTCALL_GNU,     Double ], Double ),
        sin_thiscall => wrap( $libfile, 'sin', [ CC_THISCALL_GNU,     Double ], Double )
    );
    my $correct
        = $Config{usequadmath} ? -0.988031624092861826547107284568483 :
        $Config{uselongdouble} ? -0.988031624092861827 :
        -0.988031624092862;    # The real value of sin(30);
    for my $fptr ( sort keys %loaders ) {
        if ( !defined $loaders{$fptr} ) {
            diag 'Failed to affix ' . $fptr;
        }
        else {
            is $loaders{$fptr}->(30), $correct, sprintf '$loaders{%s}->( 30 );', $fptr;

            #skip sprintf( '$loaders{%s}->( 30 ) failed: %s', $fptr, $@ ), 1 if $@;
        }
    }
}
done_testing;
