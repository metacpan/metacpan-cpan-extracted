package Amon2::Lite;
use strict;
use warnings;
use 5.008008;
our $VERSION = '0.13';

use parent qw/Amon2 Amon2::Web/;
use Router::Simple 0.04;
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;
use File::Spec;
use File::Basename qw(dirname);
use Data::Section::Simple ();
use Amon2::Config::Simple;

my $COUNTER;

sub import {
    my $class = shift;
    no strict 'refs';

    my $router = Router::Simple->new();
    my $caller = caller(0);

    my $base_class = 'Amon2::Lite::_child_' . $COUNTER++;
    {
        no warnings;
        unshift @{"$base_class\::ISA"}, qw/Amon2 Amon2::Web/;
        unshift @{"$caller\::ISA"}, $base_class;
    }

    *{"$caller\::to_app"} = sub {
        my ($class, %opts) = @_;

        my $app = $class->Amon2::Web::to_app();
        if (delete $opts{handle_static}) {
            my $vpath = Data::Section::Simple->new($caller)->get_data_section();
            require Plack::App::File;
            my $orig_app = $app;
            my $app_file_1;
            my $app_file_2;
            my $root1 = File::Spec->catdir( dirname((caller(0))[1]), 'static' );
            my $root2 = File::Spec->catdir( dirname((caller(0))[1]) );
            $app = sub {
                my $env = shift;
                if ((my $content = $vpath->{$env->{PATH_INFO}}) && $env->{PATH_INFO} =~ m{^/}) {
                    my $ct = Plack::MIME->mime_type($env->{PATH_INFO});
                    return [200, ['Content-Type' => $ct, 'Content-Length' => length($content)], [$content]];
                } elsif ($env->{PATH_INFO} =~ qr{^(?:/robots\.txt|/favicon\.ico)$}) {
                    $app_file_1 ||= Plack::App::File->new({ root => $root1 });
                    return $app_file_1->call($env);
                } elsif ($env->{PATH_INFO} =~ m{^/static/}) {
                    $app_file_2 ||= Plack::App::File->new({ root => $root2 });
                    return $app_file_2->call($env);
                } else {
                    return $orig_app->($env);
                }
            };
        }
        if (my @middlewares = @{"${caller}::_MIDDLEWARES"}) {
            for my $middleware (@middlewares) {
                my ($klass, $args) = @$middleware;
                $klass = Plack::Util::load_class($klass, 'Plack::Middleware');
                $app = $klass->wrap($app, %$args);
            }
        }
        unless ($opts{no_x_content_type_options}) {
            $class->add_trigger(AFTER_DISPATCH => sub {
                my ($c, $res) = @_;
                $res->header( 'X-Content-Type-Options' => 'nosniff' );
            });
        }
        unless ($opts{no_x_frame_options}) {
            $class->add_trigger(AFTER_DISPATCH => sub {
                my ($c, $res) = @_;
                $res->header( 'X-Frame-Options' => 'DENY' );
            });
        }
        return $app;
    };

    *{"${base_class}::enable_middleware"} = sub {
        my ($class, $klass, %args) = @_;
        push @{"${caller}::_MIDDLEWARES"}, [$klass, \%args];
    };
    *{"${base_class}::enable_session"} = sub {
        my ($class, %args) = @_;
        $args{state} ||= do {
            require Plack::Session::State::Cookie;
            Plack::Session::State::Cookie->new(httponly => 1); # for security
        };
        require Plack::Middleware::Session;
        $class->enable_middleware('Plack::Middleware::Session', %args);
        $class->add_trigger(AFTER_DISPATCH => sub {
            my ($c, $res) = @_;
            $res->header('Cache-Control' => 'private');
        });
    };

    *{"$caller\::router"} = sub { $router };

    # any [qw/get post delete/] => '/bye' => sub { ... };
    # any '/bye' => sub { ... };
    *{"$caller\::any"} = sub ($$;$) {
        my $pkg = caller(0);
        if (@_==3) {
            my ($methods, $pattern, $code) = @_;
            $router->connect(
                $pattern,
                {code => $code, method => [ map { uc $_ } @$methods ]},
                {method => [map { uc $_ } @$methods]},
            );
        } else {
            my ($pattern, $code) = @_;
            $router->connect(
                $pattern,
                {code => $code},
            );
        }
    };

    *{"$caller\::get"} = sub {
        $router->connect($_[0], {code => $_[1], method => ['GET', 'HEAD']}, {method => 'GET'});
    };

    *{"$caller\::post"} = sub {
        $router->connect($_[0], {code => $_[1], method => ['POST']}, {method => ['POST']});
    };

    *{"${base_class}\::dispatch"} = sub {
        my ($c) = @_;
        if (my $p = $router->match($c->request->env)) {
            return $p->{code}->( $c, $p );
        } else {
            if ($router->method_not_allowed) {
                my $content = '405 Method Not Allowed';
                return $c->create_response(
                    405,
                    [
                        'Content-Type'   => 'text/plain; charset=utf-8',
                        'Content-Length' => length($content),
                    ],
                    [$content]
                );
            } else {
                return $c->res_404();
            }
        }
    };

    my $tmpl_dir = File::Spec->catdir(dirname((caller(0))[1]), 'tmpl');
    *{"${base_class}::create_view"} = sub {
        $base_class->template_options();
    };
    *{"${base_class}::template_options"} = sub {
        my ($class, %options) = @_;

        # using lazy loading to read __DATA__ section.
        my $vpath = Data::Section::Simple->new($caller)->get_data_section();
        my %params = (
            'syntax'   => 'TTerse',
            'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
            'path'     => [ $vpath, $tmpl_dir ],
            'function' => {
                c        => sub { Amon2->context() },
                uri_with => sub { Amon2->context()->req->uri_with(@_) },
                uri_for  => sub { Amon2->context()->uri_for(@_) },
            },
        );
        my $merge = sub {
            my ($stuff) = @_;
            for (qw(module path)) {
                if ($stuff->{$_}) {
                    unshift @{$params{$_}}, @{delete $stuff->{$_}};
                }
            }
            for (qw(function)) {
                if ($stuff->{$_}) {
                    $params{$_} = +{ %{$params{$_}}, %{delete $stuff->{$_}} };
                }
            }
            while (my ($k, $v) = each %$stuff) {
                $params{$k} = $v;
            }
        };
        if (my $config = $caller->config->{'Text::Xslate'}) {
            $merge->($config);
        }
        if (%options) {
            $merge->(\%options);
        }
        my $xslate = Text::Xslate->new(%params);
        no warnings 'redefine';
        *{"${caller}::create_view"} = sub { $xslate };
        $xslate;
    };

    if (-d File::Spec->catdir($caller->base_dir, 'config')) {
        *{"${base_class}::load_config"} = sub { Amon2::Config::Simple->load(shift) };
    } else {
        *{"${base_class}::load_config"} = sub { +{ } };
    }
}


