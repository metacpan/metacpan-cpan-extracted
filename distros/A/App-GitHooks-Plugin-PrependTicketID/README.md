App-GitHooks-Plugin-PrependTicketID
===================================

[![Build Status](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-PrependTicketID.svg?branch=master)](https://travis-ci.org/guillaumeaubert/App-GitHooks-Plugin-PrependTicketID)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/App-GitHooks-Plugin-PrependTicketID/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/App-GitHooks-Plugin-PrependTicketID?branch=master)
[![CPAN](https://img.shields.io/cpan/v/App-GitHooks-Plugin-PrependTicketID.svg)](https://metacpan.org/release/App-GitHooks-Plugin-PrependTicketID)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

App::GitHooks plugin to derive a ticket ID from the branch name and prepend it
to the commit-message.


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

	perldoc App::GitHooks::Plugin::PrependTicketID


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/App-GitHooks-Plugin-PrependTicketID/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/App-GitHooks-Plugin-PrependTicketID)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/App-GitHooks-Plugin-PrependTicketID)

 * [MetaCPAN]
   (https://metacpan.org/release/App-GitHooks-Plugin-PrependTicketID)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2013-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
