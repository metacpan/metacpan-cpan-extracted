package DBIO::Shortcut::ch;
# ABSTRACT: `use DBIO -ch` shortcut for the ClickHouse driver

use strict;
use warnings;

our $VERSION = '0.900004';

sub apply { DBIO->apply_driver($_[1], 'ClickHouse') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Shortcut::ch - `use DBIO -ch` shortcut for the ClickHouse driver

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
