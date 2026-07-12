package DBIO::Shortcut::fb;
# ABSTRACT: `use DBIO -fb` shortcut for the Firebird driver

use strict;
use warnings;

sub apply { DBIO->apply_driver($_[1], 'Firebird') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Shortcut::fb - `use DBIO -fb` shortcut for the Firebird driver

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
