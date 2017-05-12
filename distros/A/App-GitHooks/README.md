App-GitHooks
============

[![Build Status](https://travis-ci.org/guillaumeaubert/App-GitHooks.svg?branch=master)](https://travis-ci.org/guillaumeaubert/App-GitHooks)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/App-GitHooks/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/App-GitHooks?branch=master)
[![CPAN](https://img.shields.io/cpan/v/App-GitHooks.svg)](https://metacpan.org/release/App-GitHooks)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

`App::GitHooks` is an extensible and easy to configure git hooks framework that
supports many plugins.


OVERVIEW
--------

 * Here's an example of it in action, running the `pre-commit` hook checks before
the commit message can be entered:

	![Successful checks](https://raw.github.com/guillaumeaubert/App-GitHooks/master/img/app-githooks-example-success.png)

 * Here is another example, with a Perl file that fails compilation this time:

	![Failing checks](https://raw.github.com/guillaumeaubert/App-GitHooks/master/img/app-githooks-example-failure.png)


INSTALLATION
------------

1. Install this distribution (with `cpanm` or your preferred CPAN client):

		cpanm App::GitHooks

2. Install the plugins you are interested in (with `cpanm`or your prefered CPAN
   client), as `App::GitHooks` does not bundle them. See the list of plugins
   below, but for example:

		cpanm App::GitHooks::Plugin::BlockNOCOMMIT
		cpanm App::GitHooks::Plugin::DetectCommitNoVerify
		...

3. Go to the git repository for which you want to set up git hooks, and run:

		githooks install

4. Enjoy!


OFFICIALLY SUPPORTED PLUGINS
----------------------------

 * [App::GitHooks::Plugin::BlockNOCOMMIT]
   (https://metacpan.org/pod/App::GitHooks::Plugin::BlockNOCOMMIT)

Prevent committing code with #NOCOMMIT mentions.

 * [App::GitHooks::Plugin::BlockProductionCommits]
   (https://metacpan.org/pod/App::GitHooks::Plugin::BlockProductionCommits)

Prevent commits in a production environment.

 * [App::GitHooks::Plugin::DetectCommitNoVerify]
   (https://metacpan.org/pod/App::GitHooks::Plugin::DetectCommitNoVerify)

Find out when someone uses --no-verify and append the pre-commit checks to the
commit message.

 * [App::GitHooks::Plugin::ForceRegularUpdate]
   (https://metacpan.org/pod/App::GitHooks::Plugin::ForceRegularUpdate)

Force running a specific tool at regular intervals.

 * [App::GitHooks::Plugin::MatchBranchTicketID]
   (https://metacpan.org/pod/App::GitHooks::Plugin::MatchBranchTicketID)

Detect discrepancies between the ticket ID specified by the branch name and the
one in the commit message.

 * [App::GitHooks::Plugin::PerlCompile]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PerlCompile)

Verify that Perl files compile without errors.

 * [App::GitHooks::Plugin::PerlCritic]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PerlCritic)

Verify that all changes and addition to the Perl files pass PerlCritic checks.

 * [App::GitHooks::Plugin::PerlInterpreter]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PerlInterpreter)

Enforce a specific Perl interpreter on the first line of Perl files.

 * [App::GitHooks::Plugin::PgBouncerAuthSyntax]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PgBouncerAuthSyntax)

Verify that the syntax of PgBouncer auth files is correct.

 * [App::GitHooks::Plugin::PrependTicketID]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PrependTicketID)

Derive a ticket ID from the branch name and prepend it to the commit-message.

 * [App::GitHooks::Plugin::RequireCommitMessage]
   (https://metacpan.org/pod/App::GitHooks::Plugin::RequireCommitMessage)

Require a commit message.

 * [App::GitHooks::Plugin::RequireTicketID]
   (https://metacpan.org/pod/App::GitHooks::Plugin::RequireTicketID)

Verify that staged Ruby files compile.

 * [App::GitHooks::Plugin::ValidatePODFormat]
   (https://metacpan.org/pod/App::GitHooks::Plugin::ValidatePODFormat)

Validate POD format in Perl and POD files.


CONTRIBUTED PLUGINS
-------------------

 * [App::GitHooks::Plugin::RubyCompile]
   (https://metacpan.org/pod/App::GitHooks::Plugin::RubyCompile)

Verify that staged Ruby files compile.

 * [App::GitHooks::Plugin::PreventTrailingWhitespace]
   (https://metacpan.org/pod/App::GitHooks::Plugin::PreventTrailingWhitespace)

Prevent trailing whitespace from being committed.


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

	perldoc App::GitHooks


You can also look for information at:

 * [GitHub's request tracker (report bugs here)]
   (https://github.com/guillaumeaubert/App-GitHooks/issues)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/App-GitHooks)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/App-GitHooks)

 * [MetaCPAN]
   (https://metacpan.org/release/App-GitHooks)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2013-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
