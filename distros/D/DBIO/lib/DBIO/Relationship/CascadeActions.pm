package DBIO::Relationship::CascadeActions;
# ABSTRACT: Cascade delete and update actions across relationships

use strict;
use warnings;
use DBIO::Carp;
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIO::Relationship::CascadeActions' => 'DBIO::Relationship' }
  );


sub delete {
  my ($self, @rest) = @_;
  return $self->next::method(@rest) unless ref $self;
    # I'm just ignoring this for class deletes because hell, the db should
    # be handling this anyway. Assuming we have joins we probably actually
    # *could* do them, but I'd rather not.

  my $source = $self->result_source;
  my %rels = map { $_ => $source->relationship_info($_) } $source->relationships;
  my @cascade = grep { $rels{$_}{attrs}{cascade_delete} } keys %rels;

  if (@cascade) {
    my $guard = $source->schema->txn_scope_guard;

    my $ret = $self->next::method(@rest);

    foreach my $rel (@cascade) {
      if( my $rel_rs = eval{ $self->search_related($rel) } ) {
        $rel_rs->delete_all;
      } else {
        carp "Skipping cascade delete on relationship '$rel' - related resultsource '$rels{$rel}{class}' is not registered with this schema";
        next;
      }
    }

    $guard->commit;
    return $ret;
  }

  $self->next::method(@rest);
}


sub update {
  my ($self, @rest) = @_;
  return $self->next::method(@rest) unless ref $self;
    # Because update cascades on a class *really* don't make sense!

  my $source = $self->result_source;
  my %rels = map { $_ => $source->relationship_info($_) } $source->relationships;
  my @cascade = grep { $rels{$_}{attrs}{cascade_update} } keys %rels;

  if (@cascade) {
    my $guard = $source->schema->txn_scope_guard;

    my $ret = $self->next::method(@rest);

    foreach my $rel (@cascade) {
      next if (
        $rels{$rel}{attrs}{accessor}
          &&
        $rels{$rel}{attrs}{accessor} eq 'single'
          &&
        !exists($self->{_relationship_data}{$rel})
      );
      $_->update for grep defined, $self->$rel;
    }

    $guard->commit;
    return $ret;
  }

  $self->next::method(@rest);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::CascadeActions - Cascade delete and update actions across relationships

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 delete

=head2 update

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
