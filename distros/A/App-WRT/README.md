wrt
===

wrt (WRiting Tool) is a static site / blog generator and some related
utilities.

This project can be thought of as both a format for storing blog entries and
other writing in folders and files, as well as the utilities for rendering them
to a full-fledged web site.  It's particularly well-suited to collections of
blog entries organized by date.

wrt can be found at:

  - [metacpan.org as App::WRT](https://metacpan.org/pod/App::WRT) - latest CPAN release
  - https://code.p1k3.com/gitea/brennen/wrt - latest code

I have been using some version of this code to publish [p1k3][p1k3] since 2001,
and have written [various posts about it][p1k3-wrt] over the years.

[p1k3]: https://p1k3.com/
[p1k3-wrt]: https://p1k3.com/topics/wrt/

installation and use
====================

You'll need a Unix / Linux, and a relatively recent Perl installation.  In
practice I know that Debian Jessie or later (or Ubuntu 16.04 or later) and Perl
5.26.1 work.

The short version, CPAN edition:

```sh
cpan -i App::WRT
```

The short version, git edition:

```sh
git clone https://code.p1k3.com/gitea/brennen/wrt.git
cd wrt
perl Build.PL
./Build installdeps
./Build test
./Build install
```

Starting a new site once installed:

```sh
# Set up some defaults:
mkdir project && cd project
wrt init

# Create an entry for January 1, 2019:
mkdir -p archives/2019/1/
nano archives/2019/1/1

# Publish HTML to project/public/
wrt render-all
```

Please see the [App::WRT listing on MetaCPAN][mc] or the POD documentation in
[lib/App/WRT.pm](lib/App/WRT.pm) in this repository for detailed instructions.

[mc]: https://metacpan.org/pod/App::WRT

security
========

A cautionary note that, since wrt templates and entries can contain embedded
Perl, running this code against untrusted input is effectively the same as
executing an arbitrary script.  There may be _other_ issues with running it
against an untrusted archive (I make no promises) but it's probably not worth
worrying about them in light of the `<perl>` feature.

This shouldn't worry you if you're generating a static site of your own.  Just
don't (for example) create a service that uses it to publish sites for users
you don't already trust to run code on your systems.

wrt-as-a-service might be something I explore in future, but it will need
some tweaking first.

copying
=======

wrt is copyright 2001-2020 Brennen Bearnes.

wrt is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/
