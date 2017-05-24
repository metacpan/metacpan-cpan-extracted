package Dancer2::Plugin::Etcd;
use utf8;
use strict;
use warnings;

=encoding utf8

=head1 NAME

Dancer2::Plugin::Etcd

=cut

our $VERSION = '0.006';

use Dancer2::Core::Types qw/Bool HashRef Str/;
use Dancer2::Plugin;
use Data::Dumper;
use File::Spec;
use Etcd3;

=head1 SYNOPSIS

    get '/foo/:name' => sub {
        $tokens = shift;
        $etcd = etcd('foo');
        $name = param('name');
        $tokens->{name} = $etcd->range({ key => $name })->get_value;
        [ ... ]
    };

    # save development configs to etcd
    shepherd put

    # retrieve latest version of configs
    shepherd get

=head1 DESCRIPTION

The C<etcd> keyword which is exported by this plugin allows you to 
connect directly to etcd v3 api.

=head1 shepherd

By far the most interesting part of this module is shepherd. shepherd
allows you to save Dancer App YAML configs to etcd by line as key/value.
Even more interesting is that it maintains your comments.  An example of
usage would be spawning a container with the application then simply running
shepherd get --env=production would bring in the latest production configs for
your app.

=head1 CONFIGURATION

single e.g.:

    plugins:
      Etcd:
        host: 127.0.0.1
        port: 4001
        user: samb
        password: h3xFu5ion
        ssl: 1

named e.g.:

    plugins:
      Etcd:
        connections:
          foo:
            host: 127.0.0.1
            port: 4001
            user: samb
            password: h3xFu5ion
          bar:
            host: 127.0.0.1
            port: 2379

=cut

=head2 connections

=cut

has connections => (
    is          => 'ro',
    isa         => HashRef,
    from_config => 'connections',
    default     => sub { +{} },
);

=head2 host

default 127.0.0.1

=cut

has host => (
    is => 'ro',
    isa => Str,
    default => sub {
         $_[0]->config->{host} || '127.0.0.1'
    }
);

=head2 port

default 2379

=cut

has port => (
    is => 'ro',
    default => sub {
         $_[0]->config->{port} || '2379'
    }
);

=head2 etcd_connection_name 

=cut

has etcd_connection_name => (
    is  => 'ro',
    isa => Str,
);

=head2 username

Etcd username.

=cut

has username => (
    is => 'ro',
    default => sub {
        $_[0]->config->{user}
    }
);


=head2 password

Etcd user password.

=cut

has password => (
    is => 'ro',
    default => sub {
        $_[0]->config->{password}
    }
);

=head2 ssl 

Secure connection is recommended,

=cut

has ssl => (
    is => 'ro',
    default => sub {
        $_[0]->config->{ssl}
    }
);

plugin_keywords 'etcd';

=head1 KEYWORDS

=head2 etcd

=cut

sub etcd {
    my( $plugin, $handle ) = @_;
    $plugin->app->log( "debug", "etcd handle: ", $handle ); 
#    print STDERR Dumper($handle);
    my $host;
    $handle ||= '';
    my $settings;
    if ($handle) {
#        print STDERR Dumper($plugin->connections);
        $settings = $plugin->connections->{$handle} or return;
        $host = $settings->{host};
    }
    else {
        for (qw(username password port)) {
            $settings->{$_} = $plugin->{$_};
        }
    }
    return Etcd3->new( $settings );
};

=head1 AUTHOR

Sam Batschelet, <sbatschelet at mac.com>

=head1 ACKNOWLEDGEMENTS

The L<Dancer2> developers and community for their great application framework
and for their quick and competent support.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;
