[![Build Status](https://travis-ci.org/dex4er/perluse.png?branch=master)](https://travis-ci.org/dex4er/perluse)

# NAME

perluse - Use the specified perl in shell command

# SYNOPSIS

__perluse__ _version_
perl-_version_&nbsp;|&nbsp;_version_&nbsp;|&nbsp;_name_
\[command\]

Examples:

    $ perluse 5.18.1 perl -E 'say $^V'

    $ perluse blead perldoc perldelta

    $ perluse perl-5.18.1

    $ perluse

# DESCRIPTION

This command wraps [perlbrew](https://metacpan.org/pod/perlbrew) command and uses the given version perl in
current shell.

# INSTALLATION

## With cpanm(1)

    $ cpanm App::perluse

## Directly

    $ lwp-request http://git.io/dXVJCg | sh

or

    $ curl -kL http://git.io/dXVJCg | sh

# SEE ALSO

[perlbrew](https://metacpan.org/pod/perlbrew).

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2011-2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
