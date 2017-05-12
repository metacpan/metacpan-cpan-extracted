# DBI::Test - The DBI/DBD API Test Suite

[![Build Status](https://travis-ci.org/perl5-dbi/DBI-Test.png?branch=master)](https://travis-ci.org/perl5-dbi/DBI-Test)

## Description

This module aims at a transparent test suite for the DBI API
to be used from both sides of the API (DBI and DBD) to check
if the provided functionality is working and complete.

## Copying

Copyright (C) 2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

Recent changes can be (re)viewed in the public GIT repository at
GitHub https://github.com/perl5-dbi/DBI-Test
Feel free to fork and/or clone your own copy:

   $ git clone https://github.com/perl5-dbi/DBI-Test.git DBI-Test

## Contributing

We share our thoughts on the following public channels:

1. DBI development mailing list - http://lists.perl.org/list/dbi-dev.html

2. IRC: irc.perl.org/6667 #dbi

## Build/Installation

Though this module should validate against itself, its use is
only visible when used as subset of the testsuite for DBI or a
DBD.

## Authors

This module is a team-effort. The current team members are

* H.Merijn Brand  (Tux)
* Jens Rehsack    (Sno)
* Peter Rabbitson (ribasushi)
* Joakim Tørmoen  (trmjoa)

## Some background and plans

Several of use DBI/DBD developers were playing with an idea for a long
time to come to a new way of testing DBI and DBD and especially the API
as defined by the DBI.

We have noticed in several occasions that the DBI defines the API,
where testing the API is hard because there is not (yet) an actual
database on the backend (no functional DBD) and from the other side
(the DBD) some of these tests are quite the same, just to test if the
API as documented from the DBI is working as expected from the DBD
point of view.

The plan has grown to create a new module that would replace the API
tests in the DBI test suite and that can also be used without
modification in the DBD test suites.

This way we can assure that all documented API is tested the same way
from both sides. As a bonus, we can have the DBD check that ALL DBI
functionality is implemented (or documented not to be) and that all
functionality (like logging) are dealt with in the way the end-user is
expecting the DBI/DBD to work.

As the Lancaster Consensus has come to the conclusion that the new
toolchain can expect a minimum of perl-5.8.1 (which might be raised to
5.8.4 when the need arises), we have set the lower bound for DBI::Test
to be 5.8.1, which includes the use of recent Test::More and the use of
`done_testing();` (no plans).

What the end-user sees:

[![End-user view](http://tux.nl/Talks/DBI-Test/images/dbi-dbd.png)](http://tux.nl/Talks/DBI-Test/images/dbi-dbd.png)

How that is currently tested:

[![Current testing view](http://tux.nl/Talks/DBI-Test/images/testing.png)](http://tux.nl/Talks/DBI-Test/images/testing.png)

What the new plan would be:

[![new plan](http://tux.nl/Talks/DBI-Test/images/dbi-api.png)](http://tux.nl/Talks/DBI-Test/images/dbi-api.png)

The plan is to support a full matrix of tests, including both DBI/XS
and pure-perl DBI, as well as with and without proxy or other optional
parts.

There will be a possibility to skip pure-perl DBI (DBD::Oracle,
DBD::CSV with Text::CSV\_XS) or to skip DBI/XS (DBD::Pg\_PP, DBD::CSV
with Text::CSV\_PP).

Visit the sandbox in the repository to view unrelated notes and stuff
that won't be part of the distribution.
