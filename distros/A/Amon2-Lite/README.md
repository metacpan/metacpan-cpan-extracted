# NAME

Amon2::Lite - Sinatra-ish framework on Amon2!

# SYNOPSIS

    use Amon2::Lite;

    get '/' => sub {
        my ($c) = @_;
        return $c->render('index.tt');
    };

    __PACKAGE__->to_app();

    __DATA__

    @@ index.tt
    <!doctype html>
    <html>
        <body>Hello</body>
    </html>

# DESCRIPTION

This is a Sinatra-ish wrapper for Amon2.

**THIS MODULE IS BETA STATE. API MAY CHANGE WITHOUT NOTICE**.

# FUNCTIONS

- `any(\@methods, $path, \&code)`
- `any($path, \&code)`

    Register new route for router.

- `get($path, $code->($c))`

    Register new route for router.

- `post($path, $code->($c))`

    Register new route for router.

- `__PACKAGE__->load_plugin($name, \%opts)`

    Load a plugin to the context object.

- \[EXPERIMENTAL\] `__PACKAGE__->enable_session(%args)`

    This method enables [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session).

    `%args` would be pass to enabled to `Plack::Middleware::Session->new`.

    The default state class is [Plack::Session::State::Cookie](https://metacpan.org/pod/Plack::Session::State::Cookie), and store class is [Plack::Session::Store::File](https://metacpan.org/pod/Plack::Session::Store::File).

    This option enables a response filter, that adds ` Cache-Control: private ` header.

- \[EXPERIMENTAL\] `__PACKAGE__->enable_middleware($klass, %args)`

        __PACKAGE__->enable_middleware('Plack::Middleware::XFramework', framework => 'Amon2::Lite');

    Enable the Plack middlewares.

- `__PACKAGE__->to_app(%args)`

    Create new PSGI application instance.

    There is a options.

    - `no_x_content_type_options : default false`

            __PACKAGE__->to_app(no_x_content_type_options => 1);

        Amon2::Lite puts `X-Content-Type-Options` header by default for security reason.
        You can disable this feature by this option.

    - `no_x_frame_options`

            __PACKAGE__->to_app(no_x_frame_options => 1);

        Amon2::Lite puts `X-Frame-Options: DENY` header by default for security reason.
        You can disable this feature by this option.

# FAQ

- How can I configure the options for Xslate?

    You can provide a constructor arguments by configuration.
    Write following lines on your app.psgi.

        __PACKAGE__->template_options(
            syntax => 'Kolon',
        );

- How can I use other template engines instead of Text::Xslate?

    You can use any template engine with Amon2::Lite. You can overwrite create\_view method same as normal Amon2.

    This is a example to use [Text::MicroTemplate::File](https://metacpan.org/pod/Text::MicroTemplate::File).

        use Tiffany::Text::MicroTemplate::File;

        sub create_view {
            Tiffany::Text::MicroTemplate::File->new(+{
                include_path => ['./tmpl/']
            })
        }

- How can I handle static files?

    If you pass the 'handle\_static' option to 'to\_app' method, Amon2::Lite handles /static/ path to ./static/ directory.

        use Amon2::Lite;
        __PACKAGE__->to_app(handle_static => 1);

- Where is a example codes?

    There is a tiny TinyURL example: [https://github.com/tokuhirom/MyTinyURL/blob/master/app.psgi](https://github.com/tokuhirom/MyTinyURL/blob/master/app.psgi).

- How can I use session?

    You can enable session by `__PACKAGE__->enable_session()`. And you can access the session object by `$c->session` accessor.

        use Amon2::Lite;

        get '/' => sub {
            my $c = shift;
            my $cnt = $c->session->get('cnt') || 1;
            $c->session->set('cnt' => $cnt+1);
            return $c->create_response(200, [], [$cnt]);
        };

        __PACKAGE__->enable_session(); # 
        __PACKAGE__->to_app();

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
