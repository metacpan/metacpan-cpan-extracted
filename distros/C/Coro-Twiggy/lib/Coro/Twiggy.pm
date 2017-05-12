package Coro::Twiggy;
use 5.008008;
use strict;
use warnings;

use Twiggy::Server;
use Scalar::Util 'weaken';
use Coro;
use Data::Dumper;

our $VERSION = '0.03';

=head1 NAME

Coro::Twiggy - Coro interface for L<Twiggy>

=head1 SYNOPSIS

    use Coro::Twiggy;
    use Plack::Request;
    use Coro::AnyEvent;

    my $application = sub {
        my ($env) = @_;
        my $req = Plack::Request->new($env);

        Coro::AnyEvent::sleep 10;
        ...
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ 'Twiggy response after 10 seconds' ]
        ]
    };


    my $server = Coro::Twiggy->new(host => '127.0.0.1', port => 8080);
    $server->register_service( $application );


=head1 DESCRIPTION

The server starts Your application in L<Coro/async> coroutine and uses its
return value to respond to client.

Application have to return an B<ARRAYREF> with the following items:

=over

=item *

HTTP-code;

=item *

an B<ARRAYREF> that contains headers for response;

=item *

an B<ARRAYREF> that contains body of response.

=back

To stop server destroy server object

=head1 METHODS

=cut

use constant DEFAULT_SERVICE => sub {
    [
        503,
        [ 'Content-Type' => 'text/plain' ],
        [ 'There is no registered PSGI service' ]
    ]
};


=head2 new

Constructor. Returns server.

=head3 Named arguments

=over

=item host

=item port

=item service

PSGI application

=back

=cut

sub new {
    my ($class, %opts) = @_;
    my $host = $opts{host};
    my $port = $opts{port} || 8080;
    my $listen = $opts{listen};
    my $app  = $opts{service} || DEFAULT_SERVICE;

    my @args;
    if ($listen) {
        push @args => listen => $listen;
    } elsif ($port !~ /^\d+$/) {
        push @args => listen => [ $port ];
    } else {
        push @args =>
            host => $host,
            port => $port;
    }

    my $ts = Twiggy::Server->new(@args);

    my $self = bless { ts => $ts, app => $app } => ref($class) || $class;

    my $this = $self;
    $ts->register_service( $this->_app );

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{ts}{listen_guards};  # hack: Twiggy has no interface to stop
    delete $self->{ts};
}


=head2 register_service

(Re)register PSGI application.
Until the event server will respond B<503 Service Unavailable>.

=cut

sub register_service {
    my ($self, $cb) = @_;
    $self->{app} = $cb || DEFAULT_SERVICE;
}

sub _app {
    my ($self) = @_;
    weaken $self;
    sub {
        my ($env) = @_;
        sub {
            my ($cb) = @_;
            async {
                return DEFAULT_SERVICE->() unless $self;
                my @res = eval { $self->{app}->($env, $self) };
                my $res = shift @res;

                if (my $err = $@) {
                    utf8::encode($err) if utf8::is_utf8 $err;
                    $cb->([ 500, [ 'Content-Type' => 'text/plain' ], [ $err ]]);
                    return;
                }

                my $msg;
                unless('ARRAY' eq ref $res) {
                    $msg = 'PSGI application have to return an ARRAYREF';
                    goto WRONG_RES;
                }

                goto WRONG_RES unless @$res >= 2;
                push @$res => [] unless @$res > 2;

                goto WRONG_RES
                    unless defined($res->[0]) && $res->[0] =~ /^\d+$/;
                goto WRONG_RES unless 'ARRAY' eq ref $res->[1];
                goto WRONG_RES unless 'ARRAY' eq ref $res->[2];

                $cb->( $res );
                return;


                WRONG_RES:
                    $msg ||= "PSGI returned wrong response";
                    $msg .= "\n\n";
                    {
                        local $Data::Dumper::Indent = 1;
                        local $Data::Dumper::Terse = 1;
                        local $Data::Dumper::Useqq = 1;
                        local $Data::Dumper::Deepcopy = 1;
                        local $Data::Dumper::Maxdepth = 0;

                        my $dump = Data::Dumper->Dump([ $res, @res ]);
                        utf8::downgrade($dump) if utf8::is_utf8 $dump;
                        $msg .= $dump;
                    }

                    $cb->( [ 500, [ 'Content-Type', 'text/plain' ], [ $msg ]]);
                    return;
            }
        }
    }
}


1;

=head1 VCS

L<https://github.com/unera/coro-twiggy>

=head1 AUTHOR

 Dmitry E. Oboukhov, <unera@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
