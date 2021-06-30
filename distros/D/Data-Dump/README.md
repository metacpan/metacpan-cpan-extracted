Data::Dump
==========

This module provides a few functions that traverse their
argument list and return a string containing Perl code that,
when C<eval>ed, produces a deep copy of the original arguments.

The main feature of the module is that it strives to produce output
that is easy to read.  Example:

```perl
    @a = (1, [2, 3], {4 => 5});
    dump(@a);
```

Produces:

```perl
    "(1, [2, 3], { 4 => 5 })"
```

If you dump just a little data, it is output on a single line. If
you dump data that is more complex or there is a lot of it, line breaks
are automatically added to keep it easy to read.

Please refer to [Data::Dump's complete documentation](https://metacpan.org/pod/Data::Dump)
for details on how to use this module, including which funcions it
exports. Or (after installation) type:

    perldoc Data::Dump

To view the complete docs on your terminal.


Installation
------------

To install this module via cpanm:

    > cpanm Data::Dump

Or, at the cpan shell:

    cpan> install Data::Dump

If you wish to install it manually, download and unpack the tarball and
run the following commands:

	perl Makefile.PL
	make
	make test
	make install

Of course, instead of downloading the tarball you may simply clone the
git repository:

    $ git clone git://github.com/garu/Data-Dump.git



LICENSE AND COPYRIGHT
---------------------

The "Data::Dump" module is written by Gisle Aas <gisle@aas.no>, based on
"Data::Dumper" by Gurusamy Sarathy <gsar@umich.edu>.

Copyright 1998-2010 Gisle Aas.
Copyright 1996-1998 Gurusamy Sarathy.

This distribution is currenly maintained by Breno G. de Oliveira.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.
