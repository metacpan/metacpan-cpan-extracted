package DBIO::Test::Schema::Money;
# ABSTRACT: Test result class for the money_test table (MONEY column)
use strict;
use warnings;
use base 'DBIO::Test::BaseResult';

__PACKAGE__->table('money_test');
__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  amount => {
    data_type => 'money',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('DBIO::Test::BaseResultSet');
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Money - Test result class for the money_test table (MONEY column)

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
