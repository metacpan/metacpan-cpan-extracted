use v5.40;
use Affix;
use Affix::Build;

# Define some C code
my $c_source = <<'C_CODE';
#include <stdio.h>

typedef struct {
    int x;
    int y;
} Point;

// A function that takes a Struct and returns an Int
int area(Point p) {
    printf("[C] Calculating area for Point(%d, %d)\n", p.x, p.y);
    fflush(stdout);
    return p.x * p.y;
}
C_CODE

# Configure the builder
my $builder = Affix::Build->new(
    name  => 'geometry',
    debug => 1,            # Show compiler commands
);

# Add the source
say 'Compiling inline C code...';
$builder->add( \$c_source, lang => 'c' );

# Compile and Link
my $lib_path = $builder->compile_and_link();
say "Library compiled to: $lib_path";

# Bind and Call using Affix
# Define the Point struct definition in Perl
typedef Point => Struct [ x => Int, y => Int ];
#
affix $lib_path, 'area', [ Point() ] => Int;
#
my $result = area( { x => 10, y => 20 } );
say "Result from C: $result";
