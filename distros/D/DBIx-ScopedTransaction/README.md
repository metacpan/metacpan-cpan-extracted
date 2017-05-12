DBIx-ScopedTransaction
======================

[![Build Status](https://travis-ci.org/guillaumeaubert/DBIx-ScopedTransaction.svg?branch=master)](https://travis-ci.org/guillaumeaubert/DBIx-ScopedTransaction)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/DBIx-ScopedTransaction/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/DBIx-ScopedTransaction?branch=master)
[![CPAN](https://img.shields.io/cpan/v/DBIx-ScopedTransaction.svg)](https://metacpan.org/release/DBIx-ScopedTransaction)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

DBIx::ScopedTransaction is a module that allows scoping database transactions
on DBI handles in code, to detect and prevent issues with unterminated
transactions.


INSTALLATION
------------

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

	perldoc DBIx::ScopedTransaction


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/DBIx-ScopedTransaction/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/DBIx-ScopedTransaction)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/DBIx-ScopedTransaction)

 * [MetaCPAN]
   (https://metacpan.org/release/DBIx-ScopedTransaction)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
