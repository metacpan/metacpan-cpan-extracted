package DBIO::Test::MooseSchema::Result::Artist;
# ABSTRACT: Moose-enabled test result class for the artist table

use DBIO::Moose;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 100, is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('DBIO::Test::MooseSchema::ResultSet::Artist');

__PACKAGE__->has_many(
  cds => 'DBIO::Test::MooseSchema::Result::CD', 'artist_id'
);

# Lazy Moose attribute — computed from column data on first access
has display_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

# Moose rw attribute with type constraint and lazy default
# (must be lazy — inflate_result bypasses new())
has score => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::MooseSchema::Result::Artist - Moose-enabled test result class for the artist table

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
