Dancer-Plugin-Auth-Google
=========================

[![Build status](https://api.travis-ci.org/garu/Dancer-Plugin-Auth-Google.png)](https://api.travis-ci.org/garu/Dancer-Plugin-Auth-Google.png)
[![Coverage status](https://coveralls.io/repos/garu/Dancer-Plugin-Auth-Google/badge.png)](https://coveralls.io/r/garu/Dancer-Plugin-Auth-Google)
[![CPAN version](https://badge.fury.io/pl/Dancer-Plugin-Auth-Google.png)](http://badge.fury.io/pl/Dancer-Plugin-Auth-Google)

This plugin provides a simple way to authenticate your users through Google's
OAuth API. It provides you with a helper to build easily a redirect to the
authentication URI, defines automatically a callback route handler and saves
the authenticated user to your session when done.

```perl
    package MyApp;
    use Dancer ':syntax';
    use Dancer::Plugin::Auth::Google;

    auth_google_init;  # <-- don't forget to call this first!

    before sub {
        return unless request->path_info !~ m{^/auth/google/callback};
        redirect auth_google_authenticate_url unless session('google_user');
    };

    get '/' => sub {
        "welcome, " . session('google_user')->{displayName}
    };

    get '/fail' => sub {
        "oh noes!"
    };
```

Prerequisites
-------------

In order for this plugin to work, you need the following:

### Session backend ###

For the authentication process to work, **you need a session backend** so the plugin
can store the authenticated user's information.

Use the session backend of your choice, it doesn't make a difference, see
[Dancer::Session](https://metacpan.org/pod/Dancer::Session) for details
about supported session engines, or search the CPAN for new ones.

### Google Application ###

Anyone with a valid Google account can register an application. Go to
http://console.developers.google.com, then select a project or create
a new one. After that, in the sidebar on the left, select "Credentials"
under the "APIs and auth" option. In the "OAuth" section of that page,
select **Create New Client ID**. A dialog will appear.

![screenshot for creating new id](https://raw.githubusercontent.com/garu/Dancer-Plugin-Auth-Google/master/share/create-new-id.png)

In the "Application type" section of the dialog, make sure you select
"Web application". In the "Authorized JavaScript origins" field, make
sure you put the domains of both your development server and your
production one (e.g.: http://localhost:3000 and http://mywebsite.com).
Same thing goes for the "Redirect URIs": those ** **MUST** ** be the same
as you will set in your app and Google won't redirect to any page that
is not listed (don't worry, you can edit this later too).

![screenshot for authorized uris](https://raw.githubusercontent.com/garu/Dancer-Plugin-Auth-Google/master/share/authorized-uris.png)

Again, make sure the "Redirect URIs" contains both your development
url (e.g. http://localhost:3000/auth/google/callback) and production
(e.g. http://mycoolwebsite.com/auth/google/callback).

After you're finished, copy the "Client ID" and "Client Secret" data
of your newly created app. It should be listed on that same panel
(you can check it anytime by going to the "Credentials" option under
"APIs & auth":

![screenshot for client id](https://raw.githubusercontent.com/garu/Dancer-Plugin-Auth-Google/master/share/client-id.png)

### Configuration ###

After you set up your app, you need to configure this plugin. To do
that, copy the "Client ID" and "Client Secret" generated on the
previous step into your Dancer's configuration under
Plugins / Auth::Google, like so:

```yaml
    # config.yml
    plugins:
        'Auth::Google':
            client_id:        'your-client-id'
            client_secret:    'your-client-secret'
            scope:            'profile'
            access_type:      'online'
            callback_url:     'http://localhost:3000/auth/google/callback'
            callback_success: '/'
            callback_fail:    '/fail'
```

Of those, only "client_id", "client_secret" and "callback_url" are mandatory.
If you omit the other ones, they will assume their default values, as listed
above.

Specifically, it is a good practice to change the "callback_url" depending on
whether you're on a development or production environment. Dancer makes this
easier for you by letting you split your settings, leaving the basic plugin
settings on "config.yml" and specific "callback_url" definitions on
"environments/development.yml" and "environments/production.yml":

```yaml
    # environments/development.yml
    plugins:
        'Auth::Google':
            callback_url:   'http://localhost:3000/auth/google/callback'
```

And

```yaml
    # environments/production.yml
    plugins:
        'Auth::Google':
            callback_url:   'http://myproductionserver.com/auth/google/callback'
```

#### Setting your permissions' scope ####

Since this plugin is meant mainly for authentication, the default scope
is 'profile'. That should give you general profile data for the user, such
as full name, id, profile url, etc. See
https://developers.google.com/+/api/oauth#login-scopes for available
scopes to chose from. You can set as many as you like, separated by space.
A usual combination is 'profile email'. If you want a Google-specific scope
(i.e. those with a "." in the name) make sure you add the full URL as
specified in the document above. For example, the proper way to ask for a
user's social features is not "plus.login", but
"https://www.googleapis.com/auth/plus.login".


### Installation ###

    cpanm Dancer::Plugin::Auth::Google


Exports
-------

The plugin exports the following symbols to your application's namespace:

### auth_google_init ###

This function should be called before your route handlers in order to
initialize the underlying object and set up the proper routes. It will
read your configuration and create everything that it needs.

### auth_google_authenticate_url ###

This function returns an authorize URI for redirecting unauthenticated
users. You should use this in a before filter like the "synopsis"
demo above.


Route Handlers
--------------

The plugin defines the following route handler automatically:

* /auth/google/callback

This route handler is responsible for catching back a user that has just
authenticated herself with Google's OAuth. The route handler saves tokens
and user information in the session and then redirects the user to the URI
specified by callback_success.

If the validation of the token returned by Google failed or was denied,
the user will be redirected to the URI specified by callback_fail. Otherwise,
this route will point the user to callback_success.


Accessing Other Google APIs
---------------------------

Once the user is authenticated, your session data will contain the access
token:

```perl
    my $token = session('google_user')->{access_token};
```

You can use that access token to make calls to a Google API on behalf of
the user. See https://developers.google.com/accounts/docs/OAuth2WebServer
for more information on this.


Acknowledgements
----------------

This plugin was written following the same design as
Dancer::Plugin::Auth::Twitter and Dancer::Plugin::Auth::Facebook.


COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2014, Breno G. de Oliveira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
