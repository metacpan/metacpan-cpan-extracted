package DBIOx;
# ABSTRACT: Bring your own database magic!

use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIOx - Bring your own database magic!

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The B<DBIOx> namespace is the conventional home for third-party extensions to
L<DBIO>. If you are building a module that extends or integrates with DBIO but
does not belong in the core distribution, publish it under C<DBIOx::>.

For custom storage drivers, publish under C<DBIOx::Storage::*>. For custom
components, publish under C<DBIOx::Component::*>. For ResultSet extensions,
publish under C<DBIOx::ResultSet::*>.

DBIO resolves configured component names against both C<DBIO::> and C<DBIOx::>
namespaces via L<DBIO::Componentised>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
