package Database::Async::SQLite 0.001;
# ABSTRACT: SQLite support for IO::Async

use strict;
use warnings;

use parent qw(DynaLoader);

our $VERSION = '0.001';

=encoding utf8

=head1 NAME

Database::Async::SQLite - support for an SQLite thread in L<IO::Async> code

=head1 DESCRIPTION

B<This is not currently usable>. Please don't get your hopes up - it's merely a
compilation test to see whether C++11 and XS is a viable mix.

=head2 IMPLEMENTATION

This uses a combination of C<eventfd> for signalling, and a Unix-domain socket
for data transfer. There's a minimal sqlite binding which runs in a separate
thread, accepting sqlite instructions (queries etc.) and sending back data/errors
as appropriate.

The original code used a standalone worker pool - this version moves that in-process
and switches to XS.

No method documentation or usage examples, for reasons that may become apparent if
you read the above paragraphs.

=cut

__PACKAGE__->bootstrap(__PACKAGE__->VERSION);

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2017. Licensed under the same terms as Perl itself.

