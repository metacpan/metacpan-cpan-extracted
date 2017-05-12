App-GitHooks-Plugin-MatchBranchTicketID
=======================================

[![Build Status](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID.svg?branch=master)](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID?branch=master)
[![CPAN](https://img.shields.io/cpan/v/App-GitHooks-Plugin-MatchBranchTicketID.svg)](https://metacpan.org/release/App-GitHooks-Plugin-MatchBranchTicketID)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

App::GitHooks plugin to detect discrepancies between the ticket ID specified by
the branch name and the one in the commit message.


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

	perldoc App::GitHooks::Plugin::MatchBranchTicketID


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/App-GitHooks-Plugin-MatchBranchTicketID)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/App-GitHooks-Plugin-MatchBranchTicketID)

 * [MetaCPAN]
   (https://metacpan.org/release/App-GitHooks-Plugin-MatchBranchTicketID)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2013-2016 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
