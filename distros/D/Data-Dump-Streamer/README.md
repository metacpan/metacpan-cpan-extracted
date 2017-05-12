## INSTALLATION
    To install this module type the following:

```
      perl Build.PL
      ./Build
      ./Build test
      ./Build install
```

    The modules requires a functional C compiler, however PPM support
    for Win32 users will also be available sometime soon.

    It is known to work correctly on Perl 5.6 and later on both Win32
    and *nix operating systems. Not all 5.8.x features are available
    in 5.8.0

## DEPENDENCIES
    This module requires these other modules and libraries:

     * Module::Build
     * ExtUtils::Depends
     * B::Utils

    and optionally for enhanced testing

      Algortihm::Diff and later versions of Data::Dumper

    All other dependencies are part of the standard distribution as
    of Perl 5.6.

## AUTHOR AND COPYRIGHT
    Yves Orton, (demerphq)

    Copyright (C) 2003 Yves Orton  2003-2005

    This library is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

    Contains code derived from works by Gisle Aas, Graham Barr,
    Jeff Pinyan, Richard Clamp, and Gurusamy Sarathy as well as
    material taken from the core.
