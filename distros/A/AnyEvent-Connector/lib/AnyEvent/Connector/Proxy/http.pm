package AnyEvent::Connector::Proxy::http;
use strict;
use warnings;
use AnyEvent::Handle;

sub new {
    my ($class, $uri) = @_;
    my $self = bless {
        uri => $uri
    }, $class;
    return $self;
}

sub uri_string {
    my ($self) = @_;
    return $self->{uri}->as_string;
}

sub host {
    my ($self) = @_;
    return $self->{uri}->host;
}

sub port {
    my ($self) = @_;
    return $self->{uri}->port;
}

sub establish_proxy {
    my ($self, $fh, $target_host, $target_port, $cb) = @_;
    my $ah;
    $ah = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
            ## TODO: how should we report the error detail?
            $cb->(0);
        },
        on_eof => sub {
            $cb->(0);
        },
    );
    $ah->push_write(
        "CONNECT $target_host:$target_port HTTP/1.1\r\n" .
        "Host: $target_host:$target_port\r\n\r\n"
    );
    my $header_reader;
    $header_reader = sub {
        my ($h, $line) = @_;
        if($line eq "") {
            $ah->destroy();
            undef $ah;
            $cb->(1);
        }else {
            $ah->push_read(line => $header_reader);
        }
    };
    $ah->push_read(line => sub {
        my ($h, $line) = @_;
        if($line !~ qr{^HTTP/1\S* +(\d{3})}) {
            $ah->destroy();
            undef $ah;
            $cb->(0);
        }
        my $status = $1;
        if(int($status / 100) != 2) {
            $ah->destroy();
            undef $ah;
            $cb->(0);
        }
        $ah->push_read(line => $header_reader);
    });
}


1;

__END__

=pod

=head1 NAME

AnyEvent::Connector::Proxy::http - http Proxy connector

=head1 DESCRIPTION

This module is internal. End-users should not use it directly.

=cut
