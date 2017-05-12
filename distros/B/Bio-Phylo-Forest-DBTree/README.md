Bio::Phylo::Forest::DBTree
==========================
An object-oriented API to operate on very large phylogenies stored in portable databases

Requires
--------
* Bio::Phylo v0.52 or later
* DBIx::Class
* DBD::SQLite
* An installation of `sqlite3`

Installation
------------
This package can be installed in the standard ways, e.g. using the `ExtUtils::MakeMaker`
workflow:

    $ perl Makefile.PL
    $ make
    $ sudo make install

Alternatively, the `cpanm` workflow can be used to install directly from github, i.e.

    $ sudo cpanm git://github.com/rvosa/bio-phylo-forest-dbtree.git

BUGS
----
Please report any bugs or feature requests on the GitHub bug tracker:

https://github.com/rvosa/bio-phylo-forest-dbtree/issues

BUILD STATUS
------------
Currently, the build status at Travis is:

[![Build Status](https://travis-ci.org/rvosa/bio-phylo-forest-dbtree.svg?branch=master)](https://travis-ci.org/rvosa/bio-phylo-forest-dbtree)
