use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use v5.36;

# Regression test for the segfault syncing a union whose members overlap a
# String/pointer field with float data. The rope.pl SDL3 demo crashed when an
# SDL_Event (a union) had `motion.x/y` written and was then passed to
# SDL_PushEvent(): the argument sync (lazy_agg_set) read back *every* union
# member, and reading the inactive `drop.file` (Pointer[String]) dereferenced
# the motion floats (0x42c8...) as a C string pointer -> SIGSEGV.
#
# Members that are still bound to their original C slot are now skipped during
# the deep write (C memory already reflects them), so no garbage is read.
my $lib = compile_ok(<<'');
#include "std.h"
// ext: .c
int poke(void * p) { return 1; }

typedef 'Eventish' => Union [ motion => Struct [ x => Float, y => Float ], drop => Struct [ file => Pointer [String] ] ];
my $buf = Affix::malloc(64);
my $ev  = Affix::cast( $buf, Eventish() );
$ev->{motion}->{x} = 100;
$ev->{motion}->{y} = 100;
ok affix( $lib, 'poke', [ Pointer [ Eventish() ] ] => Int ), 'affix poke( Pointer [Eventish] )';
is poke($ev), 1, 'poke($ev) syncs the union without reading inactive members';

# A fresh hash assignment still writes plain data into the buffer.
$ev = { motion => { x => 7, y => 9 } };
is poke($ev),          1, 'poke({ ... }) writes plain hash members';
is $ev->{motion}->{x}, 7, 'x was written through the pin tree';
done_testing;
