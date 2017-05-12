#
# This file is part of Dancer-Plugin-Redis
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Redis;

# ABSTRACT: easy database connections for Dancer applications

use strict;
use warnings;
our $VERSION = '0.8';    # VERSION
use Carp;
use Dancer::Plugin;
use Try::Tiny;
use Redis 1.955;

my $_settings;
my $_handles;

sub redis {
    my @args = @_;
    my ( undef, $name ) = plugin_args(@args);
    $name = "_default" if not defined $name;
    return $_handles->{$name} if exists $_handles->{$name};

    $_settings ||= plugin_setting;

    my $conf
        = $name eq '_default'
        ? $_settings
        : $_settings->{connections}->{$name};
    croak "$name is not defined in your redis conf, please check the doc"
        unless defined $conf;

    return $_handles->{$name} = Redis->new(
        server    => $conf->{server},
        debug     => $conf->{debug},
        encoding  => $conf->{encoding},
        reconnect => $conf->{reconnect} // 60,
        password  => $conf->{password},
    );

}

register redis => \&redis;
register_plugin for_versions => [ 1, 2 ];

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Redis - easy database connections for Dancer applications

=head1 VERSION

version 0.8

=head1 DESCRIPTION

Provides an easy way to obtain a connected Redis database handle by simply calling
the redis keyword within your L<Dancer> application.

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Redis;

    # Calling the redis keyword will get you a connected Redis Database handle:
    get '/widget/view/:id' => sub {
        template 'display_widget', { widget => redis->get('hash_key'); };
    };

    dance;

Redis connection details are read from your Dancer application config - see
below.

=head1 METHODS

=head2 redis

Keywords redis, that use your config to connect to redis

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as, for example: 

    plugins:
        Redis:
            server: '127.0.0.1:6379'
            debug: 0
            encoding: utf8
            reconnect: 60
            password: yourpassword
            connections:
                test:
                    server: '127.0.0.1:6380'
                    debug: 1
                    encoding: utf8
                    password: yourpassword

C<server> is the ip:port of redis server

C<debug> activate the debug of redis

C<encoding> activate auto encoding, if you want raw data, put nothing after encoding

C<reconnect> is the number of second which try to reconnect if we have lost connection, default to 60

C<password> pass AUTH to Redis if you use the requirepass config. You can skip this option if you don't have requirepass set.

=head1 GETTING A DATABASE HANDLE

Calling C<redis> will return a connected database handle; the first time it is
called, the plugin will establish a connection to the database, and return a
reference to the DBI object.  On subsequent calls, the same DBI connection
object will be returned. The connection will be refresh automatically with the Redis C<reconnect> option.

If you have declared named connections as described above in 'DEFINING MULTIPLE
CONNECTIONS', then calling the database() keyword with the name of the
connection as specified in the config file will get you a database handle
connected with those details.

=head1 SEE ALSO

L<Dancer>

L<DBI>

L<Redis>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Dancer-Plugin-Redis/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
