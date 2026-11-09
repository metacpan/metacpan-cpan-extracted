package DBIO::PostgreSQL::Diff::Type;
# ABSTRACT: Diff operations for PostgreSQL types (enums, composites, ranges)

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::CaseOnly ();
use DBIO::PostgreSQL::Diff::Dependents ();
use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified quote_literal);

__PACKAGE__->mk_diff_accessors(qw(type_key type_info added_values value_positions));







# The types of one section as DBIO::PostgreSQL::Diff::CaseOnly compares them:
# a name within its schema, among the types of its kind.
sub _named {
  my ($types) = @_;
  my @entries;
  for my $key (keys %$types) {
    my $info = $types->{$key};
    my ($schema, $name) = DBIO::PostgreSQL::Introspect->key_names($key, type_name => $info);
    next unless defined $name;
    push @entries, {
      in => [ $schema, $info->{type_kind} // '' ], name => $name, schema => $schema,
    };
  }
  return \@entries;
}

sub _refuse_case_only {
  my ($source, $target) = @_;
  DBIO::PostgreSQL::Diff::CaseOnly->refuse(
    "A column does not go from the one type to the other without a cast, and DROP\n"
      . 'TYPE of the old one meets every column that is still of it.',
    map {
      my ($old, $new) = @$_;
      my $schema = $old->{schema};
      {
        kind     => 'type',
        database => "$schema.$old->{name}",
        target   => "$schema.$new->{name}",
        rename   => sprintf('ALTER TYPE %s RENAME TO %s;',
          quote_qualified($schema, $old->{name}), quote_ident($new->{name})),
      }
    } DBIO::PostgreSQL::Diff::CaseOnly->pairs(_named($source), _named($target)),
  );
}

sub _kind_name {
  my ($info) = @_;
  my $kind = $info->{type_kind} // '';
  return $kind eq '' ? 'type' : "$kind type";
}

# An attribute as the diff compares and shows it: name, type, and the
# collation where it has one of its own.
sub _attribute_text {
  my ($attr) = @_;
  return "$attr->{name} $attr->{type}"
    . ( ($attr->{collation} // '') ne '' ? " COLLATE $attr->{collation}" : '' );
}

sub _attribute_lines {
  my ($sign, $list) = @_;
  return map { "  $sign " . _attribute_text($_) } @$list;
}

# What a range type sets besides its subtype, as the keys of its entry and
# the words the refusal uses for them.
my @RANGE_EXTRAS = (
  [ collation       => 'collation' ],
  [ subtype_opclass => 'subtype_opclass' ],
  [ canonical       => 'canonical' ],
  [ subtype_diff    => 'subtype_diff' ],
);

# What differs between the same type in the database ($src) and in the target
# ($tgt), as the lines of one refusal; none where the diff has a statement
# for the change (new values at the end of an enum) or there is no change.
sub _type_change {
  my ($key, $src, $tgt) = @_;
  my $src_kind = $src->{type_kind} // '';
  my $tgt_kind = $tgt->{type_kind} // '';
  my $what = _kind_name($tgt);

  # A type the target declares without values or attributes, which the
  # database has with some: the target means an empty type, not "no type",
  # and the diff has no statement for it that keeps the data (a drop would
  # take every column of the type with its rows).
  if ($src_kind eq $tgt_kind && ($tgt_kind eq 'enum' || $tgt_kind eq 'composite')) {
    my $field = $tgt_kind eq 'enum' ? 'values' : 'attributes';
    if (!@{ $tgt->{$field} // [] } && @{ $src->{$field} // [] }) {
      return (
        "$what $key is declared empty in the target but has $field in the database",
        'The diff does not empty a type: that would be a DROP TYPE of a type the columns',
        'are of, and their data with them, and PostgreSQL has no ALTER TYPE that',
        ($tgt_kind eq 'enum' ? 'removes values.' : 'removes all attributes at once.'),
        'Declare the type as the database has it, or move what uses it to another type',
        'and drop this one by hand.',
      );
    }
  }

  if ($src_kind ne $tgt_kind) {
    return (
      "type $key is " . _article($tgt) . " in the target and " . _article($src) . ' in the database',
      'PostgreSQL has no ALTER TYPE that makes a type another kind. Move what uses it',
      'to a new type, drop this one and create it again as the target has it.',
    );
  }

  if ($tgt_kind eq 'enum') {
    my @src = @{ $src->{values} // [] };
    my @tgt = @{ $tgt->{values} // [] };
    my %in_tgt = map { $_ => 1 } @tgt;
    my %in_src = map { $_ => 1 } @src;
    my @lost = grep { !$in_tgt{$_} } @src;
    if (@lost) {
      return (
        "$what $key has lost the value(s) " . join(', ', map { quote_literal($_) } @lost)
          . ' in the target',
        'PostgreSQL has no ALTER TYPE ... DROP VALUE. Create a new type with the values',
        'wanted, move the columns with ALTER TABLE ... ALTER COLUMN ... TYPE ... USING',
        'col::text::new_type, drop this type and rename the new one.',
      );
    }
    my @src_common = @src;
    my @tgt_common = grep { $in_src{$_} } @tgt;
    if (join("\0", @src_common) ne join("\0", @tgt_common)) {
      return (
        "$what $key has its values in another order in the target",
        'PostgreSQL places a new value (ALTER TYPE ... ADD VALUE ... BEFORE|AFTER)',
        'and does not reorder the ones a type has. Create a new type with the order wanted and',
        'move the columns to it, as for a lost value.',
      );
    }
    return ();
  }

  if ($tgt_kind eq 'composite') {
    my @s = map { _attribute_text($_) } @{ $src->{attributes} // [] };
    my @t = map { _attribute_text($_) } @{ $tgt->{attributes} // [] };
    return () if join("\n", @s) eq join("\n", @t);
    my %s = map { $_ => 1 } @s;
    my %t = map { $_ => 1 } @t;
    return (
      "$what $key has other attributes in the target than in the database",
      _attribute_lines('-', [ grep { !$t{_attribute_text($_)} } @{ $src->{attributes} // [] } ]),
      _attribute_lines('+', [ grep { !$s{_attribute_text($_)} } @{ $tgt->{attributes} // [] } ]),
      'The diff writes no ALTER TYPE ... ADD ATTRIBUTE, DROP ATTRIBUTE or ALTER',
      'ATTRIBUTE ... TYPE (which also sets the collation). Change the type by hand',
      '(the attributes keep their order only by being added at the end).',
    );
  }

  if ($tgt_kind eq 'range') {
    my ($s, $t) = map { $_->{subtype} // '' } $src, $tgt;
    if ($s ne $t) {
      return (
        "$what $key has another subtype in the target than in the database",
        "  database: $s",
        "  target:   $t",
        'PostgreSQL has no ALTER TYPE for the subtype of a range. Move what uses the',
        'type to a new one, drop this one and create it again.',
      );
    }
    for my $extra (@RANGE_EXTRAS) {
      my ($field, $word) = @$extra;
      my ($s_val, $t_val) = map { $_->{$field} // '' } $src, $tgt;
      next if $s_val eq $t_val;
      return (
        "$what $key has another $word in the target than in the database",
        '  database: ' . ($s_val eq '' ? '(none)' : $s_val),
        '  target:   ' . ($t_val eq '' ? '(none)' : $t_val),
        'PostgreSQL has no ALTER TYPE for what a range type is built with. Move what',
        'uses the type to a new one, drop this one and create it again.',
      );
    }
  }
  return ();
}

sub _article {
  my ($info) = @_;
  my $name = _kind_name($info);
  return ($name =~ /\A[aeiou]/ ? 'an ' : 'a ') . $name;
}

# The types a type is built on: the types of the attributes of a composite
# type, the subtype of a range.
sub _built_on {
  my ($info) = @_;
  my $kind = $info->{type_kind} // '';
  my @used = $kind eq 'composite' ? map { $_->{type} } @{ $info->{attributes} // [] }
           : $kind eq 'range'     ? ($info->{subtype})
           :                        ();
  return grep { defined } @used;
}

# The order types are dropped in: a type goes ahead of the types it is built
# on. A type is told by its text as format_type gives it -- with its schema
# where the search_path does not find it, an array with [] behind it, quoted
# where the name needs it -- so both sides are compared unquoted, the
# qualified key first and the bare name where the text has no schema.
sub _drop_order {
  my ($source, @keys) = @_;
  my %left = map { $_ => 1 } @keys;
  my %of;
  my %by_key = map { my $k = $_; (my $u = $k) =~ tr/"//d; ($u => $k) } @keys;
  for my $key (@keys) {
    for my $used (_built_on($source->{$key})) {
      (my $name = $used) =~ s/(?:\[\d*\])+\z//;
      $name =~ tr/"//d;
      my $base = $by_key{$name}
        // (grep { ($source->{$_}{type_name} // '') eq $name } @keys)[0];
      $of{$key}{$base} = 1 if defined $base && $base ne $key;
    }
  }
  my @order;
  while (%left) {
    # the first by key that no type left is built on
    my ($next) = sort grep {
      my $candidate = $_;
      !grep { $of{$_}{$candidate} } keys %left
    } keys %left;
    ($next) = sort keys %left unless defined $next;
    push @order, $next;
    delete $left{$next};
  }
  return @order;
}

sub diff {
  my ($class, $source, $target, $source_dependents) = @_;
  my @ops;

  _refuse_case_only($source, $target);

  # A type both sides have that differs in more than new enum values at the
  # end has no statement here: refused, all of them in one message.
  my @refused;
  for my $key (sort keys %$target) {
    next unless exists $source->{$key};
    my @lines = _type_change($key, $source->{$key}, $target->{$key});
    push @refused, \@lines if @lines;
  }
  if (@refused) {
    die join "\n",
      (map { ('refusing to diff: ' . join("\n", @$_), '') } @refused),
      'No statement was generated.',
      '';
  }

  for my $key (sort keys %$target) {
    if (!exists $source->{$key}) {
      push @ops, $class->new(
        action    => 'create',
        type_key  => $key,
        type_info => $target->{$key},
      );
      next;
    }

    # Existing type — check for enum value additions
    my $src = $source->{$key};
    my $tgt = $target->{$key};

    if ($tgt->{type_kind} eq 'enum' && $src->{type_kind} eq 'enum') {
      my %src_vals = map { $_ => 1 } @{ $src->{values} };
      my @new_vals = grep { !$src_vals{$_} } @{ $tgt->{values} };
      if (@new_vals) {
        # Each new value is placed relative to a value that exists when its
        # statement runs: after the value before it in the target (an old one
        # or a new one written ahead of it), or, when it comes first, before
        # the first value the type has. A value with no old value behind it
        # needs no position.
        my (@positions, @after_old);
        my $seen_old_after = 0;
        for my $i (reverse 0 .. $#{ $tgt->{values} }) {
          $after_old[$i] = $seen_old_after;
          $seen_old_after = 1 if $src_vals{ $tgt->{values}[$i] };
        }
        my $prev;
        for my $i (0 .. $#{ $tgt->{values} }) {
          my $v = $tgt->{values}[$i];
          if (!$src_vals{$v} && $after_old[$i]) {
            if (defined $prev) {
              push @positions, { value => $v, after => $prev };
            }
            else {
              my ($first_old) = grep { $src_vals{$_} } @{ $tgt->{values} };
              push @positions, { value => $v, before => $first_old };
            }
          }
          elsif (!$src_vals{$v}) {
            push @positions, { value => $v };
          }
          $prev = $v;
        }
        push @ops, $class->new(
          action          => 'add_value',
          type_key        => $key,
          type_info       => $tgt,
          added_values    => \@new_vals,
          value_positions => \@positions,
        );
      }
    }
  }

  my @dropped = grep { !exists $target->{$_} } sort keys %$source;

  # What stands on a type outside the model is named, not left to the server.
  DBIO::PostgreSQL::Diff::Dependents->refuse(map { {
    object     => _kind_name($source->{$_}) . " $_",
    dependents => ($source_dependents // {})->{types}{$_},
  } } @dropped);

  for my $key (_drop_order($source, @dropped)) {
    push @ops, $class->new(
      action    => 'drop',
      type_key  => $key,
      type_info => $source->{$key},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  my $info = $self->type_info;
  my $type = quote_qualified(
    DBIO::PostgreSQL::Introspect->key_names($self->type_key, type_name => $info));
  my $object = 'type ' . ($self->type_key // '');

  if ($self->action eq 'create') {
    my $kind = $info->{type_kind} // '';
    if ($kind eq 'enum') {
      my $values = join ', ', map { quote_literal($_) } @{ $info->{values} };
      return sprintf "CREATE TYPE %s AS ENUM (%s);", $type, $values;
    }
    elsif ($kind eq 'composite') {
      my $attrs = join ",\n  ", map {
        quote_ident($_->{name}) . " $_->{type}"
          . ( ($_->{collation} // '') ne '' ? " COLLATE $_->{collation}" : '' )
      } @{ $info->{attributes} };
      return sprintf "CREATE TYPE %s AS (\n  %s\n);", $type, $attrs;
    }
    elsif ($kind eq 'range') {
      DBIO::PostgreSQL::Diff::NoStatement->throw(
        $self, $object, 'its type_info has no subtype, and a range type is created over one',
      ) unless ($info->{subtype} // '') =~ /\S/;
      my %option = (
        SUBTYPE         => $info->{subtype},
        SUBTYPE_OPCLASS => $info->{subtype_opclass},
        COLLATION       => $info->{collation},
        CANONICAL       => $info->{canonical},
        SUBTYPE_DIFF    => $info->{subtype_diff},
      );
      return sprintf "CREATE TYPE %s AS RANGE (%s);", $type, join ', ',
        map { "$_ = $option{$_}" }
        grep { ($option{$_} // '') ne '' } qw( SUBTYPE SUBTYPE_OPCLASS COLLATION CANONICAL SUBTYPE_DIFF );
    }
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object,
      "its type_info is of kind '$kind', and the diff creates an enum, a composite and a range type",
    );
  }
  elsif ($self->action eq 'drop') {
    return sprintf "DROP TYPE %s;", $type;
  }
  elsif ($self->action eq 'add_value') {
    my @values = @{ $self->added_values // [] };
    DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object, 'it has no added_values')
      unless @values;
    my %where = map { $_->{value} => $_ } @{ $self->value_positions // [] };
    return join "\n", map {
      my $pos = $where{$_} // {};
      sprintf "ALTER TYPE %s ADD VALUE %s%s;", $type, quote_literal($_),
        exists $pos->{after}  ? ' AFTER ' . quote_literal($pos->{after})
      : exists $pos->{before} ? ' BEFORE ' . quote_literal($pos->{before})
      : '';
    } @values;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  if ($self->action eq 'add_value') {
    my $count = scalar @{ $self->added_values };
    my $vals = join ', ', @{ $self->added_values };
    return sprintf '  ~type: %s +%d value(s) (%s)', $self->type_key, $count, $vals;
  }
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %stype: %s (%s)', $prefix, $self->type_key, $self->type_info->{type_kind};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Type - Diff operations for PostgreSQL types (enums, composites, ranges)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a type-level diff operation: C<CREATE TYPE>, C<DROP TYPE>,
or C<ALTER TYPE ... ADD VALUE> (for enum value additions). Handles enum,
composite, and range types. Note that enum value removal is not supported by
PostgreSQL -- only addition is possible without recreating the type.

=head1 ATTRIBUTES

=head2 type_key

The C<schema.type_name> key.

=head2 type_info

Type metadata hashref from introspection (C<type_kind>, C<values>,
C<attributes>, or C<subtype> depending on kind).

=head2 added_values

For an C<add_value> operation: arrayref of the enum values the target has and
the source does not, in the order the target has them. L</as_sql> writes one
C<ALTER TYPE ... ADD VALUE> for each. Not set for C<create> and C<drop>.

=head2 value_positions

For an C<add_value> operation: arrayref of C<< { value => $v, after => $w } >>,
C<< { value => $v, before => $w } >> or C<< { value => $v } >>, one for each of
L</added_values>, which L</as_sql> writes as C<ADD VALUE 'v' AFTER 'w'>,
C<BEFORE 'w'> or without a position. Without an entry (an operation built by
hand) a value is added with no position.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Type->diff(
      $source, $target, $source_outside_dependents);

Compares two type hashrefs. Produces C<create> operations for new types,
C<drop> for removed types, and C<add_value> for enum types that have gained
new values.

A type to create whose name differs only in upper and lower case from one to
drop, of the same kind and in the same schema -- C<Role_Type> in the target,
C<role_type> in the database -- is B<refused>, with C<refusing to diff: ...>
and no statement (L<DBIO::PostgreSQL::Diff::CaseOnly>). The two are most
likely one type. Taken for two, a column of the one is altered to the other
ahead of the drop, which PostgreSQL does not do without a cast, and the drop
would meet every column that is still of the old one. The message
names both, for every such type at once, and the way out: C<ALTER TYPE
auth.role_type RENAME TO "Role_Type">.

A type both sides have that differs in more than enum values added to
the ones the database has is B<refused> the same way, naming every such type,
what differs and the way out, and no statement is written:

=over 4

=item * a type that is of another kind in the target (an enum where the
database has a composite type, ...)

=item * an enum or a composite type the target declares B<empty> (no values,
no attributes) where the database has some. The model carries an empty type as
an entry with an empty list, which tells it from a type the target does not
declare at all (that one is a plain C<DROP TYPE>). Written as a
drop it would take every column of the type with its rows

=item * an enum that has lost a value (PostgreSQL has no C<DROP VALUE>), or
has its values in another order. A value added between the ones the database
has is not refused: it is written with its position, and an upgrade does not
reorder the ones the database has

=item * a composite type with other attributes (added, dropped, renamed, of
another type or size, or with another collation of its own): C<ALTER TYPE ...
ADD ATTRIBUTE> and its relatives exist, but the diff does not write them

=item * a range type with another subtype, another collation, another
operator class (C<subtype_opclass>, where it is not the subtype's default) or
another C<canonical> or C<subtype_diff> function. The model carries these
keys only where a range sets them (L<DBIO::PostgreSQL::Introspect::Types>),
and a model without them is read as a range that sets none; before they were
in the model such a difference gave no operation and no message

=back

A type that is created is created with all of these
(C<CREATE TYPE ... AS RANGE (SUBTYPE = ..., SUBTYPE_OPCLASS = ..., COLLATION =
..., CANONICAL = ..., SUBTYPE_DIFF = ...)>, C<name type COLLATE ...> for an
attribute), so that the diff after it is empty.

A type that moves to another schema or is renamed is a type to create and a
type to drop: the columns of it are altered to the new one with C<USING
col::text::new_type> in between (L<DBIO::PostgreSQL::Diff::Column>), and
C<DROP TYPE> comes last.

A type is dropped without C<CASCADE>. The order of the operations has dropped
what the model holds on it by then -- the columns that are of it are altered to
another type, the functions that take it are gone -- and a type that another
dropped type is built on (an attribute of a composite type, the subtype of a
range) is dropped after the type built on it. What is not in the model and
stands on the type -- a column of a table in a schema outside C<pg_schemas>, a
function or procedure of such a schema that takes or returns it, a domain over
it -- is read into the C<outside_dependents> section (the third argument, the
section of the source model) and B<refused> by name: C<refusing to diff: ...>
and no statement (L<DBIO::PostgreSQL::Diff::Dependents>). Anything else that
depends on the type stops the C<DROP TYPE> itself, and the transaction
C<apply> runs in leaves the database as it was.

An enum value added B<between> two the database has, or ahead of all of them,
is written with its position -- C<ADD VALUE 'c' AFTER 'a'>, or C<BEFORE 'a'>
for a value that comes first -- so the type has the target's order afterwards
and the next diff is empty. The position names the value before it in the
target (a new one is written ahead of it), or the first value the database
has. A value with no value the database has behind it is added with no
position. See L</value_positions>.

=head2 as_sql

Returns the SQL for this operation. For C<add_value>, returns one
C<ALTER TYPE ... ADD VALUE> statement per new enum value.

The type is written from the C<schema_name> and C<type_name> of its
C<type_info>, each quoted for itself by the server's rule
(L<DBIO::PostgreSQL::Util/quote_ident>) -- not from L</type_key>, which is
where the model files the type and cannot be taken apart again. A
C<type_info> without the names falls back to the key
(L<DBIO::PostgreSQL::Introspect/key_names>). Enum values are written as
literals (L<DBIO::PostgreSQL::Util/quote_literal>), the attribute names of a
composite type as identifiers; attribute types and a range's subtype come
from the catalog (C<format_type>) and are written as given, and so are a
collation, an operator class and the C<canonical> and C<subtype_diff>
functions, which the model holds quoted with their schema.

A C<create> of a type that is none of the three kinds has no statement, and
neither has a range type without a C<subtype>, an C<add_value> without values or an C<action> this class does
not know: C<as_sql> dies
(L<DBIO::PostgreSQL::Diff::NoStatement/throw>). The model has no such type
from L<DBIO::PostgreSQL::Introspect::Types>; an operation built by hand can.

=head2 summary

Returns a one-line description such as C<+type: auth.role_type (enum)> or
C<~type: auth.role_type +1 value(s) (superadmin)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
