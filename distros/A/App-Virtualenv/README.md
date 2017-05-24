# NAME

App::Virtualenv - Perl virtual environment

# VERSION

version 2.07

# SYNOPSIS

        #!/bin/sh
        perl -MApp::Virtualenv -erun -- environment_path

# DESCRIPTION

App::Virtualenv is a Perl package to create isolated Perl virtual environments, like Python virtual environment.

See also: [virtualenv.pl](https://metacpan.org/pod/distribution/App-Virtualenv/lib/App/Virtualenv/virtualenv.pl)

# Functions

## sh(@args)

runs shell program defined in SHELL environment variable, otherwise /bin/sh

@args: _arguments of shell program_

return value: _exit code of shell program_

## perl(@args)

runs Perl interpreter

@args: _arguments of Perl interpreter_

return value: _exit code of Perl interpreter_

## activate($virtualenv\_path)

activates Perl virtual environment

$virtualenv\_path: _virtual environment path_

return value: _virtual environment path if success, otherwise undef_

## deactivate($nondestructive)

deactivates Perl virtual environment

$nondestructive: _leaves envionment variables as it is, unless there are old envionment variables_

return value: _always 1_

## create($virtualenv\_path, $empty)

creates Perl virtual environment

$virtualenv\_path: _new virtual environment path_

$empty: _create empty virtual environment_

return value: _virtual environment path if success, otherwise undef_

## find\_virtualenv\_path($virtualenv\_path)

finds Perl virtual environment path by $virtualenv\_path argument or activated virtual environment or running script or PERL5LIB environment variable

$virtualenv\_path: _virtual environment path_

return value: _best matching virtual environment path_

## activate2($virtualenv\_path, $inform)

activates Perl virtual environment by find\_virtualenv\_path function

$virtualenv\_path: _virtual environment path_

$inform: _informs activated virtual environment path to STDERR if new activated path differs old one, by default 0_

return value: _activated best matching virtual environment path if success, otherwise undef_

## getinc($virtualenv\_path)

gets array ref of include paths given virtual environment path or sitelib paths

$virtualenv\_path: _virtual environment path_

return value: _array ref of paths_

## list(%params)

lists packages or modules or files by given %params

%params: _parameters of function_

> one: _output is one-column, by default 0_
>
> detail: _prints additional detail by given value(&#39;module&#39; or &#39;file&#39;), by default undef_

return value: _always 1_

## main(@argv)

App::Virtualenv main function to run on command-line

See also: [virtualenv.pl](https://metacpan.org/pod/distribution/App-Virtualenv/lib/App/Virtualenv/virtualenv.pl)

@argv: _command-line arguments_

return value: _exit code of program_

## run

runs App::Virtualenv by main function with command-line arguments by @ARGV

return value: _function doesn&#39;t return, exits with main function return code_

# PREVIOUS VERSION

Previous version of App::Virtualenv has include PiV(Perl in Virtual environment) to list/install/uninstall modules
using CPANPLUS API. Aimed with PiV making a package manager like Python pip. But Perl has various powerful package tools
mainly CPAN and cpanminus, CPANPLUS and etc. And also building a great package manager requires huge community support.
So, PiV is deprecated in version 2.xx.

You should uninstall previous version before upgrading from v1.xx: **cpanm -U App::Virtualenv; cpanm -i App::Virtualenv;**

See also: [App::Virtualenv 1.13](https://metacpan.org/release/ORKUN/App-Virtualenv-1.13)

## Deprecated Modules

- App::Virtualenv::Piv
- App::Virtualenv::Module
- App::Virtualenv::Utils

# INSTALLATION

To install this module type the following

        perl Makefile.PL
        make
        make test
        make install

from CPAN

        cpan -i App::Virtualenv

You should uninstall previous version before upgrading from v1.xx: **cpanm -U App::Virtualenv; cpanm -i App::Virtualenv;**

# DEPENDENCIES

This module requires these other modules and libraries:

- local::lib
- ExtUtils::Installed
- CPAN
- Cwd
- Lazy::Utils

# REPOSITORY

**GitHub** [https://github.com/orkunkaraduman/perl5-virtualenv](https://github.com/orkunkaraduman/perl5-virtualenv)

**CPAN** [https://metacpan.org/release/App-Virtualenv](https://metacpan.org/release/App-Virtualenv)

# SEE ALSO

- [App::Virtualenv 1.13](https://metacpan.org/release/ORKUN/App-Virtualenv-1.13)
- [CPAN](https://metacpan.org/pod/CPAN)
- [App::cpanminus](https://metacpan.org/pod/App::cpanminus)
- [CPANPLUS](https://metacpan.org/pod/CPANPLUS)

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
