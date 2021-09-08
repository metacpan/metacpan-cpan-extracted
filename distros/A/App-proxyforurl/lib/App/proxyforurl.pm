package App::proxyforurl;
use strict;
use warnings;

our $VERSION = '0.09';

1;

=encoding utf8

=head1 NAME

App::proxyforurl - An online proxy PAC file parser

=head1 VERSION

0.09

=head1 DESCRIPTION

L<App::proxyforurl> is a web application that can be used to test proxy PAC
files.

The L<server side|Mojolicious> is used to serve the web page, but does also
provide functionlity for resolving hostnames and checking if an IP is within
a given net.

=head2 Demo

Check out L<https://app.thorsen.pm/proxyforurl> for a running example.

=head2 Missing features

The client side PAC parser does not fully support C<dateRange()>, C<timeRange()>
or C<weekdayRange()>. These functions simply return true, no matter what the
intput is.

=head1 SYNOPSIS

  $ proxyforurl --listen http://*:8080;

=head1 SEE ALSO

=over 4

=item * L<https://findproxyforurl.com/>

=item * L<https://github.com/pacparser/pacparser>

=back

=head1 DISCLAIMER

The parsing is done using good old C<eval()> on the client side, which means
that the pasted PAC file could in theory contain code which could steal
cookies, inject alien JavaScript or do other harmful things.

There is a safety net installed to prevent this from happening, but since
this is software, there might be bugs.

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
