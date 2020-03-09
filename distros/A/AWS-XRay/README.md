# NAME

AWS::XRay - AWS X-Ray tracing library

# SYNOPSIS

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

# DESCRIPTION

AWS::XRay is a tracing library with AWS X-Ray.

AWS::XRay sends segment data to [AWS X-Ray Daemon](https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html).

# FUNCTIONS

## new\_trace\_id

Generate a Trace ID. (e.g. "1-581cf771-a006649127e371903a2de979")

[Document](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html#xray-api-traceids)

## capture($name, $code)

capture() executes $code->($segment) and send the segment document to X-Ray daemon.

$segment is a AWS::XRay::Segment object.

When $AWS::XRay::TRACE\_ID is not set, generates TRACE\_ID automatically.

When capture() called from other capture(), $segment is a sub segment document.

See also [AWS X-Ray Segment Documents](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html).

## capture\_from($header, $name, $code)

capture\_from() parses the trace header and capture the $code with sub segment of header's segment.

## parse\_trace\_header($header)

    my ($trace_id, $segment_id) = parse_trace_header($header);

Parse a trace header (e.g. "Root=1-5759e988-bd862e3fe1be46a994272793;Parent=53995c3f42cd8ad8").

## add\_capture($package, $method1\[, $method2, ...\])

add\_capture() adds a capture to package::method.

    AWS::XRay->add_capture("MyApp::Model", "foo", "bar");

The segments of these captures are named as "MyApp::Model".
These segments include metadata "method": "foo" or "bar".

# CONFIGURATION

## sampling\_rate($rate)

Set/Get a sampling rate for capture().

    AWS::XRay->sampling_rate(0.1); # 10% sampling

$rate is allowed a float value between 0 and 1.

0 means disable tracing.
1 means all of capture() are traced.

When capture\_from() called with a trace header includes "Sampled=1", all of followed capture() are traced.

## sampler($code)

Set/Get a code ref to sample for capture().

    AWS::XRay->sampler(sub {
        if ($some_condition) {
           return 1;
        } else {
           return 0;
        }
    });

## auto\_flush($mode)

Set/Get auto flush mode.

When $mode is 1 (default), segment data will be sent to xray daemon immediately after capture() called.

When $mode is 0, segment data are buffered in memory. You should call AWS::XRay->sock->flush() to send the buffered segment data or call AWS::XRay->sock->close() to discard the buffer.

## AWS\_XRAY\_DAEMON\_ADDRESS environment variable

Set the host and port of the X-Ray daemon. Default 127.0.0.1:2000

## $AWS::XRay::CROAK\_INVALID\_NAME

When set to 1 (default 0), capture() will raise exception if a segment name is invalid.

See https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html

> name – The logical name of the service that handled the request, up to 200 characters.
> For example, your application's name or domain name.
> Names can contain Unicode letters, numbers, and whitespace, and the following symbols: \_, ., :, /, %, &, #, =, +, \\, -, @

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
