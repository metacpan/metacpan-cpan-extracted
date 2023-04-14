use strict;
use utf8;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use t::lib::nativecall;
use experimental 'signatures';
use Devel::CheckBin;
use Config;
$|++;
#
#~ my $lib = 't/src/85_affix_mangle_rust/target/release/' .
#~ ( $^O eq 'MSWin32' ? '' : 'lib' ) . 'affix_rust.' . $Config{so};
#~ warn $lib;
#~ system 'nm -D --demangle ' . $lib;
SKIP: {
    skip 'test requires rust/cargo', 2 unless can_run('cargo');
    diag 'building crate as dylib';
    system 'cargo build --manifest-path=t/src/85_affix_mangle_rust/Cargo.toml --release --quiet';
    my $lib = 't/src/85_affix_mangle_rust/target/release/' .
        ( $^O eq 'MSWin32' ? '' : 'lib' ) . 'affix_rust.' . $Config{so};
    affix $lib, 'add', [ Size_t, Size_t ], Size_t;    #[no_mangle]
    is add( 5, 4 ), 9, 'add(5, 4) == 9';
    #
    affix [ $lib, RUST ], mod => [ Int, Int ] => Int;
    is mod( 5, 3 ), 2, 'mod(5, 3) == 2';
    #
    diag 'might fail to clean up on Win32 because we have not released the lib yet... this is fine'
        if $^O eq 'MSWin32';
    system 'cargo clean --manifest-path=t/src/85_affix_mangle_rust/Cargo.toml --quiet';
}
#
done_testing;
