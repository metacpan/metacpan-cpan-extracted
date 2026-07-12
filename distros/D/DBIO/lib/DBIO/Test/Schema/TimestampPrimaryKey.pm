package DBIO::Test::Schema::TimestampPrimaryKey;
# ABSTRACT: Test result class for timestamp primary key handling

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('timestamp_primary_key_test');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'timestamp',
    default_value => \'current_timestamp',
    retrieve_on_insert => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::TimestampPrimaryKey - Test result class for timestamp primary key handling

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
