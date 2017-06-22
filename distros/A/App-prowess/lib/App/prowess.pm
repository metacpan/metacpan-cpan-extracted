package App::prowess;
use strict;
use warnings;

our $VERSION = '0.05';

1;

=encoding utf8

=head1 NAME

App::prowess - Watch files for changes and re-run prove

=head1 VERSION

0.05

=head1 DESCRIPTION

L<App::prowess> is an application which will watch files for changes and the
re-run C<prove> on change.

=head1 SYNOPSIS

  # Watch default directories
  $ prowess -vl t/mytest.t

  # Watch just lib/ directory
  $ prowess -w lib -l -j6

  # Get debug information
  $ PROWESS_DEBUG=1 prowess -w lib t/mytest.t

C<-w> is used to watch directories or files for changes. C<-w> without a
following path will be passed on to C<prove> as the C<-w> flag.
Any other option is passed directly to C<prove>.

=head1 SEE ALSO

L<App::Prove::Watch> is an alternative to C<prowess>. The main difference is:

=over 4

=item *

C<prowess> will restart the test run on every file change. This means that
if the test has not completed, C<prove> will be C<kill>ed and restarted. This
is nice if you have tests that doesn't complete.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Stefan Adams - C<stefan@borgia.com>

=cut
