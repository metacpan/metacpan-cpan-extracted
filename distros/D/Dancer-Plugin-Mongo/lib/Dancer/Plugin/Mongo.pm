# ABSTRACT: MongoDB plugin for the Dancer micro framework
package Dancer::Plugin::Mongo;

use strict;
use warnings;
use Dancer::Plugin;
use MongoDB 0.38;

our $VERSION = 0.03;

my $settings = plugin_setting;
my $conn;

## return a connected MongoDB object
register mongo => sub {

    $conn ? $conn : $conn = MongoDB::Connection->new( _slurp_settings() ) ;

    return $conn;
};

register_plugin;

sub _slurp_settings {
    
    my $args = {};
    for (qw/ host port username password w wtimeout auto_reconnect auto_connect
        timeout db_name query_timeout find_master/) {
        if (exists $settings->{$_}) {
            $args->{$_} = $settings->{$_};
        }
    }

    return $args;
}


1;

__END__
=pod

=head1 NAME

Dancer::Plugin::Mongo - MongoDB plugin for the Dancer micro framework

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Mongo;

    get '/widget/view/:id' => sub {
        my $widget = mongo->database->collection->find_one({ id => params->{id} });
    }

=head1 DESCRIPTION

Dancer::Plugin::Mongo provides a wrapper around L<MongoDB>. Add the appropriate
configuraton options to your config.yml and then you can access a MongoDB database
using the 'mongo' keyword.

To query the database, use the standard MongoDB syntax, described in
L<MongoDB::Collection>.

=head1 CONFIGURATON

Connection details will be taken from your Dancer application config file, and
should be specified as follows:

    plugins:
        Mongo:
            host:
            port:
            username:
            password:
            w:
            wtimeout:
            auto_reconnect:
            auto_connect:
            timeout:
            db_name:
            query_timeout:
            find_master:

All these configuration values are optional, full details are in the
L<MongoDB::Connection> documentation.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

