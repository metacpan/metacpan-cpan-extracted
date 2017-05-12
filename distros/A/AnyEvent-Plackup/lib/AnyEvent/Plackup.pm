package AnyEvent::Plackup;
use strict;
use warnings;
use 5.008_001;
use overload (
    '""' => 'origin',
    fallback => 1
);

use AnyEvent;
use Twiggy::Server;
use Net::EmptyPort qw(empty_port);
use Scalar::Util qw(weaken);
use Carp;

use Class::Accessor::Lite (
    ro => [
        'host', 'port',
        'ready_cv', 'request_cv',
        'twiggy',
    ],
);

use Exporter::Lite;

our $VERSION = '0.02';
our @EXPORT = qw(plackup);

sub plackup (@) {
    return __PACKAGE__->new(@_);
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        app  => delete $args{app},
        args => \%args,
    }, $class;
    $self->_run;
    return $self;
}

sub recv {
    my $self = shift;

    croak 'plackup->recv is not available if app is set'
        if $self->{app};

    unless (@{ $self->{request_queue} }) {
        $self->{request_cv} = AE::cv if $self->{request_cv}->ready;
        $self->{request_cv}->recv;
    }

    return shift @{ $self->{request_queue} };
}

sub origin {
    my $self = shift;
    return sprintf "http://%s:%s", $self->host, $self->port;
}

sub _run {
    my $self = shift;

    weaken $self;

    $self->{ready_cv} = AE::cv;

    my $app = $self->{app} || $self->_mk_default_app;

    my $twiggy = Twiggy::Server->new(
        port => $self->{port} || empty_port(),
        %{ $self->{args} || {} },
        server_ready => sub {
            my $args = shift;

            $self->{host} = $args->{host};
            $self->{port} = $args->{port};

            $self->ready_cv->send($args);
        }
    );
    $twiggy->register_service($app);

    $self->{twiggy} = $twiggy;
}

sub _mk_default_app {
    my $self = shift;

    $self->{request_cv} = AE::cv;
    $self->{request_queue} = [];

    weaken $self;

    require AnyEvent::Plackup::Request;

    return sub {
        my ($env) = @_;

        my $req = AnyEvent::Plackup::Request->new($env);

        push @{ $self->{request_queue} }, $req;
        $self->{request_cv}->send if $self->{request_cv};

        return sub {
            my $respond = shift;
            $req->_response_cv->cb(sub {
                my $res = $_[0]->recv;
                if (ref $res eq 'CODE') {
                    $res->($respond);
                } else {
                    $respond->($res);
                }
            });
        };
    };
}

sub DESTROY {
    my $self = shift;
    local $@;
    delete $self->{twiggy}->{listen_guards};
}

sub shutdown {
    my $self = shift;
    my $w; $w = AE::timer 0, 0, sub {
        $self->{twiggy}->{exit_guard}->end;
        undef $w;
    };
    $self->{twiggy}->{exit_guard}->recv;
}

1;

__END__

=head1 NAME

AnyEvent::Plackup - Easily establish an HTTP server inside a program

=head1 SYNOPSIS

  use AnyEvent::Plackup;

  my $server = plackup(); # port is automatically chosen
  my $req = $server->recv; # isa Plack::Request

  my $value = $req->parameters->{foo};

  $req->respond([ 200, [], [ 'OK' ] ]);

  # or specify PSGI app:

  my $server = plackup(app => \&app);

=head1 DESCRIPTION

AnyEvent::Plackup provides functionality of establishing an HTTP server inside a program using L<Twiggy>. If not specified, open port is automatically chosen.

=head1 FUNCTIONS

=over 4

=item C<< my $server = AnyEvent::Plackup->new([ app => \&app, port => $port, %args ]) >>

=item C<< my $server = plackup([ app => \&app, port => $port, %args ]) >>

Creates and starts an HTTP server. Internally calls C<new> and C<run>.

If I<app> is not specified, C<< $server->recv >> is available and you should respond this manually.

=item C<< my $req = $server->recv >>

Waits until next request comes. Returns an C<AnyEvent::Plackup::Request> (isa C<Plack::Request>).

=item C<< my $origin = $server->origin >>

=item C<< my $origin = "$server" >>

Returns server's origin. e.g. C<"http://0.0.0.0:8290">.

=item C<< $server->shutdown >>

Shuts down the server immediately.

=back

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<Twiggy>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
