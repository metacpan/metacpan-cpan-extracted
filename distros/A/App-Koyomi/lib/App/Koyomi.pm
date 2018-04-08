package App::Koyomi;

use strict;
use warnings;
use 5.010_001;

use version; our $VERSION = 'v0.6.1';

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi - A simple distributed job scheduler

=head1 DESCRIPTION

B<Koyomi> is a simple distributed job scheduler which achieves High Availability.

You can run I<koyomi worker> on several servers.
Then if one worker stops with any trouble, remaining workers will take after its jobs.

=head1 DOCUMENTATION

Full documentation is available on L<http://progrhyme.github.io/App-Koyomi-Doc/>.

=head1 SEE ALSO

L<koyomi>,
L<koyomi-cli>,
L<App::Koyomi::Worker>,
L<App::Koyomi::CLI>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

