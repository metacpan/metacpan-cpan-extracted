# NAME

Apache::LoadAvgLimit - limiting client request by system CPU load-averages (deprecated)

# SYNOPSIS

    in httpd.conf, simply

    <Location /perl>
      PerlInitHandler Apache::LoadAvgLimit
      PerlSetVar LoadAvgLimit 2.5
    </Location>

    or fully

    <Location /perl>
      PerlInitHandler Apache::LoadAvgLimit
      PerlSetVar LoadAvgLimit_1 3.00
      PerlSetVar LoadAvgLimit_5 2.00
      PerlSetVar LoadAvgLimit_15 1.50
      PerlSetVar LoadAvgRetryAfter 120
    </Location>

# CAUTION

__THIS MODULE IS MARKED AS DEPRECATED.__

The module may still work for you, but consider switch to psgi like below:

    use Plack::Builder;
    use HTTP::Exception;
    use Sys::Load;

    builder {
        enable 'HTTPExceptions';
        enable_if { (Sys::Load::getload())[0] > 3.00 }
            sub { sub { HTTP::Exception::503->throw } };

        $app;
    };

You can run mod\_perl1 application as psgi with [Plack::Handler::Apache1](http://search.cpan.org/perldoc?Plack::Handler::Apache1).

# DESCRIPTION

If system load-average is over the value of __LoadAvgLimit\*__, 
Apache::LoadAvgLimit will try to reduce the machine load by returning
HTTP status 503 (Service Temporarily Unavailable) to client browser.

Especially, it may be useful in <Location> directory that has heavy CGI,
Apache::Registry script or contents-handler program.

# PARAMETERS

__LoadAvgLimit__

When at least one of three load-averages (1, 5, 15 min) is over this
value, returning status code 503.

__LoadAvgLimit\_1__, 
__LoadAvgLimit\_5__, 
__LoadAvgLimit\_15__

When Each minute's load-averages(1, 5, 15 min) is over this value,
returning status code 503.

__LoadAvgRetryAfter__

The second(s) that indicates how long the service is expected to be
unavailable to browser. When this value exists, Retry-After field is
automatically set.

# AUTHOR

Ryo Okamoto <ryo@aquahill.net>

# SEE ALSO

mod\_perl(3), Apache(3), getloadavg(3), uptime(1), RFC1945, RFC2616, 
mod\_loadavg

# REPOSITORY

https://github.com/ryochin/p5-apache-loadavglimit

# AUTHOR

Ryo Okamoto <ryo@aquahill.net>

# COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
