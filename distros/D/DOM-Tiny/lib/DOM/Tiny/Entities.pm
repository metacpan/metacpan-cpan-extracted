package DOM::Tiny::Entities;

use strict;
use warnings;
use Exporter 'import';
use Mojo::DOM58::Entities qw(html_escape html_unescape);

our $VERSION = '0.005';

our @EXPORT_OK = qw(html_escape html_unescape);

1;

=encoding utf8

=head1 NAME

DOM::Tiny::Entities - This is an empty re-exporter, you wanted Mojo::DOM58::Entities

=head1 IT'S DEAD, JIM.

Development continues under the name L<Mojo::DOM58::Entities>.

This is an empty re-exporter therefor to avoid defecating on existing users
from a great height, but you should still update your code.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<HTML::Entities>

=cut
