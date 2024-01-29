#!/usr/bin/perl -c

package App::PureProxy;

=head1 NAME

App::PureProxy - Pure Perl HTTP proxy server

=head1 SYNOPSIS

=for markdown ```sh

    pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

    pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

    pureproxy --access-log=access.log

    pureproxy --other-plackup-options

    pureproxy -v

    http_proxy=http://localhost:5000/ lwp-request http://www.perl.org/

    https_proxy=http://localhost:5000/ lwp-request https://metacpan.org/

=for markdown ```

=head1 DESCRIPTION

See pureproxy(1) for available command line options.

C<App::PureProxy> is not real module because pureproxy(1) is complete Perl
script and this module allows to install this script with cpan(1) or cpanm(1)
command.

=cut

use 5.008_001;

use strict;
use warnings;

our $VERSION = '0.0200';

1;

__END__

=head1 INSTALLATION

=head2 With cpanm(1)

=for markdown ```sh

    cpanm App::PureProxy

=for markdown ```

=head2 Directly

=for markdown ```sh

    lwp-request -m get https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

or

=for markdown ```sh

    curl -qsSL https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

or

=for markdown ```sh

    wget --quiet -O- https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

=head1 SEE ALSO

L<http://github.com/dex4er/PureProxy>, pureproxy(1).

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014-2015, 2023-2024 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
