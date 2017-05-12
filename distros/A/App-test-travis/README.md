# NAME

App::test::travis - Runs Travis-CI scripts (.travis.yml)

# USAGE

    test-travis [--dry-run] [.travis.yml]

# DESCRIPTION

`test-travis(1)` is a helper script which runs scripts defined in `.travis.yml`, emulating Travis-CI environments.

Note that the actual Travis-CI runs projects on Linux, so Linux specific commands like `apt-get(1)` won't work.

# SEE ALSO

[http://about.travis-ci.org/docs/user/getting-started/](http://about.travis-ci.org/docs/user/getting-started/)

[http://about.travis-ci.org/docs/user/build-configuration/\#Build-Lifecycle](http://about.travis-ci.org/docs/user/build-configuration/\#Build-Lifecycle) for the build lifecycle

# LICENSE

Copyright (C) Fuji, Goro (gfx) <gfuji@cpan.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Fuji, Goro (gfx) <gfuji@cpan.org>
