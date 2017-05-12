package AnyEvent::REST::Server;

use strict;
use warnings;

use AnyEvent::Handle;
use AnyEvent::Socket;
use Log::Any qw($log);


our $VERSION = 0.05;


my $HTTP_CODE_TEXT = {
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    208 => 'Already Reported',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',
    422 => 'Unprocessable Entity',
    423 => 'Locked',
    424 => 'Failed Dependency',
    425 => 'No code',
    426 => 'Upgrade Required',
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    449 => 'Retry with',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',
    507 => 'Insufficient Storage',
    509 => 'Bandwidth Limit Exceeded',
    510 => 'Not Extended',
    511 => 'Network Authentication Required',
};

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    my $self = { @_ };
    bless $self, $class;

    return $self;
}

sub register {
    my $self = shift;
    my $regs = { @_ };

    while (my ($url_regex, $callback) = each %$regs) {
        push @{$self->{urls}}, $url_regex;
        $self->{callback}{$url_regex} = $callback;
    }
}

sub start {
    my $self = shift;

    $log->debug("Setting up AnyEvent::REST::Server on $self->{host}:$self->{port}.");

    $self->{tcp_server} = tcp_server(
        $self->{host},
        $self->{port},
        sub {
            my ($fh, $host, $port) = @_;
            my $id = "$host:$port";

            $log->debug("$id connected.");

            $self->{connections}{$id}{handle} = AnyEvent::Handle->new(
                fh => $fh,
                poll => 'r',
                on_error => sub {
                    my ($handle, $fatal, $message) = @_;
                    $handle->destroy;
                    delete $self->{connections}{$id};
                    $log->debug("$id disconnected.");
                },
            );

            $self->read_http_command($id);
        }
    );
}

sub read_http_command {
    my ($self, $id) = @_;

    $self->{connections}{$id}{handle}->push_read(
        regex => qr<(GET|POST|PUT|DELETE)\s+([^ ]+)\s+HTTP/(\d.\d)\r?\n>,
        sub {
            my ($handle, $data) = @_;
            $self->{connections}{$id}{command} = $1;
            $self->{connections}{$id}{location} = $2;
            $self->{connections}{$id}{version} = $3;

            if ($self->{connections}{$id}{location} =~ /(.*)\/$/) {
                $self->{connections}{$id}{location} = $1;
            }

            if ($self->can_handle("$self->{connections}{$id}{command} $self->{connections}{$id}{location}")) {
                $self->read_http_header($id);
            }
            else {
                $self->send_not_found($id);
            }
        }
    );
}

sub read_http_header {
    my ($self, $id) = @_;

    $self->{connections}{$id}{handle}->push_read(
        line => qr<\r?\n\r?\n>,
        sub {
            my ($handle, $line) = @_;
            my @header_lines = split(/\r?\n/, $line);

            foreach (@header_lines) {
                my ($key, $value) = split ':';
                $self->{connections}{$id}{header}{$key} = $value;
            }

            $self->read_http_body($id);
        }
    );
}

sub read_http_body {
    my ($self, $id) = @_;

    my $content_length = $self->{connections}{$id}{header}{'Content-Length'};

    if (defined $content_length && int($content_length)) {
        $self->{connections}{$id}{handle}->push_read(
            chunk => int($content_length),
            sub {
                my ($handle, $body) = @_;
                $self->{connections}{$id}{body} = $body;

            }
        );
    }

    my $command = $self->{connections}{$id}{command};
    my $location = $self->{connections}{$id}{location};
    $log->debug("$id HTTP $command $location");
    $self->request($id, "$command $location");

    $self->cleanup_restart($id);
}

sub cleanup_restart {
    my ($self, $id) = @_;

    $self->{connections}{$id}{handle}->rbuf = "";
    $self->read_http_command($id);
}

sub can_handle {
    my ($self, $url) = @_;

    foreach my $url_regex (@{$self->{urls}}) {
        return 1 if ($url =~ m/^$url_regex$/);
    }

    return 0;
}

sub request {
    my ($self, $id, $url) = @_;

    foreach my $url_regex (@{$self->{urls}}) {
        if ($url =~ m/^$url_regex$/) {
            $self->send($id, &{$self->{callback}{$url_regex}}($url, %+));
        }
    }
}

sub send {
    my ($self, $id, $code, $custom_header, $body) = @_;

    my $HTTP_EOL = "\r\n";

    my $header = {
        'Cache-Control' => 'max-age=0, no-cache, must-revalidate, proxy-revalidate, private',
        'Pragma' => 'no-cache',
        'Content-Type' => 'application/octet-stream',
        %$custom_header,
        'Content-Length' => length($body),
        'Server' => $self->{name},
    };

    my $response = 'HTTP/'.$self->{connections}{$id}{version}.' '.$code.' '.$HTTP_CODE_TEXT->{$code}.$HTTP_EOL;
    $response .= "$_: $header->{$_}$HTTP_EOL" foreach (keys %$header);
    $response .= $HTTP_EOL;
    $response .= $body if $body;

    $self->{connections}{$id}{handle}->push_write($response);
}

sub send_not_found {
    shift->send(shift, 404, {}, '');
}

1;
