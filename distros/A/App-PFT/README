# App-PFT

PFT stands for *Plain F. Text*, where the meaning of *F.* is up to
personal interpretation. Like *Fancy* or *Fantastic*.

It is yet another static website generator. This means your content is
compiled once and the result can be served by a simple HTTP server,
without need of server-side dynamic content generation.

This project provides the command line tools needed for managing the blog
and compile it in web pages. It uses the library called
[PFT](https://github.com/dacav/pft) in order to obtain an abstraction over
the file system access.

# INSTALLATION

The canonical way of installing this module would be by means of the
following commands:

	perl Makefile.PL
	make
	make test
	make install

In reality you probably want to install `cpanminus` and just run `cpanm .`
in the directory obtained by extracting the tarball.

This module installs executable scripts for the command line, and it comes
with an extension of the bash completion system.  Such system is not
installed automatically in order to avoid collisions with the native
packaging system.

The file can be manually installed by copying the `bash_completion.d/pft`
file in the proper directory, whose path can be retrieved by running
`pkg-config --variable=completionsdir bash-completion`.  Usually this gets
expanded as `/usr/share/bash-completion/completions`.

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc App::PFT

This project however comes with a number of individually documented
executable scripts.  Each script comes with a manual page (e.g. `man pft
init`).

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PFT

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/App-PFT

    CPAN Ratings
        http://cpanratings.perl.org/d/App-PFT

    Search CPAN
        http://search.cpan.org/dist/App-PFT/


# LICENSE AND COPYRIGHT

Copyright (C) 2015 Giovanni Simoni

PFT is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your
option) any later version.

PFT is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with PFT.  If not, see <http://www.gnu.org/licenses/>.
