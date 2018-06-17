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

# CONFIGURATION

## $AWS::XRay::Enabled

Default true. When set false, capture() executes sub but do not send segument documents to X-Ray daemon.

## AWS\_XRAY\_DAEMON\_ADDRESS environment variable

Set the host and port of the X-Ray daemon. Default 127.0.0.1:2000

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
