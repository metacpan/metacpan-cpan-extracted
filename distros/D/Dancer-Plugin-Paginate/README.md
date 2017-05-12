# NAME

Dancer::Plugin::Paginate - HTTP 1.1 Range-based Pagination for Dancer apps.

# VERSION

Version 1.0.1

# DESCRIPTION

HTTP 1.1 Range-based Pagination for Dancer apps.

Provides a simple wrapper to provide pagination of results via the HTTP 1.1 Range headers for AJAX requests.

# SYNOPSIS

To use, simply add the "paginate" keyword to any route that should support HTTP Range headers. The HTTP Request
will be processed and Dancer session variables will be populated with the items being requested.

    use Dancer::Plugin::Paginate;

    get '/data' => paginate sub { ... }
    ...

# Configuration Options

## Ajax-Only

Options: _true|false_

Default: **true**

Determines if paginate should only operate on Ajax requests.

## Mode

Options: _headers|parameters|both_

Default: **headers**

Controls if paginate will look for the pagination in the headers, parameters, or both.

If set to both, headers will be preferred.

### Headers Mode

Header mode will look for the following 2 Headers:

- Content-Range
- Range-Unit

Both are required.

You can read more about these at [http://www.ietf.org/rfc/rfc2616.txt](http://www.ietf.org/rfc/rfc2616.txt) and
[http://greenbytes.de/tech/webdav/draft-ietf-httpbis-p5-range-latest.html](http://greenbytes.de/tech/webdav/draft-ietf-httpbis-p5-range-latest.html).

Range-Unit will be returned to your app, but is not validated in any way.

### Parameters mode

Parameters mode will look the following parameters in any of Dancer's
parameter sources (query, route, or body):

- Start
- End
- Range-Unit

Start and End are required. Range-Unit will be populated with an empty string if not
available.

# Keywords

## paginate

The paginate keyword is used to add a pagination processing to a route. It will:

- Check if the request is AJAX (and stop processing if set to ajax-only).
- Extract the data from Headers, Parameters, or Both.
- Store these in Dancer Session Variables (defined below).
- Run the provided coderef for the route.
- Add proper headers and change status to 206 if coderef was successful.

Vars:

- range\_available - Boolean. Will return true if range was found.
- range - An arrayref of \[start, end\].
- range\_unit - The Range Unit provided in the request.

In your response, you an optionally provide the following Dancer Session Variables to customize response:

- total - The total count of items. Will return '\*' if not provided.
- return\_range - An arrayref of provided \[start, end\] values in your response. Original will be reused if not provided.
- return\_range\_unit - The unit of the range in your response. Original will be reused if not provided.

# AUTHOR

Colin Ewen, `<colin at draecas.com>`

# BUGS

Please report any bugs or feature requests to `bug-dancer-plugin-paginate at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Paginate](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Paginate).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Paginate

This is developed on GitHub - please feel free to raise issues or pull requests
against the repo at: [https://github.com/Casao/Dancer-Plugin-Paginate](https://github.com/Casao/Dancer-Plugin-Paginate).

# ACKNOWLEDGEMENTS

My thanks to David Precious, `<davidp at preshweb.co.uk>` for his
Dancer::Plugin::Auth::Extensible framework, which provided the Keyword
syntax used by this module. Parts were also used for testing purposes.

# LICENSE AND COPYRIGHT

Copyright 2014 Colin Ewen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
