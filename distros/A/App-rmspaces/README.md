## rmspaces

[![Build Status](https://travis-ci.org/athos-ribeiro/rmspaces.svg?branch=master)](https://travis-ci.org/athos-ribeiro/rmspaces)
[![CPAN version](https://badge.fury.io/pl/App-rmspaces.svg)](https://badge.fury.io/pl/App-rmspaces)

This is a simple script to remove those anoying, lame, awful spaces from file
names. Just run `rmspaces FILENAME`.

Note that it could also be used to change multiple file names by using the
--target and the --separator arguments. For example, if you have

```
$ ls
march_report  march_status  march_updates
```

`rmspaces -t march -s 032017 *`

would move the files in the current directory to:

```
$ ls
032017_report  032017_status  032017_updates
```

Check `rmspaces --help` for more information or check the docstrings in the
source code.

### Installing

#### From CPAN

You can install rmspaces from CPAN, available under
[App-rmspaces](http://search.cpan.org/~athos/App-rmspaces/)

cpanm
```
cpanm App::rmspaces
```

CPAN shell
```
perl -MCPAN -e shell
install App::rmspaces
```

#### From sources

You can install rmspaces from sources by running

```
perl Makefile.PL
make
make install
```

#### RPM package

A RPM package is also available in
[COPR](https://copr.fedorainfracloud.org/coprs/athoscr/extra/)

If using Fedora, you can run

```
sudo dnf copr enable athoscr/extra
sudo dnf install rmspaces
```

### Contributing

Just open a Pull Request if you have any improvements to this script. Also,
feel free to open issues in this repository.

### License

Copyright 2017 Athos Ribeiro <athoscr@fedoraproject.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
