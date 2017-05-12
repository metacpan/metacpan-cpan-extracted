Alien::Prototype automatically installs ths Prototype JS library

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

Please note that Prototype comes with its own license.

To install:
    perl Build.PL
    ./Build
    ./Build test
    ./Build install

NOTE: You -MUST- have Module::Build present to install this module; the
fallback methods provided by CPANPLUS and Module::Build::Compat are
insufficient.

If fetching Prototype fails, placing a manually downloaded copy of the archive
inside the build directory will allow your build to proceed.
