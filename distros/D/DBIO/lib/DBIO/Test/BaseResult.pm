package DBIO::Test::BaseResult;
# ABSTRACT: Base class for DBIO test Result classes

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->table('bogus');
__PACKAGE__->resultset_class('DBIO::Test::BaseResultSet');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::BaseResult - Base class for DBIO test Result classes

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
