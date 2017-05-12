App-GitHooks-Plugin-DetectCommitNoVerify
========================================

[![Build Status](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-DetectCommitNoVerify.svg?branch=master)](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-DetectCommitNoVerify)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/App-GitHooks-Plugin-DetectCommitNoVerify/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/App-GitHooks-Plugin-DetectCommitNoVerify?branch=master)
[![CPAN](https://img.shields.io/cpan/v/App-GitHooks-Plugin-DetectCommitNoVerify.svg)](https://metacpan.org/release/App-GitHooks-Plugin-DetectCommitNoVerify)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

App::GitHooks plugin to find out when someone uses --no-verify and append the
pre-commit checks to the commit message.


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

	perldoc App::GitHooks::Plugin::DetectCommitNoVerify


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/App-GitHooks-Plugin-DetectCommitNoVerify/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/App-GitHooks-Plugin-DetectCommitNoVerify)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/App-GitHooks-Plugin-DetectCommitNoVerify)

 * [MetaCPAN]
   (https://metacpan.org/release/App-GitHooks-Plugin-DetectCommitNoVerify)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2013-2016 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
