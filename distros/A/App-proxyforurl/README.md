# NAME

App::proxyforurl - An online proxy PAC file parser

# VERSION

0.11

# DESCRIPTION

[App::proxyforurl](https://metacpan.org/pod/App%3A%3Aproxyforurl) is a web application that can be used to test proxy PAC
files.

The [server side](https://metacpan.org/pod/Mojolicious) is used to serve the web page, but does also
provide functionlity for resolving hostnames and checking if an IP is within
a given net.

## Demo

Check out [https://app.thorsen.pm/proxyforurl](https://app.thorsen.pm/proxyforurl) for a running example.

## Missing features

The client side PAC parser does not fully support `dateRange()`, `timeRange()`
or `weekdayRange()`. These functions simply return true, no matter what the
intput is.

# SYNOPSIS

    $ proxyforurl --listen http://*:8080;

# SEE ALSO

- [https://findproxyforurl.com/](https://findproxyforurl.com/)
- [https://github.com/pacparser/pacparser](https://github.com/pacparser/pacparser)

# DISCLAIMER

The parsing is done using good old `eval()` on the client side, which means
that the pasted PAC file could in theory contain code which could steal
cookies, inject alien JavaScript or do other harmful things.

There is a safety net installed to prevent this from happening, but since
this is software, there might be bugs.

# COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
