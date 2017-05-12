
package Clio::Server::HTTP;
BEGIN {
  $Clio::Server::HTTP::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::HTTP::VERSION = '0.02';
}
# ABSTRACT: Clio HTTP Server

use strict;
use Moo;

use AnyEvent;
use Twiggy::Server;
use Plack::Request;
use Plack::Util;

extends qw( Clio::Server );

with 'Clio::Role::UUIDMaker';


sub start {
    my $self = shift;

    my $listen = $self->c->config->server_host_port;

    my $twiggy = Twiggy::Server->new(
        %{ $listen }
    );

    $self->c->log->info(
        "Started ", __PACKAGE__, " on $listen->{host}:$listen->{port}"
    );
    $twiggy->run( $self->build_app );
}


sub build_app {
    my $self = shift;

    my $config = $self->c->config->ServerConfig;

    my $app = $self->to_app;
    if ( my $builder = $config->{Builder} ) {
        my $wrapper = Plack::Util::load_psgi($builder);

        $app = $wrapper->($app);
    }

    $DB::single=1;
    return $app;
}


sub to_app {
    my $self = shift;

    my $log = $self->c->log;

    sub {
        my ($env) = @_;

        my $req = Plack::Request->new( $env );

        my %proc_manager_args;
        my $post_data;
        if ( $req->method eq 'POST' ) {
            $post_data = $req->body_parameters;
            $proc_manager_args{client_id} = $post_data->{'metadata.id'}
                if exists $post_data->{'metadata.id'};
        }

        my $process = $self->c->process_manager->get_first_available(
            %proc_manager_args
        );
        if ( $process ) {
            $log->debug("got process: ". $process->id );

            my $uuid = $self->create_uuid;

            $log->debug("new client(". $req->address .") id: $uuid");

            my $client = $self->clients_manager->new_client(
                id => $uuid,
                req => $req,
            );

            $client->attach_to_process( $process );

            return $client->respond(
                input => $post_data
            );
        }

        return [ 503, [
            'Content-Type' => 'text/plain; charset=utf-8',
            'Access-Control-Allow-Origin' => '*',
        ], [ "No engines available" ] ];
    }
}


1;




__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server::HTTP - Clio HTTP Server

=head1 VERSION

version 0.02

=head1 DESCRIPTION

PSGI HTTP server using L<Twiggy>.

Extends the L<Clio::Server>.

Consumes the L<Clio::Role::UUIDMaker>.

=head1 METHODS

=head2 start

Start server and wait for incoming connections.

=head2 build_app

Builds Plack application and optionally wrapps it with application specified
in configuration (C<Builder>).

=head2 to_app

Creates PSGI application.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