1;
__END__

=for stopwords TinyURL

=encoding utf8

=head1 NAME

Amon2::Lite - Sinatra-ish framework on Amon2!

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a Sinatra-ish wrapper for Amon2.

B<THIS MODULE IS BETA STATE. API MAY CHANGE WITHOUT NOTICE>.

=head1 FUNCTIONS

=over 4

=item C<< any(\@methods, $path, \&code) >>

=item C<< any($path, \&code) >>

Register new route for router.

=item C<< get($path, $code->($c)) >>

Register new route for router.

=item C<< post($path, $code->($c)) >>

Register new route for router.

=item C<< __PACKAGE__->load_plugin($name, \%opts) >>

Load a plugin to the context object.

=item [EXPERIMENTAL] C<< __PACKAGE__->enable_session(%args) >>

This method enables L<Plack::Middleware::Session>.

C<< %args >> would be pass to enabled to C<< Plack::Middleware::Session->new >>.

The default state class is L<Plack::Session::State::Cookie>, and store class is L<Plack::Session::Store::File>.

This option enables a response filter, that adds C< Cache-Control: private > header.

=item [EXPERIMENTAL] C<< __PACKAGE__->enable_middleware($klass, %args) >>

    __PACKAGE__->enable_middleware('Plack::Middleware::XFramework', framework => 'Amon2::Lite');

Enable the Plack middlewares.

=item C<< __PACKAGE__->to_app(%args) >>

Create new PSGI application instance.

There is a options.

=over 4

=item C<< no_x_content_type_options : default false >>

    __PACKAGE__->to_app(no_x_content_type_options => 1);

Amon2::Lite puts C<< X-Content-Type-Options >> header by default for security reason.
You can disable this feature by this option.

=item C<< no_x_frame_options >>

    __PACKAGE__->to_app(no_x_frame_options => 1);

Amon2::Lite puts C<< X-Frame-Options: DENY >> header by default for security reason.
You can disable this feature by this option.

=back

=back

=head1 FAQ

=over 4

=item How can I configure the options for Xslate?

You can provide a constructor arguments by configuration.
Write following lines on your app.psgi.

    __PACKAGE__->template_options(
        syntax => 'Kolon',
    );

=item How can I use other template engines instead of Text::Xslate?

You can use any template engine with Amon2::Lite. You can overwrite create_view method same as normal Amon2.

This is a example to use L<Text::MicroTemplate::File>.

    use Tiffany::Text::MicroTemplate::File;

    sub create_view {
        Tiffany::Text::MicroTemplate::File->new(+{
            include_path => ['./tmpl/']
        })
    }

=item How can I handle static files?

If you pass the 'handle_static' option to 'to_app' method, Amon2::Lite handles /static/ path to ./static/ directory.

    use Amon2::Lite;
    __PACKAGE__->to_app(handle_static => 1);

=item Where is a example codes?

There is a tiny TinyURL example: L<https://github.com/tokuhirom/MyTinyURL/blob/master/app.psgi>.

=item How can I use session?

You can enable session by C<< __PACKAGE__->enable_session() >>. And you can access the session object by C<< $c->session >> accessor.

    use Amon2::Lite;

    get '/' => sub {
        my $c = shift;
        my $cnt = $c->session->get('cnt') || 1;
        $c->session->set('cnt' => $cnt+1);
        return $c->create_response(200, [], [$cnt]);
    };

    __PACKAGE__->enable_session(); # 
    __PACKAGE__->to_app();

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
