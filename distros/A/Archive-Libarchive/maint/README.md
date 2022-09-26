# Reference libarchive docker image

Because `libarchive` contains a large number of functions (400+ as of this writing),
and because maintaining individual function bindings is tedious and error-prone;
development for `Archive-Libarchive` uses code generation to generate bindings and
documentation for most methods.  Only the methods that require Perl wrappers, or need
type subtle type conversions are implemented manually.  Files that are generated
automatically should have a comment indicating that they should not be updated directly.

To keep things consistent and reliable, we maintain a reference build of the oldest
and most recently supported versions of `libarchive` in a docker image. This means that
we can keep track of which functions are "optional", that is are available in at least
some versions that we support, but not the oldest version. We use `Const::Introspect::C`
and `Clang::CastXML` to extract constants and function signatures (respectively) from
`libarchive`.  You do not need to install those modules locally, because they are
installed in the docker image.  The introspection also loads the `Archive-Libarchive`
to keep track of which function bindings are implemented manaully, to ensure that
automatic bindings are not created for manually maintained bindings.  CI also runs
the test suite against the oldest and newest versions of `libarchive`, so the
reference docker container should have all the prerequisites (optional and required)
for `Archive-Libarchive`.

If you are just modifying manually maintained bindings or adding tests then you
should not need to use the reference docker image (unless you want to test with one
of the reference builds; though this is porbably only necessary if CI fails with one
of these builds).  If you are replacing automatically generated bindings, or making
changes to the introspection code itself you will have to use the reference docker
image.

Here are the steps:

 * If you need to modify the reference docker image itself (adding prerequisites, or
   updating to a new version of Debian), run `./maint/ref-build` to build the new
   image locally.  (If you are also the `Archive-Libarchive` maintainer you will
   want to run `./maint/ref-push` to push the image to dockerhub, once you are sure
   the image is correct).

 * Run the introspection and code generation script: `./maint/ref-update`.

 * If changes were made to `lib/Archive/Libarchive.pm` POD then you will then want
   to run `dzil build` to update the README.md in the project root.  (you can
   install `Dist::Zilla` by running `cpanm Dist::Zilla && dzil authordeps | cpanm && dzil listdeps | cpanm`).

 * It is advisable to run the test suite against the old and new versions of
   `libarchive`, since CI will do that and your PR will not be merged unless CI
   passes.  To run the test suite against the old and new versions, run `./maint/ref-test`.

 * Submit your PR!

Some other useful tools:

 * `./maint/ref-config` contains configuration items, such as the old, new and unsupported
   versions of `libarchive` (we also build an unsupported version immediately prior to
   the old version to find symbols that we need to check for during install to make sure
   that `libarchive` is at least up to the old version; if you bump the old version,
   make sure you bump the unsupported version).  If you bump either the old or new version
   you will need to rebuild the reference docker image.

 * `./maint/ref-exec` will run a command in the reference docker image.

 * `./maint/ref-shell` will give you a shell inside the reference docker image.  This can
   be useful for debugging build or run problems.

 * `./maint/ref-symbols` will list the symbols in the unsupported, old and new versions of
   `libarchive`.

 * `castxml` and `castyml` run from inside the `ref-shell` will dump a C header file using
   `libclang`.  The latter will restore some of the hierarchy to the function argument
   types, which can be helpful in debugging the function introspection.  Example:
   `castyml /usr/include/archive.h` or `castyml /usr/include/archive_entry.h`.
