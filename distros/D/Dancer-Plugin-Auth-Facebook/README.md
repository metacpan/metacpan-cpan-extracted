Dancer-Plugin-Auth-Facebook
===========================

[![Build Status](https://travis-ci.org/Prajithp/Dancer-Plugin-Auth-Facebook.svg?branch=master)](https://travis-ci.org/Prajithp/Dancer-Plugin-Auth-Facebook)

This plugin provides a simple way to authenticate your users through Facebook's
OAuth API. It provides you with a helper to build easily a redirect to the
authentication URL, defines automatically a callback route handler and saves the
authenticated user to your session when done.

The authenticated user information will be available as a hash reference under
`session('fb_user')`. Please refer to Facebook's documentation for all available
data.


#### Installation ####

    cpanm Dancer::Plugin::Auth::Facebook


#### Prerequisites ####

In order for this plugin to work, you need the following:

* Facebook application

Anyone can [register a application on Facebook for free](https://developers.facebook.com).
When done, make sure to configure the application as a *Web* application.

* Configuration

You need to configure the plugin first: copy your *application_id* and *application_secret*
(provided by Facebook) to your Dancer's configuration under `plugins/Auth::Facebook`:

    # config.yml
    ...
    plugins:
        'Auth::Facebook':
            application_id:     "1234"
            application_secret: "abcd"
            callback_url:       "http://localhost:3000/auth/facebook/callback"
            callback_success:   "/"
            callback_fail:      "/fail"
            scope:              "email friends"

*callback_success*, *callback_fail* and *scope* are optional and default to
'/' , '/fail', and 'email' respectively.

Note that you also need to provide your callback url, whose route handler is automatically
created by the plugin.

* Session backend

For the authentication process to work, you need a session backend, in order for
the plugin to store the authenticated user's information.

Use the session backend of your choice, it doesn't make a difference, see
[Dancer::Session](https://metacpan.org/pod/Dancer::Session) for details about
supported session engines, or [search the CPAN for new ones](http://search.cpan.org/search?query=Dancer-Session).



COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2014-2016 by Prajith Ndimensionz

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
