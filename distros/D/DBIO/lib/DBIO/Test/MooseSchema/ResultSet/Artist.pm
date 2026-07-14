package DBIO::Test::MooseSchema::ResultSet::Artist;
# ABSTRACT: Custom Moose-based ResultSet for the artist source

use Moose;
use MooseX::NonMoose;
extends 'DBIO::ResultSet';

# MooseX::NonMoose's default FOREIGNBUILDARGS is a pass-through — correct
# for ResultSet: no key filtering needed unlike DBIO::Row::new.

# ResultSet-level Moose attribute
has default_limit => ( is => 'rw', isa => 'Int', lazy => 1, default => 100 );

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::MooseSchema::ResultSet::Artist - Custom Moose-based ResultSet for the artist source

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
