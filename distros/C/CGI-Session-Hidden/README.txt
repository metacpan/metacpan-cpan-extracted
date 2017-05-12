CGI::Session::Driver::hidden - for CGI::Session 4.x
CGI::Session::Hidden         - for CGI::Session 3.x

  A CGI::Session driver that uses HTML <hidden> fields
to store session data. It is almost, but not quite, a drop-in
replacement for other CGI::Session drivers.

Mattia Barbon <mbarbon@cpan.org>

To install:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

or

    perl Makefile.PL
    make
    make test
    make install

Copyright (c) 2005-2006, 2008 Mattia Barbon. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The latest sources can be found on GitHub at
http://github.com/mbarbon/cgi-session-hidden/tree
