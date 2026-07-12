package DBIO::Test::Schema::SelfRef;
# ABSTRACT: Test result class for the self_ref table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('self_ref');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( aliases => 'DBIO::Test::Schema::SelfRefAlias' => 'self_ref' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::SelfRef - Test result class for the self_ref table

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
