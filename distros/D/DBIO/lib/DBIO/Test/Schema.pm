package DBIO::Test::Schema;
# ABSTRACT: Standard test schema for the DBIO ecosystem

use strict;
use warnings;
no warnings 'qw';

use base 'DBIO::Schema';
use DBIO::Util qw(old_mro);
use namespace::clean;


__PACKAGE__->mk_group_accessors(simple => 'custom_attr');

__PACKAGE__->load_classes(qw/
  Artist
  ArtistGUID
  BindType
  Employee
  CD
  Genre
  Bookmark
  Link
  #dummy
  Track
  Tag
  Year2000CDs
  Year1999CDs
  CustomSql
  TimestampPrimaryKey
  /,
  { 'DBIO::Test::Schema' => [qw/
    LinerNotes
    Artwork
    Artwork_to_Artist
    Image
    Lyrics
    LyricVersion
    OneKey
    #dummy
    TwoKeys
    Serialized
  /]},
  (
    'FourKeys',
    'FourKeys_to_TwoKeys',
    '#dummy',
    'SelfRef',
    'ArtistUndirectedMap',
    'ArtistSourceName',
    'ArtistSubclass',
    'Producer',
    'CD_to_Producer',
    'Dummy',    # this is a real result class we remove in the hook below
  ),
  qw/SelfRefAlias TreeLike TwoKeyTreeLike Event NoPrimaryKey/,
  qw/Collection CollectionObject TypedObject Owners BooksInLibrary/,
  qw/ForceForeign Encoded Money/,
);

sub sqlt_deploy_hook {
  my ($self, $sqlt_schema) = @_;

  $sqlt_schema->drop_table('dummy');
}


sub capture_executed_sql_bind {
  my ($self, $cref) = @_;

  $self->throw_exception("Expecting a coderef to run") unless ref $cref eq 'CODE';

  require DBIO::Test::SQLTracerObj;

  # hack around API to get raw bind values
  no warnings 'redefine';
  local *DBIO::Storage::DBI::_format_for_trace = sub { $_[1] };
  Class::C3->reinitialize if old_mro;

  local $self->storage->{debugcb};
  local $self->storage->{debugobj} = my $tracer_obj = DBIO::Test::SQLTracerObj->new;
  local $self->storage->{debug} = 1;

  local $Test::Builder::Level = $Test::Builder::Level + 2;
  $cref->();

  return $tracer_obj->{sqlbinds} || [];
}


sub is_executed_querycount {
  my ($self, $cref, $exp_counts, $msg) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  $self->throw_exception("Expecting an hashref of counts or an integer representing total query count")
    unless ref $exp_counts eq 'HASH' or (defined $exp_counts and ! ref $exp_counts);

  my @got = map { $_->[0] } @{ $self->capture_executed_sql_bind($cref) };

  return Test::More::is( scalar @got, $exp_counts, $msg )
    unless ref $exp_counts;

  my $got_counts = { map { $_ => 0 } keys %$exp_counts };
  $got_counts->{$_}++ for @got;

  return Test::More::is_deeply(
    $got_counts,
    $exp_counts,
    $msg,
  );
}


sub is_executed_sql_bind {
  my ($self, $cref, $sqlbinds, $msg) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  $self->throw_exception("Expecting an arrayref of SQL/Bind pairs") unless ref $sqlbinds eq 'ARRAY';

  my @expected = @$sqlbinds;

  my @got = map { $_->[1] } @{ $self->capture_executed_sql_bind($cref) };

  return Test::Builder->new->ok(1, $msg || "No queries executed while running $cref")
    if !@got and !@expected;

  require SQL::Abstract::Test;
  my $ret = 1;
  while (@expected or @got) {
    my $left = shift @got;
    my $right = shift @expected;

    if ($left and $right) {
      $left = [ @$left ];
      for my $i (1..$#$right) {
        if (
          ! ref $right->[$i]
            and
          ref $left->[$i] eq 'ARRAY'
            and
          @{$left->[$i]} == 2
        ) {
          $left->[$i] = $left->[$i][1]
        }
      }
    }

    $ret &= SQL::Abstract::Test::is_same_sql_bind(
      \( $left || [] ),
      \( $right || [] ),
      $msg,
    );
  }

  return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema - Standard test schema for the DBIO ecosystem

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  use DBIO::Test::Schema;

  my $schema = DBIO::Test::Schema->connect(@connect_info);
  my $rs = $schema->resultset('Artist');

See F<t/53-test-schema-fixtures.t> for a runnable example.

=head1 DESCRIPTION

A test schema with a standard set of Result classes (Artist, CD, Track,
etc.) used across the DBIO test suite and by driver distributions.

All Result classes live under C<DBIO::Test::Schema::*>.
Treat it as the shared schema fixture for offline SQL tests, driver checks,
and cross-repo regression coverage.

=head1 METHODS

=head2 capture_executed_sql_bind

  my $sqlbinds = $schema->capture_executed_sql_bind(sub {
    $schema->resultset('Artist')->all;
  });

Runs the coderef with SQL tracing enabled and returns an arrayref of
C<[$op, [$sql, @bind]]> tuples.

=head2 is_executed_querycount

  $schema->is_executed_querycount(sub { ... }, $expected_count, $msg);
  $schema->is_executed_querycount(sub { ... }, { SELECT => 1, INSERT => 2 }, $msg);

Runs the coderef and asserts the number of queries executed.

=head2 is_executed_sql_bind

  $schema->is_executed_sql_bind(
    sub { $rs->all },
    [[ 'SELECT me.* FROM artist me', [] ]],
    'correct SQL generated',
  );

Runs the coderef and asserts the generated SQL matches expectations.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
