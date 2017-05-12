App-GitHooks-Plugin-ForceBranchNamePattern
==========================================

[![Build Status](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-ForceBranchNamePattern.svg?branch=master)](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-ForceBranchNamePattern)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/App-GitHooks-Plugin-ForceBranchNamePattern/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/App-GitHooks-Plugin-ForceBranchNamePattern?branch=master)
[![CPAN](https://img.shields.io/cpan/v/App-GitHooks-Plugin-ForceBranchNamePattern.svg)](https://metacpan.org/release/App-GitHooks-Plugin-ForceBranchNamePattern)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

App::GitHooks plugin to force pushed branch names to match a given pattern.


MINIMUM GIT VERSION
-------------------

This plugin relies on the pre-push hook, which is only available as of git
v1.8.2.


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

	perldoc App::GitHooks::Plugin::ForceBranchNamePattern


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/App-GitHooks-Plugin-ForceBranchNamePattern/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/App-GitHooks-Plugin-ForceBranchNamePattern)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/App-GitHooks-Plugin-ForceBranchNamePattern)

 * [MetaCPAN]
   (https://metacpan.org/release/App-GitHooks-Plugin-ForceBranchNamePattern)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2015-2016 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
