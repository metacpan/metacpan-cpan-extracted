# NAME

App::nodie - runs command again when its dead

# VERSION

version 1.03

# SYNOPSIS

        #!/bin/sh
        perl -MApp::nodie -erun -- command arg1 arg2 ...

# DESCRIPTION

App::nodie runs command again when its dead.

See also: [nodie.pl](https://metacpan.org/pod/distribution/App-nodie/lib/App/nodie/nodie.pl)

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i App::nodie

# DEPENDENCIES

This module requires these other modules and libraries:

- Scalar::Util
- Lazy::Utils

# REPOSITORY

**GitHub** [https://github.com/orkunkaraduman/App-nodie](https://github.com/orkunkaraduman/App-nodie)

**CPAN** [https://metacpan.org/release/App-nodie](https://metacpan.org/release/App-nodie)

# AUTHOR

Orkun Karaduman (ORKUN) &lt;orkun@cpan.org&gt;

# COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman &lt;orkunkaraduman@gmail.com&gt;

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/&gt;.
