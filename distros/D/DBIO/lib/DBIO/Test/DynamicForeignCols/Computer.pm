package DBIO::Test::DynamicForeignCols::Computer;
# ABSTRACT: Test result class for dynamic foreign column resolution

use warnings;
use strict;

use base 'DBIO::Core';

__PACKAGE__->table('Computers');

__PACKAGE__->add_columns('id');

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(computer_test_links => 'DBIO::Test::DynamicForeignCols::TestComputer', 'computer_id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::DynamicForeignCols::Computer - Test result class for dynamic foreign column resolution

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
