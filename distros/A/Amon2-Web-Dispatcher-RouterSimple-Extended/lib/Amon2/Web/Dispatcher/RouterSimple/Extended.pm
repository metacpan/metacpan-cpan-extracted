package Amon2::Web::Dispatcher::RouterSimple::Extended;
use strict;
use warnings;

our $VERSION = "0.05.01";

use Router::Simple 0.03;

my @METHODS = qw/GET POST PUT DELETE/;
my $submap;

sub import {
    my $class = shift;
    my %args = @_;
    my $caller = caller(0);

    my $router = Router::Simple->new;

    no strict 'refs';

    # functions
    *{"${caller}::submapper"} = \&_submapper;
    *{"${caller}::connect"} = \&_connect;
    for my $method (@METHODS) {
        *{"${caller}::@{[lc $method]}"} = _make_method_connector($caller, $method);
    }

    # class methods
    *{"${caller}::router"} = sub { $router };
    for my $meth (qw/match as_string/) {
        *{"$caller\::${meth}"} = sub {
            my $class = shift;
            $class->router->$meth(@_)
        };
    }
    *{"$caller\::dispatch"} = \&_dispatch;
}

sub _make_method_connector {
    my ($caller, $method) = @_;

    sub {
        my $class = caller(0);

        if ($submap) {
            my ($path, $action) = @_;
            $submap->connect($path, { action => $action }, { metod => $method });
        } else {
            $_[2] = { method => $method };
            goto \&_connect;
        }
    }
}

sub _connect {
    my $caller = caller(0);
    if ($submap) {
        if (@_ >= 2 && !ref $_[1]) {
            my ($path, $action, $opt) = @_;
            $submap->connect($path, { action => $action }, $opt || {});
        } else {
            $submap->connect(@_);
        }
    } else {
        my $router = $caller->router;
        if (@_ >= 2 && !ref $_[1]) {
            my ($path, $dest_str, $opt) = @_;
            my ($controller, $action) = split('#', $dest_str);
            my $dest = { controller => $controller };
            $dest->{action} = $action if defined $action;
            $router->connect($path, $dest, $opt || {});
        } else {
            $router->connect(@_);
        }
    }
}

sub _submapper {
    my $caller = caller(0);
    my $router = caller(0)->router();
    if ($_[2] && ref($_[2]) eq 'CODE') {
        my ($path, $controller, $callback) = @_;
        $submap = $router->submapper($path, { controller => $controller });
        $callback->();
        undef $submap;
    }
    else {
        $router->submapper(@_);
    }
}

sub _dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $class->match($req->env)) {
        my $action = $p->{action};
        $c->{args} = $p;
        "@{[ ref Amon2->context ]}::C::$p->{controller}"->$action($c, $p);
    } else {
        $c->res_404();
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Web::Dispatcher::RouterSimple::Extended - extending Amon2::Web::Dispatcher::RouterSimple

=head1 SYNOPSIS


    package MyApp::Web::Dispatcher;
    use strict;
    use warnings;
    use utf8;
    use Amon2::Web::Dispatcher::RouterSimple::Extended;
    connect '/' => 'Root#index';
    # API
    submapper '/api/' => API => sub {
        get  'foo' => 'foo';
        post 'bar' => 'bar';
    };
    # user
    submapper '/user/' => User => sub {
        get     '',           'index';
        connect '{uid}',      'show';
        post    '{uid}/hoge', 'hoge';
        connect 'new',        'create';
    };
    1;

=head1 DESCRIPTION

This is an extension of Amon2::Web::Dispatcher::RouterSimple. 100% compatible, and it provides useful functions.


=head1 METHODS

=over 4

=item get $path, "${controller}#${action}"

this is equivalent to:

    connect $path, { controller => $controller, action => $action }, { method => 'GET' };


=item post $path, "${controller}#${action}"

this is equivalent to:

    connect $path, { controller => $controller, action => $action }, { method => 'POST' };


=item put $path, "${controller}#${action}"

this is equivalent to:

    connect $path, { controller => $controller, action => $action }, { method => 'PUT' };


=item delete $path, "${controller}#${action}"

this is equivalent to:

    connect $path, { controller => $controller, action => $action }, { method => 'DELETE' };


=item submapper $path, $controller, sub {}

this is main feature of this module. In subroutine of the third argument, connect/get/post/put/delete method fits in submapper. As a results, in submapper you can be described in the same interface. If this third argument not exists, this function behave in the same way as Amon2::Web::Dispatcher::RouterSimple.

=back


=head1 LICENSE

Copyright (C) Taiyoh Tanaka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Taiyoh Tanaka <sun.basix@gmail.com>

=head1 SEE ALSO

L<Amon2::Web::Dispatcher::RouterSimple|http://search.cpan.org/~tokuhirom/Amon2/lib/Amon2/Web/Dispatcher/RouterSimple.pm>
