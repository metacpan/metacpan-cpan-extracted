package DBIO::Test::Schema::SelfRefAlias;
# ABSTRACT: Test result class for the self_ref_alias table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('self_ref_alias');
__PACKAGE__->add_columns(
  'self_ref' => {
    data_type => 'integer',
  },
  'alias' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key(qw/self_ref alias/);

__PACKAGE__->belongs_to( self_ref => 'DBIO::Test::Schema::SelfRef' );
__PACKAGE__->belongs_to( alias => 'DBIO::Test::Schema::SelfRef' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::SelfRefAlias - Test result class for the self_ref_alias table

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
