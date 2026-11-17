# Consuming an Alien, and testing it

## The Alien's own cpanfile

```perl
requires 'Alien::Base' => '2.00';

on configure => sub {
  requires 'Alien::Build'     => '2.00';
  requires 'Alien::Build::MM' => '2.00';
};
on build => sub {
  requires 'Alien::Build'     => '2.00';
  requires 'Alien::Build::MM' => '2.00';
};
on test => sub {
  requires 'Test2::V0'   => 0;
  requires 'Test::Alien' => 0;
};
```

`Alien::Build` is needed at configure **and** at build time. A missing `on build`
block produces an Alien that configures and then fails to build on a clean machine —
and works everywhere the module happens to be installed already, which is every
machine you would test it on.

Any tool the share build shells out to belongs in `configure_requires` too, as
`Alien::*` where one exists (`Alien::cmake3`, `Alien::Autotools`) — the build plugin
adds those itself when it can.

## XS consumers

```perl
# Makefile.PL
use Alien::libssh;
WriteMakefile(
  NAME   => 'Net::LibSSH',
  LIBS   => [ Alien::libssh->libs ],
  INC    => Alien::libssh->cflags,
  OBJECT => 'LibSSH$(OBJ_EXT)',
);
```

The Alien belongs in **`configure_requires`**: `Makefile.PL` calls it, so it has to
be installed before that file runs. Listing it under `requires` is the mistake that
works on a machine where it is present and fails on every clean install.

`->cflags` and `->libs` are the flags for compiling and linking an XS module.
`->cflags_static` and `->libs_static` are their static-linking counterparts, which
differ only where the Alien recorded something different; `->dynamic_libs` returns
the paths of the shared objects themselves, which is what FFI wants rather than
linker flags.

Both return a single string. `shellwords` from `Text::ParseWords` splits them when a
list is needed.

## Dist::Zilla

Under `[@Author::GETTY]` neither side keeps a hand-written `Makefile.PL`:

```ini
[@Author::GETTY]
alien_build = 1                 ; in the Alien's dist.ini — Alien::Build::MM driven
```

```ini
[@Author::GETTY]
xs_alien  = Alien::libssh       ; in the consumer's — generates the block above
xs_object = LibSSH              ; only when the .xs basename differs from the Alien's
```

`xs_object` defaults to the last component of the Alien module name, which is right
only when the `.xs` file happens to be named that way. A hand-written `Makefile.PL`
left in the working directory of either distribution resolves its flags differently
from the released one — a green local `make test` then says nothing about what CPAN
will build. Details in `getty-perl-release-author-getty`.

## FFI consumers

```perl
use Alien::foo;
use FFI::Platypus;
my $ffi = FFI::Platypus->new(api => 2, lib => [ Alien::foo->dynamic_libs ]);
```

An FFI-facing Alien has to produce a shared library — `-DBUILD_SHARED_LIBS=ON` for
CMake, `--enable-shared` for autoconf (which `Build::Autoconf` passes by default).
A share build that only produced a `.a` returns an empty `dynamic_libs` list, and
the failure lands in the consumer as "library not found", far from its cause.

`runtime_prop->{ffi_name}` is the conventional place for a bare library name when
the consumer needs to find it by name rather than by path.

## Tool Aliens

An Alien that provides executables rather than a library gathers `bin_dir`, and
consumers run through it:

```perl
use Env qw( @PATH );
unshift @PATH, Alien::foo->bin_dir;
```

`bin_dir` returns an empty list for a system install, where the tool is already on
`PATH` — so the `unshift` is harmless either way, and code that assumes a single
directory is wrong.

## Test::Alien

`Test::Alien` compiles a real XS snippet against the flags the Alien just produced.
It is the only test that covers probe, build, gather and flags as one chain instead
of proving the module loads:

```perl
use Test2::V0;
use Test::Alien;
use Alien::libssh;

alien_ok 'Alien::libssh';

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libssh/libssh.h>

MODULE = MyAlienTest PACKAGE = MyAlienTest

int
can_ssh_new(klass)
    const char *klass
  CODE:
    ssh_session s = ssh_new();
    RETVAL = s ? 1 : 0;
    if (s) ssh_free(s);
  OUTPUT:
    RETVAL

END

xs_ok $xs, with_subtest {
  my ($module) = @_;
  ok $module->can_ssh_new, 'ssh_new() works via libssh';
};

done_testing;
```

**Call a function, do not just include the header.** A snippet that only includes
`<foo.h>` compiles against a library far older than the one you claim to require,
and the test passes on exactly the systems where the Alien is broken. Pick a
function that appeared in the version named in `minimum_version`.

Companions: `ffi_ok` for the FFI path, `run_ok` and `helper_ok` for tool Aliens,
`interpolate_template_is` for checking a `%{…}` expansion.

## Debugging an install

```bash
env ALIEN_INSTALL_TYPE=share  perl Makefile.PL   # force build-from-source
env ALIEN_INSTALL_TYPE=system perl Makefile.PL   # force the system library
```

An Alien developed on a machine that already has the library has never run its own
share build. Both paths belong in CI — they are different code, and the share path
is the one users on unusual platforms will take.

`_alien/` holds the build log and `alien.json` with the gathered properties. When a
consumer gets flags it did not expect, that file says what the Alien actually
recorded, which settles whether the bug is in the gather step or in the consumer.
