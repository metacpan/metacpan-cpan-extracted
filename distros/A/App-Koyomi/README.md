# NAME

App::Koyomi - A simple distributed job scheduler

# DESCRIPTION

**Koyomi** is a simple distributed job scheduler which achieves High Availability.

You can run _koyomi worker_ on several servers.
Then if one worker stops with any trouble, remaining workers will take after its jobs.

# DOCUMENTATION

Full documentation is available on [http://progrhyme.github.io/App-Koyomi-Doc/](http://progrhyme.github.io/App-Koyomi-Doc/).

# SEE ALSO

[koyomi](https://metacpan.org/pod/koyomi),
[koyomi-cli](https://metacpan.org/pod/koyomi-cli),
[App::Koyomi::Worker](https://metacpan.org/pod/App::Koyomi::Worker),
[App::Koyomi::CLI](https://metacpan.org/pod/App::Koyomi::CLI)

# AUTHORS

IKEDA Kiyoshi <progrhyme@gmail.com>

# LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.
