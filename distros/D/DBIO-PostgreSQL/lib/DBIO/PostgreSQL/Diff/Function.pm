package DBIO::PostgreSQL::Diff::Function;
# ABSTRACT: Diff operations for PostgreSQL functions

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Diff::NoStatement ();
use DBIO::PostgreSQL::Util qw(quote_qualified trim_end);

__PACKAGE__->mk_diff_accessors(qw(function_key function_info replaced));






sub _refuse_without_definition {
  my ($key, $in_database) = @_;
  DBIO::PostgreSQL::Diff::NoStatement->refuse_without_definition(
    kind           => 'function',
    name           => $key,
    in_database    => $in_database,
    from           => 'pg_get_functiondef',
    null_when_gone => 1,
  );
}

sub _kind_of {
  my ($info) = @_;
  return $info->{kind} // 'f';
}

sub _kind_name {
  my ($info) = @_;
  my $kind = _kind_of($info);
  return $kind eq 'a' ? 'aggregate'
       : $kind eq 'w' ? 'window function'
       : $kind eq 'p' ? 'procedure'
       :                'function';
}

# What the server calls the signature of a routine: the types of its
# arguments. A procedure's identity arguments carry the mode (IN integer), a
# function's do not, so one routine is filed under two keys by its kind.
sub _signature_of {
  my ($key) = @_;
  (my $sig = $key) =~ s/([(,]\s*)IN\s+/$1/g;
  return $sig;
}

# A routine of the database the target has no key for, that the target's
# routine of the other kind would meet at the create: the server keeps one
# routine per name and input argument types, function or procedure alike.
sub _refuse_kind_clash {
  my ($key, $tgt, $src_key, $src) = @_;
  my ($from, $to) = (_kind_name($src), _kind_name($tgt));
  die join "\n",
    "refusing to diff: $from $src_key is in the database and $to $key is in the target, under the same argument types",
    '',
    'PostgreSQL holds one routine per name and argument types, a function or a',
    'procedure, and CREATE OR REPLACE can not change the kind of one. The diff',
    'pairs a function and a procedure whose signatures differ only in the mode',
    'IN, drops the old one and creates the new; these two differ in an INOUT',
    'or OUT argument or in an argument name, so the create would meet the old',
    'routine and the server would answer "already exists with same argument',
    'types" when the statements run.',
    'No statement was generated.',
    '',
    'Drop the old routine by hand and diff again:',
    '',
    '  ' . _sql_drop($src_key, $src) . ';',
    '';
}

sub _sql_drop {
  my ($key, $info) = @_;
  my $keyword = _kind_of($info) eq 'p' ? 'PROCEDURE' : 'FUNCTION';
  return "DROP $keyword $key";
}

sub _opaque {
  my ($info) = @_;
  return _kind_of($info) =~ /\A[aw]\z/ ? 1 : 0;
}

# An aggregate or a window function is in the model without a definition:
# pg_get_functiondef raises an error for one, so there is no text to write it
# from, and the diff does not make one up from pg_aggregate.
sub _refuse_opaque {
  my ($key, $tgt, $src, $src_key) = @_;
  my $what = _kind_name($tgt);
  my $head;
  if (!$src) {
    $head = "$what $key is in the target and not in the database";
  }
  elsif (_kind_of($src) ne _kind_of($tgt)) {
    $head = "$what $key is in the target, and the database has "
      . _kind_name($src) . ' ' . ($src_key // $key) . ' of the same signature';
  }
  else {
    $head = "$what $key is in the database and in the target with another definition";
  }
  die join "\n",
    "refusing to diff: $head",
    '',
    'The diff writes a function from the text pg_get_functiondef gives for it,',
    'and that function raises an error for an aggregate and for a window',
    "function: the model holds no definition of a $what to create or change",
    'it from.',
    'No statement was generated.',
    '',
    ( $what eq 'aggregate'
        ? 'Create or change it by hand (CREATE AGGREGATE; DROP AGGREGATE first for a change) and diff again.'
        : 'Create or change it by hand and diff again.' ),
    '';
}

sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  # The routines of the database the target does not have under their key,
  # by signature: where the target has one of another kind there, it is the
  # same routine under the other kind.
  my %by_signature;
  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    push @{ $by_signature{ _signature_of($key) } }, $key;
  }
  my %consumed;

  my $rebuild = sub {
    my ($src_key, $key) = @_;
    push @ops, $class->new(
      action        => 'drop',
      function_key  => $src_key,
      function_info => $source->{$src_key},
      replaced      => 1,
    );
    push @ops, $class->new(
      action        => 'create',
      function_key  => $key,
      function_info => $target->{$key},
    );
  };

  for my $key (sort keys %$target) {
    my $tgt_info = $target->{$key};
    my $tgt_def  = $tgt_info->{definition} // '';

    if (!exists $source->{$key}) {
      my ($src_key) = grep { !$consumed{$_} }
        grep { _kind_of($source->{$_}) ne _kind_of($tgt_info) }
        @{ $by_signature{ _signature_of($key) } // [] };

      if (defined $src_key) {
        _refuse_opaque($key, $tgt_info, $source->{$src_key}, $src_key)
          if _opaque($tgt_info) || _opaque($source->{$src_key});
        _refuse_without_definition($key, 1) unless $tgt_def =~ /\S/;
        $consumed{$src_key} = 1;
        $rebuild->($src_key, $key);
        next;
      }

      _refuse_opaque($key, $tgt_info) if _opaque($tgt_info);
      if (!_opaque($tgt_info) && defined $tgt_info->{input_types}) {
        my ($clash) = grep {
             !$consumed{$_} && !exists $target->{$_}
          && !_opaque($source->{$_})
          && _kind_of($source->{$_}) ne _kind_of($tgt_info)
          && ($source->{$_}{input_types} // '') eq $tgt_info->{input_types}
          && $source->{$_}{schema_name} eq $tgt_info->{schema_name}
          && $source->{$_}{function_name} eq $tgt_info->{function_name}
        } sort keys %$source;
        _refuse_kind_clash($key, $tgt_info, $clash, $source->{$clash}) if defined $clash;
      }
      _refuse_without_definition($key, 0) unless $tgt_def =~ /\S/;
      push @ops, $class->new(
        action        => 'create',
        function_key  => $key,
        function_info => $tgt_info,
      );
      next;
    }

    my $src_info = $source->{$key};
    if (_opaque($tgt_info) || _opaque($src_info)) {
      # The same on both sides is no operation; anything else has no statement.
      next if _kind_of($src_info) eq _kind_of($tgt_info)
        && ($src_info->{fingerprint} // '') eq ($tgt_info->{fingerprint} // '');
      _refuse_opaque($key, $tgt_info, $src_info);
    }
    if (_kind_of($src_info) ne _kind_of($tgt_info)) {
      _refuse_without_definition($key, 1) unless $tgt_def =~ /\S/;
      $rebuild->($key, $key);
      next;
    }

    # Compare definitions
    my $src_def = $src_info->{definition} // '';
    if ($src_def ne $tgt_def) {
      _refuse_without_definition($key, 1) unless $tgt_def =~ /\S/;
      push @ops, $class->new(
        action        => 'replace',
        function_key  => $key,
        function_info => $tgt_info,
      );
    }
  }

  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    next if $consumed{$key};
    push @ops, $class->new(
      action        => 'drop',
      function_key  => $key,
      function_info => $source->{$key},
    );
  }

  return @ops;
}


# "schema"."name"(identity args) for DROP FUNCTION.
sub _sql_signature {
  my ($self, $no_args) = @_;
  my $info = $self->function_info // {};

  my ($schema_name, $function_name, $args) =
    @{$info}{qw(schema_name function_name identity_args)};
  unless (defined $schema_name && defined $function_name) {
    ($schema_name, $function_name, $args) =
      $self->function_key =~ /\A([^.]*)\.([^(]*)\((.*)\)\z/s
        or return $self->function_key;
  }
  return sprintf '%s(%s)',
    quote_qualified($schema_name, $function_name),
    ( ( $args // '' ) eq '' ? $no_args // '' : $args );
}

sub as_sql {
  my ($self) = @_;
  my $info = $self->function_info;

  my $action = $self->action // '';
  my $object = 'function ' . ($self->function_key // '');

  if ($action eq 'create' || $action eq 'replace') {
    my $def = $info->{definition};
    DBIO::PostgreSQL::Diff::NoStatement->throw(
      $self, $object, 'its function_info has no definition',
    ) unless defined $def && $def =~ /\S/;
    $def = trim_end($def);
    $def .= ';' unless substr($def, -1) eq ';';
    return $def;
  }
  elsif ($action eq 'drop') {
    my $kind = $info->{kind} // '';
    # An aggregate is dropped by DROP AGGREGATE, one without arguments as
    # name(*); a window function is dropped as the function it is.
    return sprintf 'DROP AGGREGATE %s;', $self->_sql_signature('*') if $kind eq 'a';
    return sprintf 'DROP %s %s;',
      ( $kind eq 'p' ? 'PROCEDURE' : 'FUNCTION' ), $self->_sql_signature;
  }
  DBIO::PostgreSQL::Diff::NoStatement->throw($self, $object);
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : $self->action eq 'drop' ? '-' : '~';
  return sprintf '  %sfunction: %s', $prefix, $self->function_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Function - Diff operations for PostgreSQL functions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a function-level diff operation: C<CREATE FUNCTION>, C<DROP
FUNCTION>, or C<CREATE OR REPLACE FUNCTION> (when the definition has changed).
Function identity is by the full signature key C<schema.name(identity_args)>.

=head1 ATTRIBUTES

=head2 function_key

The function's identity string: C<schema.name(args)>.

=head2 function_info

Function metadata hashref (C<definition>, C<language>, C<return_type>, etc.).

=head2 replaced

True on the C<drop> of a routine that is dropped only to be created again
under the other kind: a function that is now a procedure, or the other way
round. It tells L<DBIO::PostgreSQL::Diff> to leave the two together instead of
moving the drop to the removals (L<DBIO::PostgreSQL::Diff/ORDER OF
OPERATIONS>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Function->diff($source, $target);

Compares function hashrefs by identity key. Produces C<create>, C<replace>
(definition changed), or C<drop> operations.

A function that is a procedure in the target (or the other way round) is not
replaced: C<CREATE OR REPLACE> cannot change the kind of a routine, and the
server answers C<cannot change routine kind>. The old routine is dropped
(C<replaced> true) and the new one created behind it. The identity arguments
of a procedure carry the mode (C<f(IN integer)>), a function's do not, so
the two are filed under two keys; the diff pairs them by the signature with
the mode left out. The C<DROP> has no C<CASCADE>: a routine something else
depends on, a trigger for one, is refused by the server when the statement
runs. That is so for a function a trigger or a column default still uses, a
trigger function that becomes a procedure: the server answers C<cannot drop
function ... because other objects depend on it>, naming the trigger or the
column, and the transaction C<apply> runs the statements in leaves the
database as it was (t/171-diff-function-kind-dependents-live.t).

Where the keys do not pair -- an C<INOUT> argument (its mode is not left out
of the signature), another argument name, an C<OUT> argument one side has --
but the two routines have the same C<input_types>, the diff is B<refused>
when the operations are built (C<refusing to diff: ...>). PostgreSQL holds one
routine per schema, name and input argument types, function or procedure, so
the C<CREATE> of the new one, written ahead of the removal of the old, would
be answered C<function ... already exists with same argument types> only when
the statements run. The message names both routines and the way out, a
C<DROP> of the old one by hand and a new diff. (A model without C<input_types>,
one built by hand, is not checked.) Measured on PostgreSQL 18, in both
directions: C<DROP> then C<CREATE> of the other kind runs for every case, so
the refusal is the diff's rule, not the server's.

An aggregate or a window function (C<kind> C<a> or C<w>,
L<DBIO::PostgreSQL::Introspect::Functions>) has no definition in the model:
C<pg_get_functiondef> raises an error for one, and the diff does not make a
C<CREATE AGGREGATE> up from C<pg_aggregate>. One the target has and the
database has not, or has with another definition (compared by the
C<fingerprint> of its catalog rows), or as another kind, is B<refused> with
C<refusing to diff: ...>, naming it and saying to create or change it by hand.
One that is the same on both sides is no operation, and one only the database
has is dropped like any function: an aggregate by C<DROP AGGREGATE
schema.name(args)> (C<name(*)> for one without arguments), a window function
by C<DROP FUNCTION>, in the removals. Dropping needs no definition, only the
signature. What belongs to an extension is not in the model and is never
dropped.

A function to create or to replace that the target model has no C<definition>
for is B<refused>, with C<refusing to diff: ...> and no statement
(L<DBIO::PostgreSQL::Diff::NoStatement>): the definition is all the diff
writes a function from, and all it compares one by. C<pg_get_functiondef>
gives none for a function another session dropped while the model was read. A
function only the source lacks the definition of is replaced like any other
whose definition differs, and a C<drop> needs none.

=head2 as_sql

Returns the SQL. For C<create> and C<replace>, emits the full function
definition from introspection (C<pg_get_functiondef>, the server's own text).
For C<drop>, returns C<DROP FUNCTION schema.name(identity_args);>, C<DROP
AGGREGATE ...> for an aggregate (C<kind> C<a>; C<name(*)> without arguments),
or C<DROP PROCEDURE ...> for a procedure -- an entry whose C<kind> is C<p>
(L<DBIO::PostgreSQL::Introspect::Functions>). PostgreSQL drops a procedure
with no other statement (C<... is not a function>). An entry that does not
say what it is is dropped as a function.

The dropped function is written from the C<schema_name>, C<function_name>
and C<identity_args> of its C<function_info>: schema and name each quoted for
itself by the server's rule (L<DBIO::PostgreSQL::Util/quote_ident>), the
argument list as C<pg_get_function_identity_arguments> gives it. It is not
written from L</function_key>, which is where the model files the function. A
C<function_info> without the names falls back to the key, read as
C<schema.name(args)> with the schema ending at the first dot.

A C<create> or C<replace> whose C<function_info> has no C<definition> has no
statement, and neither has an C<action> this class does not know: C<as_sql>
dies (L<DBIO::PostgreSQL::Diff::NoStatement/throw>) and returns no comment in
its place. L</diff> builds no such operation; one built by hand can be.

=head2 summary

Returns a one-line description such as C<+function: auth.update_modified_at()>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
