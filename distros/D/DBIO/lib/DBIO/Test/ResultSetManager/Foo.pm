package DBIO::Test::ResultSetManager::Foo;
# ABSTRACT: Test result class for ResultSetManager component testing

use warnings;
use strict;

use base 'DBIO::Core';

__PACKAGE__->load_components(qw/ ResultSetManager /);
__PACKAGE__->table('foo');

sub bar : ResultSet { 'good' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::ResultSetManager::Foo - Test result class for ResultSetManager component testing

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
