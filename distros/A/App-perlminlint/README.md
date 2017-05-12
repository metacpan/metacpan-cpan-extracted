perlminlint - smart "perl -wc" wrapper[![Build Status](https://travis-ci.org/hkoba/app-perlminlint.svg?branch=master)](https://travis-ci.org/hkoba/app-perlminlint)
====================

`perlminlint` is a simple wrapper of `perl -wc` with better automatic
`@INC` settings and plugins for specific files like `*.t`, `cpanfile`,
aimed at easing integration of lint functionality into editors.

SYNOPSIS
--------------------

```sh
% perlminlint  myscript.pl
#  => This tests "perl -wc myscript.pl"

% perlminlint  MyModule.pm
#  => This tests "perl -MMyModule -we0"

% perlminlint  MyInnerModule.pm
#  => This tests "perl -I.. -MMyApp::MyInnerModule -we0"

% perlminlint  cpanfile
#  => This tests Module::CPANfile->load

% perlminlint -w -c -wc myscript.pl
# -w, -c and -wc are just ignored for 'perl -wc' compatibility.
```

Editor Integration
--------------------

### Emacs

#### Flycheck

You may be able to use perlminlint with
[Flycheck](http://flycheck.readthedocs.org/en/latest/index.html),
but you must modify default perl handler in flycheck.
This is described in 
[flycheck-perlminlint/README.md](flycheck-perlminlint/README.md)


#### perl-minlint-mode (Bundled)

perlminlint is distributed with [perl-minlint-mode](./elisp/README.md).
In this mode, perlminlint is called automatically whenever you save 
your perl script.
Also you can run perlminlint manually by hitting `<F5>`.
If your script has an error, cursor will jump to the position.

perl-minlint-mode supports 
[tramp mode](http://www.emacswiki.org/emacs/TrampMode), so
you can safely lint remote files too 
if you install perlminlint on your remote hosts.

### Vim

Not yet completed, but proof of concept code exists.
See [vim/perl-minlint.vim](vim/perl-minlint.vim).


Plugin API
--------------------

You can add your own plugins to your `bin/../lib/App/perlminlint/Plugin`,
which can be written like following:

```perl
package App::perlminlint::Plugin::LintCPANfile;
use strict;
use warnings FATAL => qw/all/;

use App::perlminlint::Plugin -as_base;

use Module::CPANfile;

sub handle_match {
  my ($plugin, $fn) = @_;
  $fn =~ m{\bcpanfile\z}i
    and $plugin;
}

sub handle_test {
  my ($plugin, $fn) = @_;

  Module::CPANfile->load($fn)
    and "CPANfile $fn is OK";
}

1;
```

### Plugin search order.

* `perlminlint.lib`
* `dirname(perlminlin)/lib`
* `$FindBin::Bin/../lib`
* `$FindBin::RealBin/../lib`
* Then ordinally `@INC`.

INSTALLATION
--------------------

perlminlint is now on CPAN (as App::perlminlint), so you can install it
like other modules:

```sh
$ cpanm App::perlminlint
```

Alternatively, you can just clone from git repository
and make a symlink to it.
For example, if you have `~/bin` in your PATH, you can 
install perlminlint like following:

```sh
cd ~/bin
git clone https://github.com/hkoba/app-perlminlint.git
ln -s app-perlminlint/script/perlminlint .
```

* For Emacs, please read [this instruction](./elisp/README.md).

LICENSE
--------------------
This software is licensed under the same terms as Perl.

AUTHOR
--------------------
CPAN ID: HKOBA
