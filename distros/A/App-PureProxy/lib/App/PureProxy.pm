#!/usr/bin/perl -c

package App::PureProxy;

=head1 NAME

App::PureProxy - a Pure Perl HTTP proxy server

=head1 SYNOPSIS

  $ pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

  $ pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

  $ pureproxy --access-log=access.log

  $ pureproxy --other-plackup-options

  $ pureproxy -v

  $ http_proxy=http://localhost:5000/ lwp-request http://www.perl.org/

  $ https_proxy=http://localhost:5000/ lwp-request https://metacpan.org/

=head1 DESCRIPTION

See pureproxy(1) for available command line options.

C<App::PureProxy> is not real module because pureproxy(1) is complete Perl
script and this module allows to install this script with cpan(1) or cpanm(1)
command.

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0100';


1;


=head1 INSTALLATION

=head2 With cpanm(1)

  $ cpanm App::PureProxy

=head2 Directly

  $ lwp-request http://git.io/jEE6 | sh

or

  $ curl -kL http://git.io/jEE6 | sh

or

  $ wget --quiet -O- http://git.io/jEE6 | sh

=head1 SEE ALSO

L<http://github.com/dex4er/PureProxy>, pureproxy(1).

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
