package DBIO::Test::Schema::NoPrimaryKey;
# ABSTRACT: Test result class for a table with no primary key

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('noprimarykey');
__PACKAGE__->add_columns(
  'foo' => { data_type => 'integer' },
  'bar' => { data_type => 'integer' },
  'baz' => { data_type => 'integer' },
);

__PACKAGE__->add_unique_constraint(foo_bar => [ qw/foo bar/ ]);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::NoPrimaryKey - Test result class for a table with no primary key

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
