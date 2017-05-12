#!/bin/sh

: << POD

Yes! This is just a POSIX shell script but we need some Perl-like boilerplate.

use strict;
use warnings;

=head1 NAME

perluse - Use the specified perl in shell command

=head1 SYNOPSIS

B<perluse> I<version>
S<perl-I<version> | I<version> | I<name>>
[command]

Examples:

  $ perluse 5.18.1 perl -E 'say $^V'

  $ perluse blead perldoc perldelta

  $ perluse perl-5.18.1

  $ perluse

=head1 DESCRIPTION

This command wraps L<perlbrew> command and uses the given version perl in
current shell.

=cut

POD


VERSION=0.0102

PERLBREW_ROOT=${PERLBREW_ROOT:-$HOME/perl5/perlbrew}

if [ -x "$PERLBREW_ROOT/bin/perlbrew" ]; then
    perlbrew="$PERLBREW_ROOT/bin/perlbrew"
else
    perlbrew=perlbrew
fi

if [ ! -f "$PERLBREW_ROOT/etc/bashrc" ]; then
    $perlbrew init
fi

if [ -n "$BASH_VERSION" ]; then
    source "$PERLBREW_ROOT/etc/bashrc"
fi

if [ "$1" = "-v" ]; then
    echo "perluse $VERSION"
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "  perluse version [shell command]"
    echo ""
    echo "Installed versions:"
    $perlbrew list
    exit 1
fi

version="$1"
shift

env=`$perlbrew env "$version" | sed 's/^export //'` || exit 2
eval $env
export PERLBREW_MANPATH PERLBREW_PATH PERLBREW_ROOT PERLBREW_VERSION

PATH="$PERLBREW_PATH:${PATH:-/usr/bin:/bin}"
PERL5LIB=$(perl -le 'print join ":", grep { /site_perl/ } @INC')
debian_chroot="$PERLBREW_PERL"

export PATH PERL5LIB debian_chroot

if [ $# -gt 0 ]; then
    "$@"
    exit $?
else
    "${SHELL:-/bin/sh}" -i
    exit $?
fi


: << POD

=head1 INSTALLATION

=head2 With cpanm(1)

  $ cpanm App::perluse

=head2 Directly

  $ lwp-request http://git.io/dXVJCg | sh

or

  $ curl -kL http://git.io/dXVJCg | sh

=head1 SEE ALSO

L<perlbrew>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2011-2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut

POD
