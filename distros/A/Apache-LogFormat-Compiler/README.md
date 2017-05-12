[![Build Status](https://travis-ci.org/kazeburo/Apache-LogFormat-Compiler.svg?branch=master)](https://travis-ci.org/kazeburo/Apache-LogFormat-Compiler)
# NAME

Apache::LogFormat::Compiler - Compile a log format string to perl-code 

# SYNOPSIS

    use Apache::LogFormat::Compiler;

    my $log_handler = Apache::LogFormat::Compiler->new("combined");
    my $log = $log_handler->log_line(
        $env,
        $res,
        $length,
        $reqtime,
        $time
    );

# DESCRIPTION

Compile a log format string to perl-code. For faster generation of access\_log lines.

# METHOD

- new($fmt:String)

    Takes a format string (or a preset template `combined` or `custom`)
    to specify the log format. This module implements a subset of
    [Apache's LogFormat templates](http://httpd.apache.org/docs/2.0/mod/mod_log_config.html):

        %%    a percent sign
        %h    REMOTE_ADDR from the PSGI environment, or -
        %l    remote logname not implemented (currently always -)
        %u    REMOTE_USER from the PSGI environment, or -
        %t    [local timestamp, in default format]
        %r    REQUEST_METHOD, REQUEST_URI and SERVER_PROTOCOL from the PSGI environment
        %s    the HTTP status code of the response
        %b    content length of the response
        %T    custom field for handling times in subclasses
        %D    custom field for handling sub-second times in subclasses
        %v    SERVER_NAME from the PSGI environment, or -
        %V    HTTP_HOST or SERVER_NAME from the PSGI environment, or -
        %p    SERVER_PORT from the PSGI environment
        %P    the worker's process id
        %m    REQUEST_METHOD from the PSGI environment
        %U    PATH_INFO from the PSGI environment
        %q    QUERY_STRING from the PSGI environment
        %H    SERVER_PROTOCOL from the PSGI environment

    In addition, custom values can be referenced, using `%{name}`,
    with one of the mandatory modifier flags `i`, `o` or `t`:

        %{variable-name}i    HTTP_VARIABLE_NAME value from the PSGI environment
        %{header-name}o      header-name header in the response
        %{time-format]t      localtime in the specified strftime format

- log\_line($env:HashRef, $res:ArrayRef, $length:Integer, $reqtime:Integer, $time:Integer): $log:String

    Generates log line.

        $env      PSGI env request HashRef
        $res      PSGI response ArrayRef
        $length   Content-Length
        $reqtime  The time taken to serve request in microseconds. optional
        $time     Time the request was received. optional. If $time is undefined. current timestamp is used.

    Sample psgi 

        use Plack::Builder;
        use Time::HiRes;
        use Apache::LogFormat::Compiler;

        my $log_handler = Apache::LogFormat::Compiler->new(
            '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D'
        );
        my $compile_log_app = builder {
            enable sub {
                my $app = shift;
                sub {
                    my $env = shift;
                    my $t0 = [gettimeofday];
                    my $res = $app->();
                    my $reqtime = int(Time::HiRes::tv_interval($t0) * 1_000_000);
                    $env->{psgi.error}->print($log_handler->log_line(
                        $env,$res,6,$reqtime, $t0->[0]));
                }
            };
            $app
        };

# ABOUT POSIX::strftime::Compiler

This module uses [POSIX::strftime::Compiler](https://metacpan.org/pod/POSIX::strftime::Compiler) for generate datetime string. POSIX::strftime::Compiler provides GNU C library compatible strftime(3). But this module will not affected by the system locale. This feature is useful when you want to write loggers, servers and portable applications.

# ADD CUSTOM FORMAT STRING

Apache::LogFormat::Compiler allows one to add a custom format string

    my $log_handler = Apache::LogFormat::Compiler->new(
        '%z %{HTTP_X_FORWARDED_FOR|REMOTE_ADDR}Z',
        char_handlers => +{
            'z' => sub {
                my ($env,$req) = @_;
                return $env->{HTTP_X_FORWARDED_FOR};
            }
        },
        block_handlers => +{
            'Z' => sub {
                my ($block,$env,$req) = @_;
                # block eq 'HTTP_X_FORWARDED_FOR|REMOTE_ADDR'
                my ($main, $alt) = split('\|', $args);
                return exists $env->{$main} ? $env->{$main} : $env->{$alt};
            }
        },
    );

Any single letter can be used, other than those already defined by Apache::LogFormat::Compiler.
Your sub is called with two or three arguments: the content inside the `{}`
from the format (block\_handlers only), the PSGI environment (`$env`),
and the ArrayRef of the response. It should return the string to be logged.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

# SEE ALSO

[Plack::Middleware::AccessLog](https://metacpan.org/pod/Plack::Middleware::AccessLog), [http://httpd.apache.org/docs/2.2/mod/mod\_log\_config.html](http://httpd.apache.org/docs/2.2/mod/mod_log_config.html)

# LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
