Bio::PhyloXS - Core Bio::Phylo in XS/C
======================================
This distribution overrides some of the core modules of 
Bio::Phylo in the C programming language (technically, 
using a type of glue code called XS). Used correctly and
under the right circumstances, this can speed up a lot 
scripts by an order of magnitude or more.

Requires
--------
* Bio::Phylo v0.52 or later
* The toolkit for installing XS modules, i.e. a C compiler,
  the `make` program, the right headers, etc. As a rule of
  thumb, this will not work on Windows unless you use 
  something like Cygwin. Other operating systems, such as
  Mac OSX (with the Developer Tools) and Linux are quite 
  likely to work.

Installation
------------
This package can be installed in the standard ways, e.g. 
using the `ExtUtils::MakeMaker` workflow:

    $ perl Makefile.PL
    $ make
    $ sudo make install

BUGS
----
Please report any bugs or feature requests on the GitHub bug tracker:

https://github.com/rvosa/bio-phylo-xs/issues
