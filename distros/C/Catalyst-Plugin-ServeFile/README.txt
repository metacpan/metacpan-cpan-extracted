NAME
    Catalyst::Plugin::ServeFile - A less opinionated, minimal featured way
    to serve static files.

SYNOPSIS
        package MyApp;
        use Catalyst 'ServeFile';

        MyApp->setup;

        package MyApp::Controller::Root;

        use Moose;
        use MooseX::MethodAttributes;

        extends 'Catalyst::Controller';

        # Serves => https://localhost/license
        sub license :Path(license) Args(0) {
          my ($self, $c) = @_;
          $c->serve_file("license.txt");
        }

        # Servers => https://localhost/static/...
        sub static :Path(static) Args {
          my ($self, $c, @args) = @_;
          $c->serve_file('static',@args) || do {
            $c->res->status(404);
            $c->res->body('Not Found!');
          };
        }

DESCRIPTION
    Catalyst::Plugin::Static::Simple is venerable but I find it has too many
    default opinions. I generally only use it for the simple job of when I
    have a single static file or so that lives behind authentication that I
    want to serve. For that simple job Catalyst::Plugin::Static::Simple does
    provide a method 'serve_static_file', but there's two problems with it.
    First, the plugin out of the box will attempt to serve all files
    requested at the '/static/...' path. If you don't want that its
    configuration effort. Also, it doesn't currently support
    Plack::Middleware::XSendfile (Although I want to point out adding such
    support would be trivial, and I would be happy to help if needed).

    Even when I want the automatic serving of files under '/static' I find
    the old plugin has some opinions that don't work with my expectations
    (for example it by default doesn't serve *.html files). These
    assumptions probably made sense in 2006 but I prefer something with less
    default opinions. So this is a plugin that just does a simple one thing.
    It gives you a method 'serve_file' which tries to safely serve a static
    file located in '$c->config->{root}', with support for
    Plack::Middleware::XSendfile. It does basic sanity / safety checking
    such as not allowing you to have a path with '..' for example. And
    that's it. It does automatically serve up all files under 'static', or
    anything. If you want that, use the old plugin, or write a trivial
    action that does it (example below).

METHODS
    This plugin adds the following methods to your Catalyst application.

  serve_file (@path_parts, ?\%options?)
    Will serve a static file using '$c->config->{root}' as the path prefix.
    For example if you have a file '$c->config->{root}/static/license/html'
    you can serve it with $c->serve_file('static','license.html').

    This method will return true (the $fh actually) if it is successful in
    locating and serving a file. False otherwise. It doesn't automatically
    set any 'not found' response, you need to handle that yourself.

    If the last argument is a HashRef, we will use it as an overlay on any
    configuration options.

    See the \SYNOPSIS for a longer example.

CONFIGURATION
    This plugin supports the following configuration. You may set
    configuration globally via the 'Plugin::ServeFile' configuration key,
    and you may set/override when making the request. For example:

        package MyApp;
        use Catalyst 'ServeFile';

        myApp->config(
          'Plugin::ServeFile' => {
            show_log => 1,
          }
        );
        MyApp->setup;

       package MyApp::Controller::Root;

        use Moose;
        use MooseX::MethodAttributes;

        extends 'Catalyst::Controller';

        sub license :Path(license) Args(0) {
          my ($self, $c) = @_;
          $c->serve_file("license.txt", +{ show_log=>1});
        }

  show_log
    By default we supress detailed logging of the request. This is the same
    behavior as Catalyst::Plugin::Static::Simple. If you want to see those
    logs, you can enable it by setting this to true.

  allowed_content_types
    By default we allow you to serve any file. This may be dangerous if you
    are building your path arguments dynamically from uncontrolled sources.
    In that case you can set this to an arrayref of allowed mime types
    ('text/html', 'application/javascript', etc.).

AUTHOR
    John Napiorkowski <email:jjnapiork@cpan.org>

SEE ALSO
    Catalyst

COPYRIGHT & LICENSE
    Copyright 2017, John Napiorkowski <email:jjnapiork@cpan.org>

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

