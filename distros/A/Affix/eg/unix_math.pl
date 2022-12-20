use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib';
use Affix;
use Config;
$|++;
my $libfile
    = $^O eq 'MSWin32' ? 'ntdll.dll' :
    $^O eq 'darwin'    ? '/usr/lib/libm.dylib' :
    $^O eq 'bsd'       ? '/usr/lib/libm.so' :
    $Config{archname} =~ /64/ ?
    -e '/lib64/libm.so.6' ?
    '/lib64/libm.so.6' :
        '/lib/x86_64-linux-gnu/libm.so.6' :
    '/lib/libm.so.6';

sub libfile {
    $libfile;
}
#
CORE::say 'sqrtf(36.f) = ' . wrap( $libfile, 'sqrtf', [Float] => Float )->(36.0);
CORE::say 'pow(2.0, 10.0) = ' .
    wrap( $libfile, 'pow', [ Double, Double ] => Double )->( 2.0, 10.0 );
