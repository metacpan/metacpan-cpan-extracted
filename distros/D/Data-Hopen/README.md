# Data::Hopen - A dataflow library with first-class edges

[![Appveyor Badge](https://ci.appveyor.com/api/projects/status/github/hopenbuild/data-hopen?svg=true)](https://ci.appveyor.com/project/cxw42/data-hopen)



`Data::Hopen` is a dataflow library that runs actions you specify, moves data
between those actions, and permits transforming data as the data moves.  It is
the underlying engine of the [App::hopen](https://metacpan.org/pod/App::hopen) cross-platform software build
generator, but can be used for any dataflow task that can be represented as a
directed acyclic graph (DAG).

# INSTALLATION

Easiest: install `cpanminus` if you don't have it - see
[https://metacpan.org/pod/App::cpanminus#INSTALLATION](https://metacpan.org/pod/App::cpanminus#INSTALLATION).  Then run
`cpanm Data::Hopen`.

Manually: clone or untar into a working directory.  Then, in that directory,

    perl Makefile.PL
    make
    make test

(you may need to install dependencies as well -
see [https://www.cpan.org/modules/INSTALL.html](https://www.cpan.org/modules/INSTALL.html) for resources).
If all the tests pass,

    make install

If some of the tests fail, please check the issues and file a new one if
no one else has reported the problem yet.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Hopen
    perldoc hopen

You can also look for information at:

- GitHub (report bugs here)

    [https://github.com/cxw42/hopen](https://github.com/cxw42/hopen)

- MetaCPAN

    [https://metacpan.org/release/Data-Hopen](https://metacpan.org/release/Data-Hopen)

# INSPIRED BY

- [Luke](https://github.com/gvvaughan/luke)
- a bit of [Ant](https://ant.apache.org/)
- a tiny bit of [Buck](https://buckbuild.com/concept/what_makes_buck_so_fast.html)
- my own frustrations working with CMake.

# LICENSE AND COPYRIGHT

Copyright (C) 2018--2019 Christopher White, `<cxwembedded at gmail.com>`

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
