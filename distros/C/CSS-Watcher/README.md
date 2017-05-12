csswatcher [![Build Status](https://travis-ci.org/osv/csswatcher.png?branch=master)](https://travis-ci.org/osv/csswatcher)
=======

Generate completion suitable for [ac-html](https://github.com/cheunghy/ac-html),
[company-web](https://github.com/osv/company-web)

Used by [ac-html-csswatcher](https://github.com/osv/ac-html-csswatcher) project to provide emacs CSS, LESS class names completion.

## Installing

Using cpan:

```
sudo cpan i CSS::Watcher

```

Using cpanminus from source:

```shell
git clone https://github.com/osv/csswatcher.git
cd csswatcher
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
sudo cpanm -v -i .
```

or:

```
perl Makefile.PL
make
make test
sudo make install
```

More info after installation.

```shell
man csswatcher
```

## File .csswatcher

May be used like .projectile or .git for setting project home directory and
setup ignored files:

```shell
% cat .csswatcher
# ignore minified css files "min.css"
ignore: min\.css$
# ignore bootstrap css files
ignore: bootstrap.*css$
# skip recursive scanning node_modules, it may be slow!
skip: node_modules
```

Another example:

```shell
% cat .csswatcher
# ignore all css except app.css
ignore: \.css$
use: app\.css
# and skip recursive scanning node_modules, it may be slow!
skip: node_modules
```

See also https://github.com/osv/ac-html-csswatcher
