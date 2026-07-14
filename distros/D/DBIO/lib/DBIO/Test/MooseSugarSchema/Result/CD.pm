package DBIO::Test::MooseSugarSchema::Result::CD;
# ABSTRACT: Moose + Cake test result class for the cd table (no custom ResultSet)

use DBIO::Moose;
use DBIO::Cake;

table 'cd';

col id        => integer auto_inc;
col artist_id => integer;
col title     => varchar(100);
col year      => integer null;

primary_key 'id';

__PACKAGE__->belongs_to( artist => 'DBIO::Test::MooseSugarSchema::Result::Artist', 'artist_id' );

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

has rating => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::MooseSugarSchema::Result::CD - Moose + Cake test result class for the cd table (no custom ResultSet)

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
