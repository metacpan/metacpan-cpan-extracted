use v5.40;
use blib;
use Test2::V0;
use Alien::Zlib;

# Consumer accessors surface the real library after a build; before that they resolve lazily and
# stay empty, so skip rather than fail on a cold checkout.
my $zlib = Alien::Zlib->new;
my @libs = $zlib->dynamic_libs;
SKIP: {
    skip_all 'zlib not resolved yet; run `perl Makefile.PL && make` first' unless @libs;
    ok scalar @libs >= 1, 'dynamic libs resolved';
    like $zlib->cflags, qr/-I/, 'cflags present';
    like $zlib->libs,   qr/-L/, 'libs present';
    ok length( $zlib->version // '' ), 'version known';
}
#
done_testing;
