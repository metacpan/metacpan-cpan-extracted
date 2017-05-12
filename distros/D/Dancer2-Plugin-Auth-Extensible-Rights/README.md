# Dancer2::Plugin::Auth::Extensible::Rights

[![Build Status](https://travis-ci.org/sonntagd/Dancer2-Plugin-Auth-Extensible-Rights.svg?branch=master)](https://travis-ci.org/sonntagd/Dancer2-Plugin-Auth-Extensible-Rights)


## NAME

Dancer2::Plugin::Auth::Extensible::Rights - A rights mapper for Dancer2::Plugin::Auth::Extensible roles.

## DESCRIPTION

This plugin can be used on top of Dancer2::Plugin::Auth::Extensible to define fine-grained rights for each role.
Each right has a list of roles that have this right. You can also define that a user has to have all listed roles to
gain that right. This way you can define low-level rights like "create_item" and put that requirement into your routes
definition. This plugin will translate the right requirement into a role requirement and call `require_all_roles` or 
`require_any_roles` with those roles.

## SYNOPSIS

Configure the rights:

```yaml

  plugins:
    # sample config for Auth::Extensible:
    Auth::Extensible:
      realms:
        config1:
          provider: Config
          users:
            - user: dave
              pass: supersecret
              roles:
                - Developer
                - Manager
                - BeerDrinker
            - user: bob
              pass: alsosecret
              roles:
                - Tester
    Auth::Extensible::Rights:
      rights:
        create_item:
          - BeerDrinker
          - Tester
          - Manager
        delete_item:
          - [ Manager, Tester ]
        delete_all: Manager
```

Define that a user must be logged in and have the right to access a route:

```perl
    get '/create-item' => require_right create_item => sub { show_create_item_form(); };
```

## CONTROLLING ACCESS TO ROUTES

### require_right

```perl
    post '/delete-item/:id' => require_right delete_item => sub {
        ...
    };
```

Requires that the user must be logged in as a user who has the specified right. If the user is not 
logged in, they will be redirected to the login page URL. If they are logged in, but do not 
have the required role, they will be redirected to the access denied URL.

If `disable_roles` configuration option is set to a true value then using `require_right` will 
cause the application to croak on load.

## INSTALLATION

To install this module, run the following commands:

```bash
	perl Makefile.PL
	make
	make test
	make install
```

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```bash
    perldoc Dancer2::Plugin::Auth::Extensible::Rights
```

If you want to contribute to this module, write me an email or create a
Pull request on Github: https://github.com/sonntagd/Dancer2-Plugin-Auth-Extensible-Rights

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

