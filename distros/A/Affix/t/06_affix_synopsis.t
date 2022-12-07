use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix;
#
if ( $^O eq 'darwin' ) {
    plan skip_all => 'I know nothing about macOS';
}
else {
    sub pow : Native(get_lib) : Signature([Double, Double]=>Double);
    is pow( 2, 10 ), 1024, 'pow( 2, 10 ) == 1024';
}
done_testing;

sub get_lib {
    return 'ntdll'               if $^O eq 'MSWin32';
    return '/usr/lib/libm.dylib' if $^O eq 'darwin';
    my $opt = $^O =~ /bsd/ ? 'r' : 'p';
    my ($path) = qx[ldconfig -$opt | grep libm.so];
    if ( !defined $path ) {
        ($path) = qx[gcc --print-file-name=libm.so.6];
        chomp $path;
        require Cwd;
        $path = Cwd::abs_path($path);
    }
    $path =~ m!(\S*?)$!;
    diag $1;
    $1;
}
