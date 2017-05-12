Installing the Clownfish compiler with Perl bindings
====================================================

To install the Clownfish compiler as a suite of Perl modules, run the
following commands:

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

The Clownfish compiler is built with a bundled version of libcmark by
default. If you want to link against the system libcmark, run Build.PL
with `--with_system_cmark=1`:

    perl Build.PL --with_system_cmark=1

If ExtUtils::PkgConfig is installed, it is used to retrieve information
about the system cmark library. Otherwise, only `-lcmark` is added to
the extra linker flags. In this case, you may have to provide additional
flags with `--extra-compiler-flags` and `--extra-linker-flags`.

