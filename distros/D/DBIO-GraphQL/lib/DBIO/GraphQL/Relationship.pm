package DBIO::GraphQL::Relationship;
# ABSTRACT: Resolve GraphQL relationship fields from a DBIO source
use strict;
use warnings;

use base 'Class::Accessor::Grouped';
use GraphQL::Type::List;

# KARR #1 (filed 2026-06-09, low priority): DBIO::GraphQL previously
# read two undocumented keys of $source->relationship_info($rel):
#
#   $info->{source}              - the target result class
#   $info->{attrs}{accessor}     - 'multi' for has_many, 'single' otherwise
#
# If either key was missing or absent, the relationship was silently
# dropped from the GraphQL type (`or next` in the build loop), with no
# error and no warning. A future core change to either of these keys
# would have failed invisibly.
#
# This module wraps the resolution path. The two keys are now treated
# as a documented-stable contract; a build-time error is raised when
# they are missing. on_error = 'warn' downgrades the error to a warning
# and returns undef so the caller can skip the relationship.

# schema is the connected DBIO::Schema; required at construction.
# on_error is 'die' (default) or 'warn' (downgrade + skip).
__PACKAGE__->mk_group_accessors(simple => qw(schema on_error));

sub new {
  my ($class, %args) = @_;
  die "DBIO::GraphQL::Relationship: 'schema' is required\n"
    unless exists $args{schema};
  my $self = bless {}, $class;
  $self->schema($args{schema});
  $self->on_error($args{on_error} // 'die');
  return $self;
}

# Build a GraphQL field hashref for the given relationship.
# Returns undef when on_error eq 'warn' and a required key is missing
# (caller should skip the field); dies otherwise.
sub build_field {
  my ($self, $source, $rel_name, $types_snapshot) = @_;
  my $rel_info = $source->relationship_info($rel_name);
  my $moniker  = $source->source_name;

  unless (defined $rel_info->{source}) {
    return $self->_fail(
      "relationship_info for '$rel_name' on source '$moniker' "
      . "lacks required key 'source' (target result class)"
    );
  }
  unless (ref($rel_info->{attrs}) eq 'HASH' && exists $rel_info->{attrs}{accessor}) {
    return $self->_fail(
      "relationship_info for '$rel_name' on source '$moniker' "
      . "lacks required key 'attrs.accessor' (cardinality hint)"
    );
  }

  my $target_moniker = $rel_info->{source};
  $target_moniker =~ s/^.*:://;
  my $target_type = $types_snapshot->{$target_moniker};
  unless ($target_type) {
    return $self->_fail(
      "target type '$target_moniker' (for relationship '$rel_name' on "
      . "source '$moniker') is not in the type snapshot"
    );
  }

  my $is_plural = ($rel_info->{attrs}{accessor} eq 'multi') ? 1 : 0;

  return {
    type => $is_plural
              ? GraphQL::Type::List->new(of => $target_type)
              : $target_type,
    resolve => sub {
      my ($row, $args, $ctx) = @_;
      if (ref($row) eq 'HASH') {
        $row = $self->_pk_find($ctx, $moniker, $row) or return;
      }
      if ($is_plural) {
        return [
          map { { $_->get_columns } }
          $row->$rel_name->all
        ];
      }
      else {
        my $related = $row->$rel_name;
        return $related ? { $related->get_columns } : undef;
      }
    },
  };
}

sub _fail {
  my ($self, $msg) = @_;
  if ($self->on_error eq 'warn') {
    warn "DBIO::GraphQL::Relationship: $msg (skipping)\n";
    return undef;
  }
  die "DBIO::GraphQL::Relationship: $msg\n";
}

# Re-look-up a row from a HASH by primary key. Used when a relationship
# resolver receives a hashref (the connection-list return shape) rather
# than a live DBIO row object.
sub _pk_find {
  my ($self, $ctx, $moniker, $row_hash) = @_;
  my $source  = $ctx->source($moniker);
  my @pk_cols = $source->primary_columns;
  my @pk_vals = map { $row_hash->{$_} } @pk_cols;
  return if grep { !defined } @pk_vals;
  return $ctx->resultset($moniker)->find(
    { map { $pk_cols[$_] => $pk_vals[$_] } 0 .. $#pk_cols }
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Relationship - Resolve GraphQL relationship fields from a DBIO source

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
