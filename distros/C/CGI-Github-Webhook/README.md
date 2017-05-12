CGI::Github::Webhook
====================

[![Build Status](https://travis-ci.org/xtaran/CGI-Github-Webhook.svg?branch=master)](https://travis-ci.org/xtaran/CGI-Github-Webhook)
[![Coverage Status](https://coveralls.io/repos/xtaran/CGI-Github-Webhook/badge.svg?branch=master&service=github)](https://coveralls.io/github/xtaran/CGI-Github-Webhook?branch=master)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/CGI-Github-Webhook.png)](http://cpants.charsbar.org/dist/overview/CGI-Github-Webhook)
[![CPAN version](https://img.shields.io/cpan/v/CGI-Github-Webhook.svg)](https://metacpan.org/release/CGI-Github-Webhook)

An easy to use module for writing CGI-based
[Github webhook](https://developer.github.com/webhooks/) backends in
Perl.

In most cases three statements already suffice. Configure a script to
trigger, a shared secret and a log file and you're ready to go.

It also supports updating [Shields.io](https://shields.io/)-like
status badges depending on the trigger script's return code (or fork
success/fail).

Synopsis
--------

```perl
#!/usr/bin/perl

use CGI::Github::Webhook;

my $ghwh = CGI::Github::Webhook->new(
    mime_type => 'text/plain',
    trigger => '/srv/some-github-project/bin/deploy.pl',
    trigger_backgrounded => 1,
    secret => 'use a generated password here, nothing valuable',
    log => '/srv/some-github-project/log/deployment.log',
    badge_to => '/srv/some-github-project/htdocs/status.svg',
);
$ghwh->run();
```

Motivation
----------

The module has been written over the frustration of not getting
[GitHub::WebHook](https://metacpan.org/release/GitHub-WebHook) to work
together with [CGI.pm](https://metacpan.org/release/CGI).

It's first incarnation has been written as single CGI script powering
a webhook for the
[Debian Package Management Book](http://www.dpmb.org/) to trigger
builds of the e-book variants and their deployment upon every push.

Author, License and Copyright
-----------------------------

Copyright 2016 Axel Beckert <abe@deuxchevaux.org>.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the
[GNU General Public License](https://www.gnu.org/licenses/gpl) as
published by the [Free Software Foundation](https://www.fsf.org/),
either [version 1](https://www.gnu.org/licenses/old-licenses/gpl-1.0),
or (at your option)
[any later version](https://www.gnu.org/licenses/#GPL); or the
[Artistic License](http://dev.perl.org/licenses/artistic.html).

See http://dev.perl.org/licenses/ for more information.

The badges in the `static-badges` directory are licensed under the
[CC0 Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/)
and not copyrighted.
