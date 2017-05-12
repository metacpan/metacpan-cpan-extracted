Apache/Dir version 0.07
=======================

This simple module is designed to be a partial replacement for the standard
Apache mod_dir module. One of the things that module does is to redirect
browsers to a directory URL ending in a slash when they request the directory
without the slash. Since mod_dir seems do its thing during the Apache response
phase, if you use a Perl handler, it won't run. This can be problematic if the
Perl handler doesn't likewise take the directory redirecting into account.

A good example is HTML::Mason. If you've disabled Mason's decline_dirs
parameter (MasonDeclineDirs 0 in httpd.conf), and there's a dhandler in the
directory /foo, then for a request for /foo, /foo/dhandler will respond. This
can wreak havoc if you use relative URLs in the dhandler. What really should
happen is that a request for /foo will be redirected to /foo/ before Mason
ever sees it.

This is the problem that this module is designed to address. Configuration
would then look something like this:

    <Location /foo>
      PerlSetVar       MasonDeclineDirs 0
      PerlModule       Apache::Dir
      PerlModule       HTML::Mason::ApacheHandler
      SetHandler       perl-script
      PerlFixupHandler Apache::Dir
      PerlHandler      HTML::Mason::ApacheHandler
    </Location>

Apache::Dir can also be configured to handle the request during the response
cycle, if you wish. Just specify it before any other Perl handler to have it
execute first:

    <Location /foo>
      PerlSetVar  MasonDeclineDirs 0
      PerlModule  Apache::Dir
      PerlModule  HTML::Mason::ApacheHandler
      SetHandler  perl-script
      PerlHandler Apache::Dir HTML::Mason::ApacheHandler
    </Location>

Dependencies
------------

    mod_perl

Author
------

David E. Wheeler <david@justatheory.com>

Copyright and License
---------------------

Copyright 2004-2011 by David Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

