use Test::More;
use Test::Alien 0.05;
use Alien::libudev;

plan tests => 2;

alien_ok 'Alien::libudev';

BEGIN {
  plan skip_all => 'test requires Test::CChecker'
    unless eval q{ use Test::CChecker; 1 };
}

compile_with_alien 'Alien::libudev';

compile_output_to_note;

compile_run_ok do { local $/; <DATA> }, "compile basic ref and unref C code";

__DATA__
#include <libudev.h>
#include <stddef.h>
#include <stdlib.h>

int main(void) {
    struct udev *tree = udev_new();

    tree = udev_ref(tree);
    if (!tree) return EXIT_FAILURE;
    udev_unref(tree); tree = udev_unref(tree);
    return tree == NULL ? EXIT_SUCCESS : EXIT_FAILURE;
}
