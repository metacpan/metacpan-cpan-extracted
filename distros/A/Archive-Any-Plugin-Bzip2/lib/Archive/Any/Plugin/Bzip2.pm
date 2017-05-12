package Archive::Any::Plugin::Bzip2;

use strict;
use warnings;
use base 'Archive::Any::Plugin::Tar';

our $VERSION = '0.01';

sub can_handle {
  return ('application/x-bzip2');
}

1;

__END__

=head1 NAME

Archive::Any::Plugin::Bzip2 - bzip2 support via Archive::Tar

=head1 SYNOPSIS

Do not use this module directly.  Instead, use Archive::Any.

=head1 DESCRIPTION

=head2 can_handle

Used internally to add C<x-bzip2> support to L<Archive::Any>.

=head1 SEE ALSO

L<Archive::Any>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
