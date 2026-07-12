package DBIO::Test::Schema::ForceForeign;
# ABSTRACT: Test result class for the forceforeign table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('forceforeign');
__PACKAGE__->add_columns(
  'artist' => { data_type => 'integer' },
  'cd' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/artist/);

# Normally this would not appear as a FK constraint
# since it uses the PK
__PACKAGE__->might_have('artist_1', 'DBIO::Test::Schema::Artist', 'artistid',
  { is_foreign_key_constraint => 1 },
);

# Normally this would appear as a FK constraint
__PACKAGE__->might_have('cd_1', 'DBIO::Test::Schema::CD',
  { 'foreign.cdid' => 'self.cd' },
  { is_foreign_key_constraint => 0 },
);

# Normally this would appear as a FK constraint
__PACKAGE__->belongs_to('cd_3', 'DBIO::Test::Schema::CD',
  { 'foreign.cdid' => 'self.cd' },
  { is_foreign_key_constraint => 0 },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::ForceForeign - Test result class for the forceforeign table

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
