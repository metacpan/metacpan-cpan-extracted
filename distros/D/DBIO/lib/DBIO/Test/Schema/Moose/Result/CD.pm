package DBIO::Test::Schema::Moose::Result::CD;
# ABSTRACT: Moose-enabled test result class for the cd table

use DBIO::Moose;

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  id        => { data_type => 'integer', is_auto_increment => 1 },
  artist_id => { data_type => 'integer', is_nullable => 0 },
  title     => { data_type => 'varchar', size => 100, is_nullable => 0 },
  year      => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
  artist => 'DBIO::Test::Schema::Moose::Result::Artist', 'artist_id'
);

# Lazy Moose attribute — formatted title including year
has full_title => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_full_title',
);
sub _build_full_title {
  my $self = shift;
  my $year = $self->year // '?';
  sprintf '%s (%s)', $self->title, $year;
}

# Moose rw attribute with type constraint and lazy default
has rating => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Moose::Result::CD - Moose-enabled test result class for the cd table

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
