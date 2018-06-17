package AWS::XRay;

use 5.012000;
use strict;
use warnings;

use Crypt::URandom ();
use IO::Socket::INET;
use Time::HiRes ();
use AWS::XRay::Segment;

use Exporter 'import';
our @EXPORT_OK = qw/ new_trace_id capture capture_from trace /;

our $VERSION = "0.02";

our $TRACE_ID;
our $SEGMENT_ID;
our $ENABLED = 1;
our $DAEMON_HOST = "127.0.0.1";
our $DAEMON_PORT = 2000;

if ($ENV{"AWS_XRAY_DAEMON_ADDRESS"}) {
    ($DAEMON_HOST, $DAEMON_PORT) = split /:/, $ENV{"AWS_XRAY_DAEMON_ADDRESS"};
}

my $Sock;

sub sock {
    $Sock //= IO::Socket::INET->new(
        PeerAddr => $DAEMON_HOST || "127.0.0.1",
        PeerPort => $DAEMON_PORT || 2000,
        Proto    => "udp",
    );
}

sub new_trace_id {
    sprintf(
        "1-%x-%s",
        CORE::time(),
        unpack("H*", Crypt::URandom::urandom(12)),
    );
}

sub new_id {
    unpack("H*", Crypt::URandom::urandom(8))
}

# alias for backward compatibility
*trace = \&capture;

sub capture {
    my ($name, $code) = @_;
    return $code->(AWS::XRay::Segment->new) if !$ENABLED;

    local $AWS::XRay::TRACE_ID = $AWS::XRay::TRACE_ID // new_trace_id();

    my $segment = AWS::XRay::Segment->new({ name => $name });
    local $AWS::XRay::SEGMENT_ID = $segment->{id};

    my @ret;
    eval {
        if (wantarray) {
            @ret = $code->($segment);
        }
        else {
            $ret[0] = $code->($segment);
        }
    };
    my $error = $@;
    if ($error) {
        $segment->{error} = Types::Serialiser::true;
        $segment->{cause} = {
            exceptions => [
                {
                    id      => new_id(),
                    message => "$error",
                    remote  => Types::Serialiser::true,
                },
            ],
        };
    }
    eval {
        $segment->close();
    };
    if ($@) {
        warn $@;
    }
    die $error if $error;
    return wantarray ? @ret : $ret[0];
}

sub capture_from {
    my ($header, $name, $code) = @_;
    local($AWS::XRay::TRACE_ID, $AWS::XRay::SEGMENT_ID) = parse_trace_header($header);
    capture($name, $code);
}

sub parse_trace_header {
    my $header = shift or return;

    my ($trace_id, $segment_id);
    if ($header =~ /Root=([0-9a-fA-F-]+)/) {
        $trace_id = $1;
    }
    if ($header =~ /Parent=([0-9a-fA-F]+)/) {
        $segment_id = $1;
    }
    return ($trace_id, $segment_id);
}

1;
__END__

=encoding utf-8

=head1 NAME

AWS::XRay - AWS X-Ray tracing library

=head1 SYNOPSIS

    use AWS::XRay qw/ capture /;

    capture "myApp", sub {
        capture "remote", sub {
            # do something ...
            capture "nested", sub {
                # ...
            };
        };
        capture "myHTTP", sub {
            my $segment = shift;
            # ...
            $segment->{http} = { # modify segument document
                request => {
                    method => "GET",
                    url    => "http://localhost/",
                },
                response => {
                    status => 200,
                },
            };
        };
    };

    my $header;
    capture "source", sub {
        my $segment = shift;
        $header = $segment->trace_header;
    };
    capture_from $header, "dest", sub {
        my $segment = shift;  # is a child of "source" segment
        # ...
    };

=head1 DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to L<AWS X-Ray Daemon|https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html>.

=head1 FUNCTIONS

=head2 new_trace_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

L<Document|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids>

=head2 capture($name, $code)

capture() executes $code->($segment) and send the segment document to X-Ray daemon.

$segment is a AWS::XRay::Segment object.

When $AWS::XRay::TRACE_ID is not set, generates TRACE_ID automatically.

When capture() called from other capture(), $segment is a sub segment document.

See also L<AWS X-Ray Segment Documents|https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html>.

=head2 capture_from($header, $name, $code)

capture_from() parses the trace header and capture the $code with sub segment of header's segment.

=head2 parse_trace_header($header)

    my ($trace_id, $segment_id) = parse_trace_header($header);

Parse a trace header (e.g. "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8").

=head1 CONFIGURATION

=head2 $AWS::XRay::Enabled

Default true. When set false, capture() executes sub but do not send segument documents to X-Ray daemon.

=head2 AWS_XRAY_DAEMON_ADDRESS environment variable

Set the host and port of the X-Ray daemon. Default 127.0.0.1:2000

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

