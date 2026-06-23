package DBIO::Generate::Relationships;
# ABSTRACT: Relationship inference for DBIO::Generate

use strict;
use warnings;
use base qw/Class::Accessor::Grouped/;
use mro 'c3';
use Carp::Clan qw/^DBIO/;
use Scalar::Util 'weaken';
use List::Util qw/all any first/;
use Try::Tiny;
use Lingua::EN::Inflect::Phrase ();
use Lingua::EN::Tagger ();
use String::ToIdentifier::EN ();
use String::ToIdentifier::EN::Unicode ();
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  inflect_plural
  inflect_singular
  rel_name_map
  rel_collision_map
  allow_extra_m2m_cols
  quiet
  _relnames_seen
/);

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  $self->allow_extra_m2m_cols($args{allow_extra_m2m_cols} // 0);
  $self->quiet($args{quiet} // 0);
  $self->rel_name_map($args{rel_name_map});
  $self->rel_collision_map($args{rel_collision_map} // {});
  $self->inflect_plural($args{inflect_plural});
  $self->inflect_singular($args{inflect_singular});
  return $self;
}


sub generate_code {
  my ($self, $tables, $class_for, $pk_for) = @_;

  $self->_relnames_seen({});

  my @tables = @$tables;
  my %all_code;

  while (my ($local_moniker, $rels, $uniqs) = @{ shift @tables || [] }) {
    my $local_class = $class_for->{$local_moniker} or next;

    my %counters;
    for my $rel (@$rels) {
      next unless $rel->{remote_moniker};
      $counters{ $rel->{remote_moniker} }++;
    }

    for my $rel (@$rels) {
      my $remote_moniker = $rel->{remote_moniker} or next;
      my $remote_class   = $class_for->{$remote_moniker} or next;

      my $remote_cols = $rel->{remote_columns};
      $remote_cols    = $pk_for->{$remote_moniker} // []
        unless $remote_cols && @$remote_cols;

      my $local_cols = $rel->{local_columns};

      if (@$local_cols != @$remote_cols) {
        croak "Column count mismatch: $local_moniker (@$local_cols) "
            . "$remote_moniker (@$remote_cols)";
      }

      my %cond;
      @cond{@$remote_cols} = @$local_cols;

      my ($local_relname, $remote_relname, $remote_method) =
        $self->_relnames_and_method(
          $local_moniker, $remote_moniker, \%cond, $uniqs, \%counters
        );

      my $local_method = 'belongs_to';

      ($local_relname)  = $self->_apply_rel_name_map($local_relname,  $local_method,  $local_moniker,  $local_cols,  $remote_moniker, $remote_cols);
      ($remote_relname) = $self->_apply_rel_name_map($remote_relname, $remote_method, $remote_moniker, $remote_cols, $local_moniker,  $local_cols);

      $local_relname  = $self->_resolve_collision($local_moniker,  $local_relname);
      $remote_relname = $self->_resolve_collision($remote_moniker, $remote_relname);

      push @{ $all_code{$local_moniker} }, {
        method => $local_method,
        args   => [
          $local_relname,
          $remote_class,
          \%cond,
          $rel->{attrs} // {},
        ],
        extra => {
          local_moniker  => $local_moniker,
          remote_moniker => $remote_moniker,
        },
      };

      my %rev_cond = reverse %cond;
      for (keys %rev_cond) {
        $rev_cond{"foreign.$_"} = "self." . $rev_cond{$_};
        delete $rev_cond{$_};
      }

      push @{ $all_code{$remote_moniker} }, {
        method => $remote_method,
        args   => [
          $remote_relname,
          $local_class,
          \%rev_cond,
          {},
        ],
        extra => {
          local_moniker  => $remote_moniker,
          remote_moniker => $local_moniker,
        },
      };
    }
  }

  $self->_generate_m2ms(\%all_code, $class_for)
    unless $self->allow_extra_m2m_cols;

  return \%all_code;
}

sub _relnames_and_method {
  my ($self, $local_moniker, $remote_moniker, $cond, $uniqs, $counters) = @_;

  my $local_relname  = $self->_local_relname($local_moniker, $cond, $remote_moniker);
  my $remote_relname = $self->_inflect_plural(lc $local_moniker);

  my @local_col_names = values %$cond;
  my $is_unique = any {
    my ($name, $cols) = @$_;
    @$cols == @local_col_names
    && all { my $c = $_; any { $_ eq $c } @local_col_names } @$cols
  } @$uniqs;

  my $remote_method = $is_unique ? 'might_have' : 'has_many';

  if ($counters->{$remote_moniker} > 1) {
    my $col_part = lc join '_', @local_col_names;
    $col_part =~ s/_id$//;
    $local_relname  = $col_part . '_' . lc $remote_moniker;
    $remote_relname = $self->_inflect_plural(lc $local_moniker) . '_via_' . $col_part;
  }

  return ($local_relname, $remote_relname, $remote_method);
}

sub _local_relname {
  my ($self, $local_moniker, $cond, $remote_moniker) = @_;

  my @local_cols = values %$cond;
  my $col        = $local_cols[0];
  (my $stripped  = $col) =~ s/_id$//i;
  return lc($stripped eq lc($local_moniker) ? $remote_moniker : $stripped);
}

sub _generate_m2ms {
  my ($self, $all_code, $class_for) = @_;

  for my $link_moniker (sort keys %$all_code) {
    my @bt = grep { $_->{method} eq 'belongs_to' } @{ $all_code->{$link_moniker} };
    next unless @bt == 2;

    my ($a, $b) = @bt;
    my $a_moniker = $a->{extra}{remote_moniker};
    my $b_moniker = $b->{extra}{remote_moniker};

    next unless $class_for->{$a_moniker} && $class_for->{$b_moniker};

    my $m2m_relname     = $self->_inflect_plural(lc $b_moniker);
    my $bridge_relname  = $a->{args}[0];

    push @{ $all_code->{$a_moniker} }, {
      method => 'many_to_many',
      args   => [
        $m2m_relname,
        $bridge_relname,
        $b->{args}[0],
      ],
      extra => {
        local_moniker  => $a_moniker,
        remote_moniker => $b_moniker,
      },
    };
  }
}

sub _inflect_plural {
  my ($self, $name) = @_;
  if (my $map = $self->inflect_plural) {
    return $map->{$name} if exists $map->{$name};
  }
  return Lingua::EN::Inflect::Phrase::to_PL($name);
}

sub _inflect_singular {
  my ($self, $name) = @_;
  if (my $map = $self->inflect_singular) {
    return $map->{$name} if exists $map->{$name};
  }
  return Lingua::EN::Inflect::Phrase::to_S($name);
}

sub _apply_rel_name_map {
  my ($self, $relname, $method, $local_moniker, $local_cols, $remote_moniker, $remote_cols) = @_;
  my $map = $self->rel_name_map or return ($relname);
  if (ref $map eq 'HASH') {
    return (exists $map->{$relname} ? $map->{$relname} : $relname);
  }
  elsif (ref $map eq 'CODE') {
    my $mapped = $map->({
      name           => $relname,
      type           => $method,
      local_moniker  => $local_moniker,
      local_columns  => $local_cols,
      remote_moniker => $remote_moniker,
      remote_columns => $remote_cols,
    });
    return (defined $mapped ? $mapped : $relname);
  }
  return ($relname);
}

sub _resolve_collision {
  my ($self, $moniker, $relname) = @_;
  my $seen = $self->_relnames_seen;
  my $key  = "$moniker.$relname";
  if ($seen->{$key}++) {
    return $relname . '_' . $seen->{$key};
  }
  return $relname;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate::Relationships - Relationship inference for DBIO::Generate

=head1 VERSION

version 0.900000

=head1 METHODS

=head2 generate_code

    my $code = $r->generate_code($tables, $class_for, $pk_for);

Takes an arrayref of [ $moniker, \@fk_info, \@uniq_info ].
Each FK info hashref must have C<remote_moniker> (not remote_table).
C<class_for> maps moniker → class name string.
C<pk_for> maps moniker → PK column arrayref.

Returns hashref { $moniker => [ { method, args, extra }, ... ] }.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
