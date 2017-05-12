# tarcolor

A Perl program that can color the output of `tar tvf` similarly to the way GNU `ls` would.

By Marc Abramowitz (http://marc-abramowitz.com)

[![Build Status](https://secure.travis-ci.org/msabramo/tarcolor.png?branch=master)](http://travis-ci.org/msabramo/tarcolor)


## Installation

From [the CPAN distribution](http://search.cpan.org/~msabramo/App-TarColor/):

    $ cpanm App::TarColor

Download a tarball `App-TarColor-<version>.tar.gz` from [the downloads page](https://github.com/msabramo/tarcolor/downloads).

Or build a tarball from the repository using [Dist::Zilla](http://dzil.org/):

    $ dzil build

Install from the tarball with [cpanm (a.k.a.: App::cpanminus)](http://search.cpan.org/perldoc?cpanm):

    $ cpanm App-TarColor-<version>.tar.gz

Or untar the tarball and build it:

    $ tar xzf App-TarColor-<version>.tar.gz
    $ cd App-TarColor-<version>
    $ perl Makefile.PL
    $ make && make test

Then install it:

    $ make install

If you are installing into a system-wide directory, you may need to run:

    $ sudo make install


## Usage

You can use `tarcolor` manually like this:

	$ tar tvf some_tarball.tgz | tarcolor

There is also a bundled shell script (for bash and zsh) that makes `tar`
automatically pipe its output through `tarcolor`:

    $ source /usr/local/etc/tarcolor/tarcolorauto.sh
    $ tarcolorauto on
	$ tar tvf some_tarball.tgz
    ... colored output ...
    $ tarcolorauto off
	$ tar tvf some_tarball.tgz
    ... normal uncolored output ...


## Customization

Colors can be customized using the `LS_COLORS` or `TAR_COLORS` environment variables:

    $ export TAR_COLORS='di=01;34:ln=01;36:ex=01;32:so=01;40:pi=01;40:bd=40;33:cd=40;33:su=0;41:sg=0;46'

The format for `LS_COLORS` and `TAR_COLORS` is the same format used by `LS_COLORS` (used by [GNU ls](http://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html#ls-invocation)). So if you use GNU ls and have your `LS_COLORS` set, then tarcolor will use similar colors as ls.


## Example

![tarcolor screenshot](https://github.com/msabramo/tarcolor/raw/master/tarcolor_screenshot.png "tarcolor screenshot")

## Tested with

* Mac OS X 10.6.8 (Snow Leopard)
  * bsdtar 2.6.2 -- [libarchive](http://code.google.com/p/libarchive/) 2.6.2
  * [GNU tar](http://www.gnu.org/software/tar/) 1.17 in `/usr/bin/gnutar`
  * [GNU tar](http://www.gnu.org/software/tar/) 1.26 installed with Homebrew
  * [pax](http://en.wikipedia.org/wiki/Pax_\(Unix\)) -- `/bin/pax -v -f`
  * bsdcpio 1.1.0 -- [libarchive](http://code.google.com/p/libarchive/) 2.6.2 -- `cpio -itv < file.tar`

* Mac OS X 10.7 (Lion)
  * bsdtar 2.8.3 -- [libarchive](http://code.google.com/p/libarchive/) 2.8.3

* [OpenIndiana](http://openindiana.org/) b151A
  * [GNU tar](http://www.gnu.org/software/tar/) 1.23 (`/usr/gnu/bin/tar` or `/usr/bin/gtar`)
  * Solaris tar (`/usr/bin/tar`) (Fixed in [issue 11](https://github.com/msabramo/tarcolor/issues/11)).
  * [pax](http://en.wikipedia.org/wiki/Pax_\(Unix\)) -- `/usr/bin/pax -v -f`
  * Solaris cpio (`/usr/bin/cpio`) (Fixed in [issue 14](https://github.com/msabramo/tarcolor/issues/14)).
 
* CentOS 5.5/Linux 2.6.16.33
  * [GNU tar](http://www.gnu.org/software/tar/) 1.15.1
  * [GNU cpio](http://www.gnu.org/software/cpio/) 2.6 -- `cpio -itv < file.tar`
  * [pax](http://en.wikipedia.org/wiki/Pax_\(Unix\)) 3.4 -- `/bin/pax -v -f` (Fixed in [issue 13](https://github.com/msabramo/tarcolor/issues/13)).
  * [RPM](http://en.wikipedia.org/wiki/RPM_Package_Manager) 4.4.2.3 -- `rpm -qlpv file.rpm`

* Fedora 16
  * [GNU tar](http://www.gnu.org/software/tar/) 1.26

* Ubuntu 11.10
  * [GNU tar](http://www.gnu.org/software/tar/) 1.25
  * [Debian dpkg](http://en.wikipedia.org/wiki/Dpkg) 1.16.0.3 -- `dpkg --contents file.deb`

* Debian 4.4.5-8/Linux version 3.1.9-vs2.3.2.5 ([DreamHost](http://marc-abramowitz.com/go_dreamhost.php) VPS)
  * [GNU tar](http://www.gnu.org/software/tar/) 1.16
  * [GNU cpio](http://www.gnu.org/software/cpio/) 2.6 -- `cpio -itv < file.tar`
  * [Debian dpkg](http://en.wikipedia.org/wiki/Dpkg) 1.13.26 -- `dpkg --contents file.deb`

* FreeBSD 9.0
  * bsdtar 2.8.4 -- [libarchive](http://code.google.com/p/libarchive/) 2.8.4
  * [GNU tar](http://www.gnu.org/software/tar/) 1.26
  * [pax](http://en.wikipedia.org/wiki/Pax_\(Unix\)) -- `/bin/pax -v -f`
  * bsdcpio 2.8.4 -- [libarchive](http://code.google.com/p/libarchive/) 2.8.4 -- `cpio -itv < file.tar`

* Windows 7/Cygwin 1.7.11-1
  * [GNU tar](http://www.gnu.org/software/tar/) 1.25
  * bsdtar 2.8.3 -- [libarchive](http://code.google.com/p/libarchive/) 2.8.3
  * [GNU cpio](http://www.gnu.org/software/cpio/) 2.11 -- `cpio -itv < file.tar`
  * bsdcpio 2.8.3 -- [libarchive](http://code.google.com/p/libarchive/) 2.8.3 -- `cpio -itv < file.tar`
  * atool 0.38.0 -- `atool -l file.tar`


## Future enhancements (patches are welcome!)

* Send me your ideas (especially with patches!)
