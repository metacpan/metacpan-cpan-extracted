package DBIO::Shortcut::du;
# ABSTRACT: `use DBIO -du` shortcut for the DuckDB driver

use strict;
use warnings;

sub apply { DBIO->apply_driver($_[1], 'DuckDB') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Shortcut::du - `use DBIO -du` shortcut for the DuckDB driver

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
