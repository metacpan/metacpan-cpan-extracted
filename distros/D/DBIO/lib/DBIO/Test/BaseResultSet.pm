package DBIO::Test::BaseResultSet;
# ABSTRACT: Base class for DBIO test ResultSet classes

use strict;
use warnings;

use base 'DBIO::ResultSet';


sub all_hri {
  return [ shift->search({}, { result_class => 'DBIO::ResultClass::HashRefInflator' })->all ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::BaseResultSet - Base class for DBIO test ResultSet classes

=head1 VERSION

version 0.900001

=head1 METHODS

=head2 all_hri

  my $rows = $rs->all_hri;

Convenience method that returns all rows as an arrayref of hashrefs
via L<DBIO::ResultClass::HashRefInflator>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
