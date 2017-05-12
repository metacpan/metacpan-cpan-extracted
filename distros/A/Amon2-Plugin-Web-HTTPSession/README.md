# NAME

Amon2::Plugin::Web::HTTPSession - HTTP::Session bindings for Amon2

# SYNOPSIS

    use Amon2::Lite;

    use HTTP::Session::Store::Memcached;
    __PACKAGE__->load_plugins(qw/Web::HTTPSession/ => {
        state => 'URI',
        store => sub {
            my ($c) = @_;
            HTTP::Session::Store::Memcached->new(
                memd => $c->get('Cache::Memcached::Fast')
            );
        },
    });

    get '/' => sub {
        my $c = shift;

        my $foo = $c->session->get('foo');
        if ($foo) {
              $c->session->set('foo' => $foo+1);
        } else {
              $c->session->set('foo' => 1);
        }
    };

# DESCRIPTION

HTTP::Session integrate to Amon2.

After load this plugin, you can get instance of HTTP::Session from `$c->session` method.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

[HTTP::Session](http://search.cpan.org/perldoc?HTTP::Session), [Amon2](http://search.cpan.org/perldoc?Amon2)
