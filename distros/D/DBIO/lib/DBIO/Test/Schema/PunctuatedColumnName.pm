package DBIO::Test::Schema::PunctuatedColumnName;
# ABSTRACT: Test result class for columns with punctuated names

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('punctuated_column_name');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  q{foo ' bar} => {
    data_type => 'integer',
    is_nullable => 1,
    accessor => 'foo_bar',
  },
  q{bar/baz} => {
    data_type => 'integer',
    is_nullable => 1,
    accessor => 'bar_baz',
  },
  q{baz;quux} => {
    data_type => 'integer',
    is_nullable => 1,
    accessor => 'bar_quux',
  },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::PunctuatedColumnName - Test result class for columns with punctuated names

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
