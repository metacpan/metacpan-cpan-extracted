package DBIO::Test::Schema::MooCake::ResultSet::Artist;
# ABSTRACT: Custom Moo-based ResultSet for the MooCake artist source

use Moo;
extends 'DBIO::ResultSet';

sub FOREIGNBUILDARGS { my ($class, @args) = @_; return @args }

has default_limit => ( is => 'rw', lazy => 1, default => sub { 100 } );

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::MooCake::ResultSet::Artist - Custom Moo-based ResultSet for the MooCake artist source

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
