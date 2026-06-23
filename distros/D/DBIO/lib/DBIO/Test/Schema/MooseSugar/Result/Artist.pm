package DBIO::Test::Schema::MooseSugar::Result::Artist;
# ABSTRACT: Moose + Cake test result class for the artist table

use DBIO::Moose;
use DBIO::Cake;

table 'artist';

col id   => integer auto_inc;
col name => varchar(100);

primary_key 'id';

__PACKAGE__->has_many( cds => 'DBIO::Test::Schema::MooseSugar::Result::CD', 'artist_id' );

__PACKAGE__->resultset_class('DBIO::Test::Schema::MooseSugar::ResultSet::Artist');

has display_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::MooseSugar::Result::Artist - Moose + Cake test result class for the artist table

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
