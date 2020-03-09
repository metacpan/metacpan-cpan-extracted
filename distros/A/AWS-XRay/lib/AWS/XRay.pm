package AWS::XRay;

use 5.012000;
use strict;
use warnings;

use Crypt::URandom ();
use IO::Socket::INET;
use Module::Load;
use Time::HiRes ();
use Types::Serialiser;
use AWS::XRay::Segment;
use AWS::XRay::Buffer;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw/ new_trace_id capture capture_from trace /;

our $VERSION = "0.11";

our $TRACE_ID;
our $SEGMENT_ID;
our $ENABLED;
our $SAMPLED;
our $SAMPLING_RATE = 1;
our $SAMPLER       = sub { rand() < $SAMPLING_RATE };
our $AUTO_FLUSH    = 1;

our @PLUGINS;

our $DAEMON_HOST = "127.0.0.1";
our $DAEMON_PORT = 2000;

our $CROAK_INVALID_NAME = 0;
my $VALID_NAME_REGEXP = qr/\A[\p{L}\p{N}\p{Z}_.:\/%&#=+\\\-@]{1,200}\z/;

if ($ENV{"AWS_XRAY_DAEMON_ADDRESS"}) {
    ($DAEMON_HOST, $DAEMON_PORT) = split /:/, $ENV{"AWS_XRAY_DAEMON_ADDRESS"};
}

my $Sock;

sub sampling_rate {
    my $class = shift;
    if (@_) {
        $SAMPLING_RATE = shift;
    }
    $SAMPLING_RATE;
}

sub sampler {
    my $class = shift;
    if (@_) {
        $SAMPLER = shift;
    }
    $SAMPLER;
}

sub plugins {
    my $class = shift;
    if (@_) {
        @PLUGINS = @_;
        Module::Load::load $_ for @PLUGINS;
    }
    @PLUGINS;
}

sub auto_flush {
    my $class = shift;
    if (@_) {
        my $auto_flush = shift;
        if ($auto_flush != $AUTO_FLUSH) {
            $Sock->close if $Sock && $Sock->can("close");
            undef $Sock; # regenerate
        }
        $AUTO_FLUSH = $auto_flush;
    }
    $AUTO_FLUSH;
}

sub sock {
    $Sock //= AWS::XRay::Buffer->new(
        IO::Socket::INET->new(
            PeerAddr => $DAEMON_HOST || "127.0.0.1",
            PeerPort => $DAEMON_PORT || 2000,
            Proto    => "udp",
        ),
        $AUTO_FLUSH,
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
    unpack("H*", Crypt::URandom::urandom(8));
}

sub is_valid_name {
    $_[0] =~ $VALID_NAME_REGEXP;
}

# alias for backward compatibility
*trace = \&capture;

sub capture {
    my ($name, $code) = @_;
    if (!is_valid_name($name)) {
        my $msg = "invalid segment name: $name";
        $CROAK_INVALID_NAME ? croak($msg) : carp($msg);
    }
    my $wantarray = wantarray;

    my $enabled;
    my $sampled = $SAMPLED;
    if (defined $ENABLED) {
        $enabled = $ENABLED ? 1 : 0; # fix true or false (not undef)
    }
    elsif ($TRACE_ID) {
        $enabled = 0;                # called from parent capture
    }
    else {
        # root capture try sampling
        $sampled = $SAMPLER->() ? 1 : 0;
        $enabled = $sampled     ? 1 : 0;
    }
    local $ENABLED = $enabled;
    local $SAMPLED = $sampled;

    return $code->(AWS::XRay::Segment->new) if !$enabled;

    local $TRACE_ID = $TRACE_ID // new_trace_id();

    my $segment = AWS::XRay::Segment->new({ name => $name });
    unless (defined $segment->{type} && $segment->{type} eq "subsegment") {
        $_->apply_plugin($segment) for @PLUGINS;
    }

    local $SEGMENT_ID = $segment->{id};

    my @ret;
    eval {
        if ($wantarray) {
            @ret = $code->($segment);
        }
        elsif (defined $wantarray) {
            $ret[0] = $code->($segment);
        }
        else {
            $code->($segment);
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
    return $wantarray ? @ret : $ret[0];
}

sub capture_from {
    my ($header,   $name,       $code)    = @_;
    my ($trace_id, $segment_id, $sampled) = parse_trace_header($header);

    local $AWS::XRay::SAMPLED = $sampled // $SAMPLER->();
    local $AWS::XRay::ENABLED = $AWS::XRay::SAMPLED;
    local ($AWS::XRay::TRACE_ID, $AWS::XRay::SEGMENT_ID) = ($trace_id, $segment_id);
    capture($name, $code);
}

sub parse_trace_header {
    my $header = shift or return;

    my ($trace_id, $segment_id, $sampled);
    if ($header =~ /Root=([0-9a-fA-F-]+)/) {
        $trace_id = $1;
    }
    if ($header =~ /Parent=([0-9a-fA-F]+)/) {
        $segment_id = $1;
    }
    if ($header =~ /Sampled=([^;]+)/) {
        $sampled = $1;
    }
    return ($trace_id, $segment_id, $sampled);
}

sub add_capture {
    my ($class, $package, @methods) = @_;
    no warnings 'redefine';
    no strict 'refs';
    for my $method (@methods) {
        my $orig = $package->can($method) or next;
        *{"${package}::${method}"} = sub {
            my @args = @_;
            capture(
                $package,
                sub {
                    my $segment = shift;
                    $segment->{metadata}->{method}  = $method;
                    $segment->{metadata}->{package} = $package;
                    $orig->(@args);
                },
            );
        };
    }
}

if ($ENV{LAMBDA_TASK_ROOT}) {
    # AWS::XRay is loaded in AWS Lambda worker.
    # notify the Lambda Runtime that initialization is complete.
    unless (mkdir '/tmp/.aws-xray') {
        # ignore the error if the directory is already exits or other process created it.
        my $err = $!;
        unless (-d '/tmp/.aws-xray') {
            warn "failed to make directory: $err";
        }
    }
    open my $fh, '>', '/tmp/.aws-xray/initialized' or warn "failed to create file: $!";
    close $fh;
    utime undef, undef, '/tmp/.aws-xray/initialized' or warn "failed to touch file: $!";

    # patch the capture
    no warnings 'redefine';
    no strict 'refs';
    my $org = \&capture;
    *capture = sub {
        my ($trace_id, $segment_id, $sampled) = parse_trace_header($ENV{_X_AMZN_TRACE_ID});
        local $AWS::XRay::SAMPLED = $sampled // $SAMPLER->();
        local $AWS::XRay::ENABLED = $AWS::XRay::SAMPLED;
        local ($AWS::XRay::TRACE_ID, $AWS::XRay::SEGMENT_ID) = ($trace_id, $segment_id);
        local *capture = $org;
        local *trace   = $org;
        capture(@_);
    };
    *trace = \&capture;
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
            $segment->{http} = { # modify segment document
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

=head2 add_capture($package, $method1[, $method2, ...])

add_capture() adds a capture to package::method.

    AWS::XRay->add_capture("MyApp::Model", "foo", "bar");

The segments of these captures are named as "MyApp::Model".
These segments include metadata "method": "foo" or "bar".

=head1 CONFIGURATION

=head2 sampling_rate($rate)

Set/Get a sampling rate for capture().

    AWS::XRay->sampling_rate(0.1); # 10% sampling

$rate is allowed a float value between 0 and 1.

0 means disable tracing.
1 means all of capture() are traced.

When capture_from() called with a trace header includes "Sampled=1", all of followed capture() are traced.

=head2 sampler($code)

Set/Get a code ref to sample for capture().

    AWS::XRay->sampler(sub {
        if ($some_condition) {
           return 1;
        } else {
           return 0;
        }
    });

=head2 auto_flush($mode)

Set/Get auto flush mode.

When $mode is 1 (default), segment data will be sent to xray daemon immediately after capture() called.

When $mode is 0, segment data are buffered in memory. You should call AWS::XRay->sock->flush() to send the buffered segment data or call AWS::XRay->sock->close() to discard the buffer.

=head2 AWS_XRAY_DAEMON_ADDRESS environment variable

Set the host and port of the X-Ray daemon. Default 127.0.0.1:2000

=head2 $AWS::XRay::CROAK_INVALID_NAME

When set to 1 (default 0), capture() will raise exception if a segment name is invalid.

See https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html

=over

name – The logical name of the service that handled the request, up to 200 characters.
For example, your application's name or domain name.
Names can contain Unicode letters, numbers, and whitespace, and the following symbols: _, ., :, /, %, &, #, =, +, \, -, @

=back

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut
