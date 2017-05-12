# Dancer2::Plugin::Github::Webhook

[![Build Status](https://travis-ci.org/sonntagd/Dancer2-Plugin-Github-Webhook.svg?branch=master)](https://travis-ci.org/sonntagd/Dancer2-Plugin-Github-Webhook)


## DESCRIPTION

This plugin can be used to verify if routes that are used as Github webhook payload URL use the correct secret.

## SYNOPSIS

Set the secret in your app configuration if you want it global:

```yaml
plugins:
  Github::Webhook:
    secret: '|8MVY)<[2Zh@!f39=<NSoCB02Btb#LTQ6Ty0dlA*4s'
```

Define that a route has to be correctly signed:

```perl
post '/githubinfo' => require_github_webhook_secret sub {
    do_something_with_correctly_signed_payload();
};
```

Define that a route has to be correctly signed with a specific secret.

```perl
post '/otherwebhook' => require_github_webhook_secret 'KUksrZyREtM32mIPoxcV7Cqx' => sub {
    do_something_with_correctly_signed_payload();
};
```

```perl
post '/otherwebhook' => require_github_webhook_secret config->{githubwebhooks}->{otherwebhook} => sub {
    do_something_with_correctly_signed_payload();
};
```

## CONTROLLING ACCESS TO ROUTES

### require_github_webhook_secret [ $secret ]

```perl
post '/reload-app' => require_github_webhook_secret 'mysecret' => sub {
    ...
};
```

Only executes the route's sub if the payload is correctly signed. If no secret is given, we use the one 
you configured in your config file (see above). If you need different secrets within your app, you can 
provide it here or use on from the configuration file via `config->{anyconfigentry}`.


## INSTALLATION

To install this module, run the following commands:

```bash
perl Makefile.PL
make
make test
make install
```

The easy way is to use `cpanm`:

```bash
cpanm Dancer2::Plugin::Github::Webhook
```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```bash
perldoc Dancer2::Plugin::Github::Webhook
```

If you want to contribute to this module, write me an email or create a
Pull request on Github: https://github.com/sonntagd/Dancer2-Plugin-Github-Webhook

## LICENSE AND COPYRIGHT

Copyright (C) 2016 Dominic Sonntag

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

