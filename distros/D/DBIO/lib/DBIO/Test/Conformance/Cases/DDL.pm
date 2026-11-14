package DBIO::Test::Conformance::Cases::DDL;
# ABSTRACT: The shared DDL cases every DBIO driver answers

use strict;
use warnings;

our $VERSION = '0.900005';

use DBIO::Util ();
use DBIO::Schema::Type ();


my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

my @CASES = (

  {
    name  => 'ddl-default-string-apostrophe',
    since => 1,
    subject => { source => 'Note', column => 'note' },
    input => { sources => [ {
      name => 'Note', table => 'note',
      columns => [
        id   => $id->(),
        note => { data_type => 'varchar', size => 20, is_nullable => 0,
                  default_value => "it's" },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { read_back => { source => 'Note', create => { id => 1 },
                       is => { note => "it's" } } },
    ],
  },

  {
    name  => 'ddl-default-digit-string',
    since => 1,
    subject => { source => 'Code', column => 'code' },
    input => { sources => [ {
      name => 'Code', table => 'code',
      columns => [
        id   => $id->(),
        code => { data_type => 'char', size => 5, is_nullable => 0,
                  default_value => '007' },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { read_back => { source => 'Code', create => { id => 1 },
                       is => { code => '007' } } },
    ],
  },

  {
    name  => 'ddl-default-expression',
    since => 1,
    subject => { source => 'Stamp', column => 'created' },
    input => { sources => [ {
      name => 'Stamp', table => 'stamp',
      columns => [
        id      => $id->(),
        created => { data_type => 'timestamp', is_nullable => 0,
                     default_value => \'CURRENT_TIMESTAMP' },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { read_back => { source => 'Stamp', create => { id => 1 },
                       like => { created => qr/^\d{4}-\d\d-\d\d/ },
                       isnt => { created => 'CURRENT_TIMESTAMP' } } },
    ],
  },

  {
    name  => 'ddl-enum-value-apostrophe',
    since => 1,
    subject => { source => 'Pick', column => 'kind' },
    input => { sources => [ {
      name => 'Pick', table => 'pick',
      columns => [
        id   => $id->(),
        kind => { data_type => 'enum', extra => { list => [ "it's", 'plain' ] },
                  is_nullable => 0 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { read_back => { source => 'Pick', create => { id => 1, kind => "it's" },
                       is => { kind => "it's" } } },
    ],
  },

  {
    name  => 'ddl-ident-reserved-word',
    since => 1,
    subject => { source => 'Order', column => 'group' },
    input => { sources => [ {
      name => 'Order', table => 'order',
      columns => [
        id    => $id->(),
        user  => { data_type => 'varchar', size => 20, is_nullable => 1 },
        group => { data_type => 'varchar', size => 20, is_nullable => 1 },
        end   => { data_type => 'varchar', size => 20, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { read_back => { source => 'Order',
                       create => { id => 1, user => 'u', group => 'g', end => 'e' },
                       is => { user => 'u', group => 'g', end => 'e' } } },
      { search_by => { source => 'Order', create => { id => 2, user => 'v', group => 'h', end => 'f' },
                       column => 'group', value => 'h' } },
    ],
  },

  {
    name  => 'ddl-ident-mixed-case',
    since => 1,
    subject => { source => 'MixedCase', column => 'camelCol' },
    input => { sources => [ {
      name => 'MixedCase', table => 'MixedCase',
      columns => [
        id       => $id->(),
        camelCol => { data_type => 'varchar', size => 20, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'table_name', source => 'MixedCase', is => 'MixedCase' } },
      { fact => { name => 'column_names', source => 'MixedCase',
                  is => [ 'camelCol', 'id' ] } },
    ],
  },

  {
    name  => 'ddl-ident-special-chars',
    since => 1,
    subject => { source => 'Odd', column => 'odd "c" `n`' },
    input => { sources => [ {
      name => 'Odd', table => 'odd "t" `n`',
      columns => [
        id            => $id->(),
        'odd "c" `n`' => { data_type => 'varchar', size => 20, is_nullable => 1,
                          accessor => 'odd_c' },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'table_name', source => 'Odd', is => 'odd "t" `n`' } },
      { fact => { name => 'column_names', source => 'Odd',
                  is => [ 'id', 'odd "c" `n`' ] } },
      { read_back => { source => 'Odd', create => { id => 1, 'odd "c" `n`' => 'x' },
                       is => { 'odd "c" `n`' => 'x' } } },
    ],
  },

  {
    name  => 'ddl-view-declared',
    since => 1,
    subject => { source => 'BaseView' },
    input => { sources => [
      {
        name => 'Base', table => 'base',
        columns => [
          id   => $id->(),
          name => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      },
      {
        name => 'BaseView', table => 'base_view',
        columns => [
          id   => { data_type => 'integer' },
          name => { data_type => 'varchar', size => 20 },
        ],
        view => { definition => 'SELECT {{id}}, {{name}} FROM {{base}}', virtual => 0 },
      },
      {
        name => 'VirtualView', table => 'virtual_view',
        columns => [
          id => { data_type => 'integer' },
        ],
        view => { definition => 'SELECT id FROM base', virtual => 1 },
      },
    ] },
    expect => [
      { fact => { name => 'object_kind', source => 'BaseView', is => 'view' } },
      { fact => { name => 'object_kind', source => 'VirtualView', is => undef } },
      { search_by => { source => 'Base', create => { id => 1, name => 'x' },
                       through => 'BaseView', column => 'name', value => 'x' } },
    ],
  },

  {
    name  => 'ddl-unique-constraint',
    since => 1,
    subject => { source => 'Pair', column => 'a' },
    input => { sources => [ {
      name => 'Pair', table => 'pair',
      columns => [
        id => $id->(),
        a  => { data_type => 'integer', is_nullable => 0 },
        b  => { data_type => 'integer', is_nullable => 0 },
      ],
      primary_key => [ 'id' ],
      unique      => [ [ pair_ab => [ 'a', 'b' ] ] ],
    } ] },
    expect => [
      { fact => { name => 'unique_exists', source => 'Pair', columns => [ 'a', 'b' ], is => 1 } },
      { rejects => { source => 'Pair', first => { id => 1, a => 1, b => 2 },
                     create => { id => 2, a => 1, b => 2 } } },
    ],
  },

  {
    name  => 'ddl-foreign-key',
    since => 1,
    subject => { source => 'Child', column => 'parent_id' },
    input => { sources => [
      {
        name => 'Parent', table => 'parent',
        columns => [ id => $id->() ],
        primary_key => [ 'id' ],
      },
      {
        name => 'Child', table => 'child',
        columns => [
          id        => $id->(),
          parent_id => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key   => [ 'id' ],
        relationships => [
          { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' },
        ],
      },
    ] },
    expect => [
      { fact => { name => 'foreign_key_count', source => 'Child', is => 1 } },
      { rejects => { source => 'Child', create => { id => 1, parent_id => 999 } } },
    ],
  },

  {
    name  => 'ddl-fk-actions',
    since => 1,
    subject => { source => 'Child', column => 'parent_id' },
    input => { sources => [
      {
        name => 'Parent', table => 'parent',
        columns => [ id => $id->() ],
        primary_key => [ 'id' ],
      },
      {
        name => 'Child', table => 'child',
        columns => [
          id        => $id->(),
          parent_id => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key   => [ 'id' ],
        relationships => [
          { type => 'belongs_to', name => 'parent', source => 'Parent',
            cond => 'parent_id', attrs => { on_delete => 'CASCADE' } },
        ],
      },
    ] },
    expect => [
      { cascade_delete => { parent => 'Parent', parent_values => { id => 1 },
                            child => 'Child', child_values => { id => 1 },
                            link => { parent_id => 'id' } } },
    ],
  },

  {
    name  => 'ddl-fk-two-rels-one-column',
    since => 1,
    subject => { source => 'Child', column => 'parent_id' },
    input => { sources => [
      {
        name => 'Parent', table => 'parent',
        columns => [ id => $id->() ],
        primary_key => [ 'id' ],
      },
      {
        name => 'Child', table => 'child',
        columns => [
          id        => $id->(),
          parent_id => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key   => [ 'id' ],
        relationships => [
          { type => 'belongs_to', name => 'parent',     source => 'Parent', cond => 'parent_id' },
          { type => 'belongs_to', name => 'parent_alt', source => 'Parent', cond => 'parent_id' },
        ],
      },
    ] },
    expect => [
      { fact => { name => 'foreign_key_count', source => 'Child', is => 1 } },
    ],
  },

  {
    name  => 'ddl-fk-table-order',
    since => 1,
    subject => { source => 'AChild', column => 'parent_id' },
    input => { sources => [
      {
        name => 'AChild', table => 'a_child',
        columns => [
          id        => $id->(),
          parent_id => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key   => [ 'id' ],
        relationships => [
          { type => 'belongs_to', name => 'parent', source => 'ZParent', cond => 'parent_id' },
        ],
      },
      {
        name => 'ZParent', table => 'z_parent',
        columns => [ id => $id->() ],
        primary_key => [ 'id' ],
      },
    ] },
    expect => [
      { fact => { name => 'object_kind', source => 'AChild', is => 'table' } },
      { fact => { name => 'foreign_key_count', source => 'AChild', is => 1 } },
    ],
  },

  {
    name  => 'ddl-auto-increment',
    since => 1,
    subject => { source => 'Counter', column => 'id' },
    input => { sources => [ {
      name => 'Counter', table => 'counter',
      columns => [
        id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
        name => { data_type => 'varchar', size => 20, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { auto_key => { source => 'Counter', create => { name => 'x' } } },
      { fact => { name => 'column_auto_increment', source => 'Counter',
                  column => 'id', is => 1 } },
    ],
  },

  {
    name  => 'ddl-type-size-char',
    since => 2,
    subject => { source => 'Sized', column => 'c' },
    input => { sources => [ {
      name => 'Sized', table => 'sized',
      columns => [
        id => $id->(),
        c  => { data_type => 'character', size => 10, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'column_size', source => 'Sized', column => 'c', is => 10 } },
      { rejects => { source => 'Sized', create => { id => 1, c => 'x' x 11 } } },
    ],
  },

  {
    name  => 'ddl-type-size-bit',
    since => 2,
    subject => { source => 'Sized', column => 'b' },
    input => { sources => [ {
      name => 'Sized', table => 'sized',
      columns => [
        id => $id->(),
        b  => { data_type => 'bit', size => 8, is_nullable => 1 },
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'column_size', source => 'Sized', column => 'b', is => 8 } },
    ],
  },

  {
    name  => 'ddl-base-types-roundtrip',
    since => 1,
    subject => { source => 'Types' },
    input => { sources => [ {
      name => 'Types', table => 'types',
      columns => [
        id => $id->(),
        ( map {
            my $type = $_;
            ( "t_$type" => {
                data_type   => $type,
                is_nullable => 1,
                ( $type eq 'char'    ? ( size => 5 )         : () ),
                ( $type eq 'numeric' ? ( size => [ 10, 2 ] ) : () ),
            } );
          } DBIO::Schema::Type::base_types() ),
      ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'object_kind', source => 'Types', is => 'table' } },
      { fact => { name => 'column_names', source => 'Types',
                  is => [ 'id', map { "t_$_" } DBIO::Schema::Type::base_types() ] } },
    ],
  },

  {
    name  => 'ddl-index-on-unique-columns',
    since => 1,
    subject => { source => 'Child', column => 'a' },
    input => { sources => [
      {
        name => 'Parent', table => 'parent',
        columns => [ id => $id->() ],
        primary_key => [ 'id' ],
      },
      {
        name => 'Child', table => 'child',
        columns => [
          id        => $id->(),
          parent_id => { data_type => 'integer', is_nullable => 0 },
          a         => { data_type => 'integer', is_nullable => 0 },
          b         => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key   => [ 'id' ],
        unique        => [ [ child_ab => [ 'a', 'b' ] ] ],
        relationships => [
          { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' },
        ],
        indexes => [
          { name => 'child_ab_idx',     columns => [ 'a', 'b' ] },
          { name => 'child_parent_idx', columns => [ 'parent_id' ] },
        ],
      },
    ] },
    expect => [
      { fact => { name => 'index_count', source => 'Child', columns => [ 'a', 'b' ], is => 1 } },
      { fact => { name => 'index_count', source => 'Child', columns => [ 'parent_id' ], is => 1 } },
    ],
  },

  {
    name  => 'ddl-qualified-source-name',
    since => 1,
    subject => { source => 'Qualified' },
    input => { sources => [ {
      name => 'Qualified', table => 'other.t',
      columns => [ id => $id->() ],
      primary_key => [ 'id' ],
    } ] },
    expect => [
      { fact => { name => 'table_in_namespace', source => 'Qualified',
                  namespace => 'other', unqualified => 't', is => 1 } },
    ],
  },

  {
    name  => 'ddl-unique-not-null-without-pk',
    since => 1,
    subject => { source => 'Loose', column => 'code' },
    input => { sources => [ {
      name => 'Loose', table => 'loose',
      columns => [
        code => { data_type => 'varchar', size => 20, is_nullable => 0 },
      ],
      unique => [ [ loose_code => [ 'code' ] ] ],
    } ] },
    expect => [
      { fact => { name => 'primary_key_columns', source => 'Loose', is => [] } },
    ],
  },

);

sub cases {
  return DBIO::Util::deep_copy([ @CASES ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Conformance::Cases::DDL - The shared DDL cases every DBIO driver answers

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

The DDL list of L<DBIO::Test::Conformance> (ADR 0060): twenty cases, D1 to
D19 of the ADR's first case list (D15 as two cases, C<ddl-type-size-char> and C<ddl-type-size-bit>), as plain Perl data. A case is one schema
declaration in DBIO's own terms and what must be observable on the server
after it was installed. It holds no SQL and no driver name.

A case is a hash:

  {
    name    => 'ddl-default-string-apostrophe',   # stable id, ddl- prefix
    since   => 1,                                 # table version that added it
    subject => { source => 'Note', column => 'note' },   # optional, see below
    input   => { sources => [ { ... }, ... ] },
    expect  => [ { read_back => { ... } }, ... ],
  }

C<input> and C<expect> are documented in L<DBIO::Test::Conformance/CASES>.
C<subject> names what a refusal must mention: the table of C<source> and, when
given, the C<column>. Without it the first source and no column.

The order is the order of the ADR appendix, so C<D5> is the fifth
entry. Names never change once published; a case that turns out wrong is
replaced by a new one with a higher C<since>.

=head1 METHODS

=head2 cases

  my $cases = DBIO::Test::Conformance::Cases::DDL->cases;

An arrayref of the cases. It is a deep copy: a caller cannot damage the next
run's table.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
