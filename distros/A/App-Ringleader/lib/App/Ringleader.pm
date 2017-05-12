package App::Ringleader;
BEGIN {
  $App::Ringleader::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Proxy for sproradically-used web application
$App::Ringleader::VERSION = '0.1.0';

use 5.10.0;

use strict;
use warnings;

use MooseX::App::Simple;

use YAML::XS;
use Path::Tiny;
use HTTP::Proxy;
use HTTP::Proxy::HeaderFilter::simple;
use Ubic;
use CHI;

parameter 'conf' => (
    is => 'ro',
    required => 1,
    documentation => 'configuration file',
);

has "port" => (
    isa => 'Int',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        $self->configuration->{port} // 3000;
    },
);

has configuration => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Load(path($_[0]->conf)->slurp);
    },
);

has inactivity_delay => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    default => sub {
        60 * ( $_[0]->configuration->{inactivity_delay} || 60 );
    },
);

has services => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $services = $_[0]->configuration->{services};

        $_ = Ubic->service($_) for values %$services;

        return $services;
    },
);

has cache => (
    is => 'ro',
    lazy => 1,
    default => sub {
        return CHI->new(
            %{ $_[0]->configuration->{CHI} 
                || { driver => 'FastMmap' } }
        );
    },
);

sub run {
    my $self = shift;

    my $proxy = HTTP::Proxy->new( host => undef, port => $self->port );

    $proxy->push_filter( 
        request => HTTP::Proxy::HeaderFilter::simple->new( sub {
            my( undef, undef, $request ) = @_;
            my $uri = $request->uri;
            my $host = $uri->host;

            my $service = $self->services->{ $host } or die;

            $uri->host( 'localhost' );
            $uri->port( $service->port );

            unless ( $self->cache->get($host) ) {
                $service->start;
                sleep 1;
            }

            # always store the latest access time
            $self->cache->set( $host => time );
        })
    );

    $self->start_monitor;

    say 'ringleader started...';

    $proxy->start;
}

sub start_monitor {
    my $self = shift;

    return if fork;

    while( sleep $self->inactivity_delay ) {
        $self->check_activity_for( $_ ) for keys %{ $self->services };
    }
}

sub check_activity_for {
    my( $self, $s ) = @_;

    my $time = $self->cache->get($s);

    # no cache? assume not running
    return if !$time or time - $time <= $self->inactivity_delay;

    $self->services->{$s}->stop;

    $self->cache->remove($s);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Ringleader - Proxy for sproradically-used web application

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use App::Ringleader;

    App::Ringleader->new( conf => 'ringleader.yml' )->run;

=head1 DESCRIPTION

Ringleader is a proxy that will wake up psgi applications upon request 
and shut them down after a period of inactivity. It's meant to provide a
middle-ground between the slowliness of CGI and the constant resource
consumption of plack applications for services that are not often used.

Typically, you'll use it via the C<ringleader> script.

Ringleader relies on L<Ubic> to start and stop the services. For PSGI
applications, you probably want to define your services using
L<Ubic::Service::Plack>.

=head1 CONFIGURATION FILE

The Ringleader configuration file is YAML-based, and looks like

    port: 3000
    inactivity_delay: 60
    services:
        techblog.babyl.ca:  webapp.techblog
        kittenwar.babyl.ca: webapp.kittenwar
    CHI:
        driver: FastMmap

=head2 port

The port of the proxy. Defaults to I<3000>.

=head2 inactivity_delay

The minimum time (in minutes) of inactivity before a service will be shut down.

Defaults to 60 minutes.

=head2 services

The services Ringleader will monitor. Each service is configured via a
key/value pair. The key is the request's host, and the value is the 
<Ubic> service it related to.

=head2 CHI

The arguments to pass to L<CHI> to build the caching system used
by the service. If not provided, L<CHI::Driver::FastMmap> will be used.

=head1 SEE ALSO

L<http://techblog.babyl.ca/entry/ringleader> - The original blog entry

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
