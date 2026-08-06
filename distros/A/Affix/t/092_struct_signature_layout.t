use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
#
# Regression test for struct member layout when a struct type is declared
# inline in a function signature (as opposed to a typedef-registered type).
#
# Structs inside function signatures used to keep the offsets computed at
# parse time, while their members were still unresolved named types (size 0).
# The layout-recalc pass (Layout stage) never descended into function
# signatures, so every member ended up at the same offset. Bindings such as
# libpng's `png_image_write_to_file` then read/wrote members at the wrong
# bytes (version read back as 0, libpng complained about the struct layout).
#
# The struct below mirrors png_image's shape: a leading member that pushes
# the following scalar fields off offset 0, and fields typed through a named
# type so they are unresolved until the Resolve stage.
my $c_source = <<'END_C';
#include "std.h"
//ext: .c

#include <stdbool.h>
#include <stddef.h>

typedef unsigned int png_uint_32;

typedef struct {
    void *      opaque;
    png_uint_32 version;
    png_uint_32 width;
    png_uint_32 height;
    png_uint_32 format;
    png_uint_32 flags;
} png_image;

DLLEXPORT bool set_image(png_image * out, png_uint_32 version, png_uint_32 width,
                         png_uint_32 height, png_uint_32 format, png_uint_32 flags) {
    if (!out)
        return false;
    out->version = version;
    out->width   = width;
    out->height  = height;
    out->format  = format;
    out->flags   = flags;
    return true;
}

DLLEXPORT bool check_image(const png_image * in) {
    if (!in)
        return false;
    return in->version == 1 && in->width == 2 && in->height == 3 && in->format == 4 && in->flags == 5;
}

DLLEXPORT size_t image_sizeof(void) { return sizeof(png_image); }
END_C
#
my $lib = compile_ok($c_source);
ok( $lib, "Library compiled at $lib" );
#
typedef png_uint_32 => Int;
#
# The struct is anonymous (declared inline in the signature), so it is laid
# out by the signature's Layout stage, not by the type registry.
my $sig = Struct [
    opaque  => Pointer [Void],
    version => png_uint_32(),
    width   => png_uint_32(),
    height  => png_uint_32(),
    format  => png_uint_32(),
    flags   => png_uint_32(),
];
#
subtest 'struct declared inline in signature' => sub {
    isa_ok my $set = wrap( $lib, 'set_image', [ Pointer [$sig], png_uint_32(), png_uint_32(), png_uint_32(), png_uint_32(), png_uint_32() ] => Bool ),
        ['Affix'];
    isa_ok my $check    = wrap( $lib, 'check_image',  [ Pointer [$sig] ] => Bool ),   ['Affix'];
    isa_ok my $c_sizeof = wrap( $lib, 'image_sizeof', []                 => Size_t ), ['Affix'];

    # Layout must match C's sizeof(png_image): opaque(8) + 5 * uint32(4) = 28, padded to 32.
    is sizeof($sig), $c_sizeof->(), 'inline signature struct has the correct sizeof';
    is sizeof($sig), 32,            'inline signature struct sizeof is 32';
    my $h = { version => 1, width => 2, height => 3, format => 4, flags => 5 };
    ok $set->( $h, 1, 2, 3, 4, 5 ), 'set_image writes all fields at the correct offsets';
    is $h->{version}, 1, 'version written back';
    is $h->{width},   2, 'width written back';
    is $h->{height},  3, 'height written back';
    is $h->{format},  4, 'format written back';
    is $h->{flags},   5, 'flags written back';
    ok $check->( { version => 1, width => 2, height => 3, format => 4, flags => 5 } ), 'check_image reads hashref from the correct offsets';
};
#
done_testing;
