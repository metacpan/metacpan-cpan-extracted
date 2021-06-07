# NAME

Alien::GSL - Easy installation of the GSL library

# SYNOPSIS

```perl
# Build.PL
use Alien::GSL;
use Module::Build 0.28; # need at least 0.28

my $builder = Module::Build->new(
  configure_requires => {
    'Alien::GSL' => '1.00', # first Alien::Base-based release
  },
  ...
  extra_compiler_flags => Alien::GSL->cflags,
  extra_linker_flags   => Alien::GSL->libs,
  ...
);

$builder->create_build_script;


# lib/MyLibrary/GSL.pm
package MyLibrary::GSL;

use Alien::GSL; # dynaload gsl

...
```

# DESCRIPTION

Provides the Gnu Scientific Library (GSL) for use by Perl modules, installing it if necessary.
This module relies heavily on the [Alien::Base](https://metacpan.org/pod/Alien%3A%3ABase) system to do so.
To avoid documentation skew, the author asks the reader to learn about the capabilities provided by that module rather than repeating them here.

# COMPATIBILITY

Since version 1.00, [Alien::GSL](https://metacpan.org/pod/Alien%3A%3AGSL) relies on [Alien::Base](https://metacpan.org/pod/Alien%3A%3ABase).
Releases before that version warned about alpha stability and therefore no compatibility has been provided.
There were no reverse dependencies on CPAN at the time of the change.

From version 1.00, compability is provided by the [Alien::Base](https://metacpan.org/pod/Alien%3A%3ABase) project itself which is quite concerned about keeping stability.
Future versions are expected to maintain compatibilty and failure to do so is to be considered a bug.
Of course this does not apply to the GSL library itself, though the author expects that the GNU project will provide the compatibility guarantees for that library as well.

# SEE ALSO

- [Alien::Base](https://metacpan.org/pod/Alien%3A%3ABase)
- ["GNU SCIENTIFIC LIBRARY" in PDL::Modules](https://metacpan.org/pod/PDL%3A%3AModules#GNU-SCIENTIFIC-LIBRARY)
- [PerlGSL](https://metacpan.org/pod/PerlGSL)
- [Math::GSL](https://metacpan.org/pod/Math%3A%3AGSL)

# SOURCE REPOSITORY

[https://github.com/PerlAlien/Alien-GSL](https://github.com/PerlAlien/Alien-GSL)

# AUTHOR

Joel Berger, <joel.a.berger@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
