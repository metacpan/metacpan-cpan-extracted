package DBIO::Test::Schema::Encoded;
# ABSTRACT: Test result class for the encoded table

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('encoded');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'encoded' => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many (keyholders => 'DBIO::Test::Schema::Employee', 'encoded');

sub set_column {
  my ($self, $col, $value) = @_;
  if( $col eq 'encoded' ){
    $value = reverse split '', $value;
  }
  $self->next::method($col, $value);
}

sub new {
  my($self, $attr, @rest) = @_;
  $attr->{encoded} = reverse split '', $attr->{encoded}
    if defined $attr->{encoded};
  return $self->next::method($attr, @rest);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Encoded - Test result class for the encoded table

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
