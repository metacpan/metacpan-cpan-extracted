package DBIO::Test::Conformance::Cases::Diff;
# ABSTRACT: The shared Diff cases every DBIO driver answers

use strict;
use warnings;

our $VERSION = '0.900004';

use Storable ();


my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

# a small table the cases share: id and a nullable text column
my $base = sub {
  my (%extra) = @_;
  return {
    name => 'Base', table => 'base',
    columns => [
      id   => $id->(),
      name => { data_type => 'varchar', size => 20, is_nullable => 1 },
      @{ delete $extra{more} || [] },
    ],
    primary_key => [ 'id' ],
    %extra,
  };
};

my $view = sub {
  my ($definition, @columns) = @_;
  return {
    name => 'BaseView', table => 'base_view',
    columns => [ @columns ],
    view => { definition => $definition, virtual => 0 },
  };
};

my $parent = sub {
  return {
    name => 'Parent', table => 'parent',
    columns => [ id => $id->(), @{ shift || [] } ],
    primary_key => [ 'id' ],
    @_,
  };
};

my @CASES = (

  {
    name  => 'diff-view-added',
    since => 1,
    cards => [ 'dbio-sqlite k67', 'dbio-postgresql k100', 'dbio-mysql k79',
               'dbio-mssql k45', 'dbio-firebird k33', 'dbio-clickhouse k31' ],
    subject => { source => 'BaseView' },
    input => {
      from => { sources => [ $base->() ] },
      to   => { sources => [
        $base->(),
        $view->('SELECT {{id}}, {{name}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'BaseView', is => 'view' } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } },
      { search_by => { source => 'Base', create => { id => 2, name => 'y' },
                       through => 'BaseView', column => 'name', value => 'y' } },
    ],
  },

  {
    name  => 'diff-view-dropped',
    since => 1,
    cards => [ 'dbio-sqlite k67', 'dbio-postgresql k100', 'dbio-mysql k79',
               'dbio-mssql k45', 'dbio-firebird k33', 'dbio-clickhouse k31' ],
    subject => { source => 'BaseView' },
    input => {
      from => { sources => [
        $base->(),
        $view->('SELECT {{id}}, {{name}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }),
      ] },
      to   => { sources => [ $base->() ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'BaseView', is => undef } },
      { fact => { name => 'object_kind', source => 'Base', is => 'table' } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } },
    ],
  },

  {
    name  => 'diff-view-definition-changed',
    since => 1,
    cards => [ 'dbio-sqlite k67' ],
    subject => { source => 'BaseView' },
    input => {
      from => { sources => [
        $base->(more => [ extra => { data_type => 'varchar', size => 20, is_nullable => 1 } ]),
        $view->('SELECT {{id}}, {{name}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }),
      ] },
      to   => { sources => [
        $base->(more => [ extra => { data_type => 'varchar', size => 20, is_nullable => 1 } ]),
        $view->('SELECT {{id}}, {{name}}, {{extra}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 },
                extra => { data_type => 'varchar', size => 20 }),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x', extra => 'e' } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'BaseView', is => 'view' } },
      { search_by => { source => 'Base', create => { id => 2, name => 'y', extra => 'f' },
                       through => 'BaseView', column => 'extra', value => 'f' } },
    ],
  },

  {
    name  => 'diff-table-added-complete',
    since => 1,
    cards => [ 'dbio-oracle k37', 'dbio-mysql k81', 'dbio-mysql k92',
               'dbio-sqlite k56 (done)' ],
    subject => { source => 'Child', column => 'parent_id' },
    input => {
      from => { sources => [
        { name => 'Anchor', table => 'anchor', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
      ] },
      to => { sources => [
        { name => 'Anchor', table => 'anchor', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
        $parent->(),
        {
          name => 'Child', table => 'child',
          columns => [
            id        => $id->(),
            parent_id => { data_type => 'integer', is_nullable => 0 },
            code      => { data_type => 'varchar', size => 20, is_nullable => 0 },
            label     => { data_type => 'varchar', size => 20, is_nullable => 1 },
          ],
          primary_key   => [ 'id' ],
          unique        => [ [ child_code => [ 'code' ] ] ],
          indexes       => [ { name => 'child_label_idx', columns => [ 'label' ] } ],
          relationships => [
            { type => 'belongs_to', name => 'parent', source => 'Parent',
              cond => 'parent_id', attrs => { on_delete => 'CASCADE' } },
          ],
        },
      ] },
      rows => [ { source => 'Anchor', values => { id => 1 } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'Child', is => 'table' } },
      { fact => { name => 'primary_key_columns', source => 'Child', is => [ 'id' ] } },
      { fact => { name => 'unique_exists', source => 'Child', columns => [ 'code' ], is => 1 } },
      { fact => { name => 'index_count', source => 'Child', columns => [ 'label' ], is => 1 } },
      { fact => { name => 'foreign_key_count', source => 'Child', is => 1 } },
      { rows_kept => { source => 'Anchor', find => { id => 1 } } },
      { read_back => { source => 'Parent', create => { id => 5 } } },
      { rejects => { source => 'Child', first => { id => 10, parent_id => 5, code => 'dup' },
                     create => { id => 11, parent_id => 5, code => 'dup' } } },
      { rejects => { source => 'Child', create => { id => 12, parent_id => 1000, code => 'orphan' } } },
      { cascade_delete => { parent => 'Parent', parent_values => { id => 1 },
                            child => 'Child', child_values => { id => 1, code => 'c1' },
                            link => { parent_id => 'id' } } },
    ],
  },

  {
    name  => 'diff-column-added-not-null-populated',
    since => 1,
    cards => [ 'dbio-sqlite k65' ],
    subject => { source => 'Base', column => 'code' },
    input => {
      from => { sources => [ $base->() ] },
      to   => { sources => [
        $base->(more => [ code => { data_type => 'varchar', size => 10, is_nullable => 0 } ]),
      ] },
      rows => [
        { source => 'Base', values => { id => 1, name => 'one' } },
        { source => 'Base', values => { id => 2, name => 'two' } },
      ],
    },
    expect => [
      { fact => { name => 'column_names', source => 'Base', is => [ 'code', 'id', 'name' ] } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'one' } } },
      { rows_kept => { source => 'Base', find => { id => 2 }, is => { name => 'two' } } },
      { read_back => { source => 'Base', create => { id => 3, name => 'three', code => 'z' },
                       is => { code => 'z' } } },
    ],
  },

  {
    name  => 'diff-column-added-expression-default',
    since => 1,
    cards => [ 'dbio-sqlite k65' ],
    subject => { source => 'Base', column => 'created' },
    input => {
      from => { sources => [ $base->() ] },
      to   => { sources => [
        $base->(more => [
          created => { data_type => 'timestamp', is_nullable => 0,
                       default_value => \'CURRENT_TIMESTAMP' },
        ]),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'one' } } ],
    },
    expect => [
      { fact => { name => 'column_names', source => 'Base', is => [ 'created', 'id', 'name' ] } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'one' } } },
      { read_back => { source => 'Base', create => { id => 2, name => 'two' },
                       like => { created => qr/^\d{4}-\d\d-\d\d/ },
                       isnt => { created => 'CURRENT_TIMESTAMP' } } },
    ],
  },

  {
    name  => 'diff-default-changed-apostrophe',
    since => 1,
    cards => [ 'dbio-oracle k47', 'dbio-mysql k78', 'dbio-sqlite k68' ],
    subject => { source => 'Note', column => 'note' },
    input => {
      from => { sources => [ {
        name => 'Note', table => 'note',
        columns => [
          id   => $id->(),
          note => { data_type => 'varchar', size => 20, is_nullable => 0, default_value => 'a' },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Note', table => 'note',
        columns => [
          id   => $id->(),
          note => { data_type => 'varchar', size => 20, is_nullable => 0, default_value => "it's" },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [ { source => 'Note', values => { id => 1, note => 'a' } } ],
    },
    expect => [
      { rows_kept => { source => 'Note', find => { id => 1 }, is => { note => 'a' } } },
      { read_back => { source => 'Note', create => { id => 2 }, is => { note => "it's" } } },
    ],
  },

  {
    name  => 'diff-default-expression-kept',
    since => 1,
    cards => [ 'dbio-mysql k78' ],
    subject => { source => 'Stamp', column => 'created' },
    input => {
      from => { sources => [ {
        name => 'Stamp', table => 'stamp',
        columns => [
          id      => $id->(),
          created => { data_type => 'timestamp', is_nullable => 0,
                       default_value => \'CURRENT_TIMESTAMP' },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Stamp', table => 'stamp',
        columns => [
          id      => $id->(),
          created => { data_type => 'timestamp', is_nullable => 0,
                       default_value => \'CURRENT_TIMESTAMP' },
          extra   => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [ { source => 'Stamp', values => { id => 1 } } ],
    },
    expect => [
      { rows_kept => { source => 'Stamp', find => { id => 1 } } },
      { read_back => { source => 'Stamp', create => { id => 2 },
                       like => { created => qr/^\d{4}-\d\d-\d\d/ },
                       isnt => { created => 'CURRENT_TIMESTAMP' } } },
    ],
  },

  {
    name  => 'diff-default-removed',
    since => 1,
    cards => [ 'dbio-mysql k95' ],
    subject => { source => 'Opt', column => 'c' },
    input => {
      from => { sources => [ {
        name => 'Opt', table => 'opt',
        columns => [
          id => $id->(),
          c  => { data_type => 'varchar', size => 10, is_nullable => 1, default_value => 'x' },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Opt', table => 'opt',
        columns => [
          id => $id->(),
          c  => { data_type => 'varchar', size => 10, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [ { source => 'Opt', values => { id => 1, c => 'x' } } ],
    },
    expect => [
      { rows_kept => { source => 'Opt', find => { id => 1 }, is => { c => 'x' } } },
      { read_back => { source => 'Opt', create => { id => 2 }, is => { c => undef } } },
    ],
  },

  {
    name  => 'diff-indexed-column-dropped',
    since => 3,
    cards => [ 'dbio-mysql k80' ],
    subject => { source => 'Wide', column => 'drop_idx_col' },
    input => {
      from => { sources => [ {
        name => 'Wide', table => 'wide',
        columns => [
          id => $id->(),
          drop_idx_col => { data_type => 'integer', is_nullable => 1 },
          wide_uq_one => { data_type => 'integer', is_nullable => 0 },
          wide_uq_two => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key => [ 'id' ],
        unique      => [ [ wide_uq_idx => [ 'wide_uq_one', 'wide_uq_two' ] ] ],
        indexes     => [ { name => 'wide_drop_idx', columns => [ 'drop_idx_col' ] } ],
      } ] },
      to => { sources => [ {
        name => 'Wide', table => 'wide',
        columns => [
          id => $id->(),
          wide_uq_two => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [ { source => 'Wide', values => { id => 1, drop_idx_col => 1, wide_uq_one => 2, wide_uq_two => 3 } } ],
    },
    expect => [
      { fact => { name => 'column_names', source => 'Wide', is => [ 'id', 'wide_uq_two' ] } },
      { fact => { name => 'unique_exists', source => 'Wide', columns => [ 'wide_uq_one', 'wide_uq_two' ], is => 0 } },
      { fact => { name => 'index_count', source => 'Wide', columns => [ 'drop_idx_col' ], is => 0 } },
      { rows_kept => { source => 'Wide', find => { id => 1 }, is => { wide_uq_two => 3 } } },
    ],
  },

  {
    name  => 'diff-fk-dropped',
    since => 1,
    cards => [ 'dbio-mysql k94' ],
    subject => { source => 'Child', column => 'parent_id' },
    input => {
      from => { sources => [
        $parent->(),
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
      to => { sources => [
        $parent->(),
        {
          name => 'Child', table => 'child',
          columns => [
            id        => $id->(),
            parent_id => { data_type => 'integer', is_nullable => 0 },
          ],
          primary_key => [ 'id' ],
        },
      ] },
      rows => [
        { source => 'Parent', values => { id => 1 } },
        { source => 'Child',  values => { id => 1, parent_id => 1 } },
      ],
    },
    expect => [
      { fact => { name => 'foreign_key_count', source => 'Child', is => 0 } },
      { rows_kept => { source => 'Child', find => { id => 1 }, is => { parent_id => 1 } } },
      { read_back => { source => 'Child', create => { id => 2, parent_id => 999 },
                       is => { parent_id => 999 } } },
    ],
  },

  {
    name  => 'diff-fk-added-to-new-unique',
    since => 1,
    cards => [ 'dbio-mysql k81' ],
    subject => { source => 'Child', column => 'parent_code' },
    input => {
      from => { sources => [
        $parent->([ code => { data_type => 'varchar', size => 20, is_nullable => 0 } ]),
        {
          name => 'Child', table => 'child',
          columns => [
            id          => $id->(),
            parent_code => { data_type => 'varchar', size => 20, is_nullable => 0 },
          ],
          primary_key => [ 'id' ],
        },
      ] },
      to => { sources => [
        $parent->([ code => { data_type => 'varchar', size => 20, is_nullable => 0 } ],
                  unique => [ [ parent_code_uq => [ 'code' ] ] ]),
        {
          name => 'Child', table => 'child',
          columns => [
            id          => $id->(),
            parent_code => { data_type => 'varchar', size => 20, is_nullable => 0 },
          ],
          primary_key   => [ 'id' ],
          relationships => [
            { type => 'belongs_to', name => 'parent', source => 'Parent',
              cond => { 'foreign.code' => 'self.parent_code' } },
          ],
        },
      ] },
      rows => [
        { source => 'Parent', values => { id => 1, code => 'p1' } },
        { source => 'Child',  values => { id => 1, parent_code => 'p1' } },
      ],
    },
    expect => [
      { fact => { name => 'unique_exists', source => 'Parent', columns => [ 'code' ], is => 1 } },
      { fact => { name => 'foreign_key_count', source => 'Child', is => 1 } },
      { rows_kept => { source => 'Child', find => { id => 1 }, is => { parent_code => 'p1' } } },
      { rejects => { source => 'Child', create => { id => 2, parent_code => 'nobody' } } },
    ],
  },

  {
    name  => 'diff-constraint-changed',
    since => 1,
    cards => [ 'dbio-sqlite k72', 'dbio-postgresql k101', 'dbio-firebird k34',
               'dbio-oracle k37' ],
    subject => { source => 'Child', column => 'code' },
    input => {
      from => { sources => [
        $parent->(),
        {
          name => 'Child', table => 'child',
          columns => [
            id        => $id->(),
            parent_id => { data_type => 'integer', is_nullable => 0 },
            code      => { data_type => 'varchar', size => 20, is_nullable => 0 },
          ],
          primary_key   => [ 'id' ],
          relationships => [
            { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' },
          ],
        },
      ] },
      to => { sources => [
        $parent->(),
        {
          name => 'Child', table => 'child',
          columns => [
            id        => $id->(),
            parent_id => { data_type => 'integer', is_nullable => 0 },
            code      => { data_type => 'varchar', size => 20, is_nullable => 0 },
          ],
          primary_key   => [ 'id' ],
          unique        => [ [ child_code => [ 'code' ] ] ],
          relationships => [
            { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' },
          ],
        },
      ] },
      rows => [
        { source => 'Parent', values => { id => 1 } },
        { source => 'Child',  values => { id => 1, parent_id => 1, code => 'c1' } },
      ],
    },
    expect => [
      { fact => { name => 'unique_exists', source => 'Child', columns => [ 'code' ], is => 1 } },
      { rows_kept => { source => 'Child', find => { id => 1 }, is => { code => 'c1' } } },
      { rejects => { source => 'Child', create => { id => 2, parent_id => 1, code => 'c1' } } },
    ],
  },

  {
    name  => 'diff-fk-action-changed',
    since => 2,
    cards => [ 'dbio-sqlite k72', 'dbio-postgresql k101', 'dbio-firebird k34',
               'dbio-oracle k37' ],
    subject => { source => 'Child', column => 'parent_id' },
    input => {
      from => { sources => [
        $parent->(),
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
      to => { sources => [
        $parent->(),
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
      rows => [
        { source => 'Parent', values => { id => 1 } },
        { source => 'Child',  values => { id => 1, parent_id => 1 } },
      ],
    },
    expect => [
      { rows_kept => { source => 'Child', find => { id => 1 }, is => { parent_id => 1 } } },
      { cascade_delete => { parent => 'Parent', parent_values => { id => 2 },
                            child => 'Child', child_values => { id => 3 },
                            link => { parent_id => 'id' } } },
    ],
  },

  {
    name  => 'diff-ident-drop',
    since => 1,
    cards => [ 'dbio-postgresql k110', 'dbio-mysql k88' ],
    subject => { source => 'MixedCase' },
    input => {
      from => { sources => [
        { name => 'Anchor', table => 'anchor', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
        { name => 'MixedCase', table => 'MixedCase', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
        { name => 'Order', table => 'order', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
      ] },
      to => { sources => [
        { name => 'Anchor', table => 'anchor', columns => [ id => $id->() ],
          primary_key => [ 'id' ] },
      ] },
      rows => [ { source => 'Anchor', values => { id => 1 } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'MixedCase', is => undef } },
      { fact => { name => 'object_kind', source => 'Order', is => undef } },
      { fact => { name => 'object_kind', source => 'Anchor', is => 'table' } },
      { rows_kept => { source => 'Anchor', find => { id => 1 } } },
    ],
  },

  {
    name  => 'diff-not-null-over-nulls',
    since => 1,
    cards => [ 'dbio-clickhouse k32' ],
    subject => { source => 'Opt', column => 'c' },
    input => {
      from => { sources => [ {
        name => 'Opt', table => 'opt',
        columns => [
          id => $id->(),
          c  => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Opt', table => 'opt',
        columns => [
          id => $id->(),
          c  => { data_type => 'varchar', size => 20, is_nullable => 0 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [
        { source => 'Opt', values => { id => 1, c => undef } },
        { source => 'Opt', values => { id => 2, c => 'x' } },
      ],
    },
    expect => [
      { rows_kept => { source => 'Opt', find => { id => 2 }, is => { c => 'x' } } },
      { rejects => { source => 'Opt', create => { id => 3, c => undef } } },
    ],
  },

  {
    name  => 'diff-column-type-change',
    since => 1,
    cards => [ 'dbio-firebird k38' ],
    subject => { source => 'Num', column => 'n' },
    input => {
      from => { sources => [ {
        name => 'Num', table => 'num',
        columns => [
          id => $id->(),
          n  => { data_type => 'integer', is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Num', table => 'num',
        columns => [
          id => $id->(),
          n  => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [
        { source => 'Num', values => { id => 1, n => 5 } },
        { source => 'Num', values => { id => 2, n => 7 } },
      ],
    },
    expect => [
      { fact => { name => 'column_size', source => 'Num', column => 'n', is => 20 } },
      { rows_kept => { source => 'Num', find => { id => 1 }, is => { n => '5' } } },
      { rows_kept => { source => 'Num', find => { id => 2 }, is => { n => '7' } } },
      { read_back => { source => 'Num', create => { id => 3, n => 'abc' }, is => { n => 'abc' } } },
    ],
  },

  {
    name  => 'diff-table-with-dependent-view',
    since => 1,
    cards => [ 'dbio-sqlite k69' ],
    subject => { source => 'BaseView' },
    input => {
      from => { sources => [
        $base->(),
        $view->('SELECT {{id}}, {{name}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }),
      ] },
      to   => { sources => [
        $base->(more => [ extra => { data_type => 'varchar', size => 20, is_nullable => 1 } ]),
        $view->('SELECT {{id}}, {{name}} FROM {{base}}',
                id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 20 }),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'BaseView', is => 'view' } },
      { fact => { name => 'column_names', source => 'Base', is => [ 'extra', 'id', 'name' ] } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } },
      { search_by => { source => 'Base', create => { id => 2, name => 'y' },
                       through => 'BaseView', column => 'name', value => 'y' } },
    ],
  },

  {
    name  => 'diff-auto-increment-kept',
    since => 1,
    cards => [ 'dbio-mysql k93', 'dbio-db2 k45' ],
    subject => { source => 'Counter', column => 'id' },
    input => {
      from => { sources => [ {
        name => 'Counter', table => 'counter',
        columns => [
          id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
          name => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      to => { sources => [ {
        name => 'Counter', table => 'counter',
        columns => [
          id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
          name => { data_type => 'varchar', size => 40, is_nullable => 1 },
        ],
        primary_key => [ 'id' ],
      } ] },
      rows => [ { source => 'Counter', values => { name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'column_auto_increment', source => 'Counter', column => 'id', is => 1 } },
      { rows_kept => { source => 'Counter', find => { name => 'x' } } },
      { auto_key => { source => 'Counter', create => { name => 'y' } } },
    ],
  },

  {
    name  => 'diff-primary-key-order',
    since => 1,
    cards => [ 'dbio-sqlite k68' ],
    subject => { source => 'Pair' },
    input => {
      from => { sources => [ {
        name => 'Pair', table => 'pair',
        columns => [
          a => { data_type => 'integer', is_nullable => 0 },
          b => { data_type => 'integer', is_nullable => 0 },
        ],
        primary_key => [ 'b', 'a' ],
      } ] },
      to => { sources => [ {
        name => 'Pair', table => 'pair',
        columns => [
          a => { data_type => 'integer', is_nullable => 0 },
          b => { data_type => 'integer', is_nullable => 0 },
          c => { data_type => 'varchar', size => 20, is_nullable => 1 },
        ],
        primary_key => [ 'b', 'a' ],
      } ] },
      rows => [ { source => 'Pair', values => { a => 1, b => 2 } } ],
    },
    expect => [
      { fact => { name => 'primary_key_columns', source => 'Pair', is => [ 'b', 'a' ] } },
      { rows_kept => { source => 'Pair', find => { a => 1, b => 2 } } },
    ],
  },

  {
    name  => 'diff-deploy-inherited',
    since => 4,
    cards => [ 'dbio k399' ],
    subject => { source => 'Base' },
    input => {
      deploy => { check => 'inherited' },
      from => { sources => [ $base->() ] },
      to   => { sources => [
        $base->(more => [ extra => { data_type => 'integer', is_nullable => 1 } ]),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'column_names', source => 'Base', is => [ 'extra', 'id', 'name' ] } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } },
    ],
  },

  {
    name  => 'diff-deploy-dry-run',
    since => 4,
    cards => [ 'dbio k399' ],
    subject => { source => 'Base' },
    input => {
      deploy => {
        check     => 'dry_run',
        unchanged => [
          { fact => { name => 'column_names', source => 'Base', is => [ 'id', 'name' ] } },
        ],
      },
      from => { sources => [ $base->() ] },
      to   => { sources => [
        $base->(more => [ extra => { data_type => 'integer', is_nullable => 1 } ]),
      ] },
      rows => [ { source => 'Base', values => { id => 1, name => 'x' } } ],
    },
    expect => [
      { fact => { name => 'column_names', source => 'Base', is => [ 'extra', 'id', 'name' ] } },
      { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } },
    ],
  },

  {
    name  => 'diff-deploy-destructive-guard',
    since => 4,
    cards => [ 'dbio k399' ],
    subject => { source => 'Gone' },
    input => {
      deploy => {
        check     => 'guard',
        unchanged => [
          { fact => { name => 'object_kind', source => 'Gone', is => 'table' } },
          { fact => { name => 'column_names', source => 'Keep', is => [ 'id' ] } },
        ],
      },
      from => { sources => [
        { name => 'Keep', table => 'keep', columns => [ id => $id->() ], primary_key => [ 'id' ] },
        { name => 'Gone', table => 'gone', columns => [ id => $id->() ], primary_key => [ 'id' ] },
      ] },
      to => { sources => [
        { name => 'Keep', table => 'keep',
          columns => [ id => $id->(), extra => { data_type => 'integer', is_nullable => 1 } ],
          primary_key => [ 'id' ] },
      ] },
      rows => [ { source => 'Keep', values => { id => 1 } } ],
    },
    expect => [
      { fact => { name => 'object_kind', source => 'Gone', is => undef } },
      { fact => { name => 'column_names', source => 'Keep', is => [ 'extra', 'id' ] } },
      { rows_kept => { source => 'Keep', find => { id => 1 } } },
    ],
  },

);

sub cases {
  return Storable::dclone([ @CASES ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Conformance::Cases::Diff - The shared Diff cases every DBIO driver answers

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The Diff list of L<DBIO::Test::Conformance> (ADR 0060): twenty cases, U1 to
U17, U19 and U20 of the ADR's first case list with U13 as two cases, and three cases of the
deploy class (table version 4), as plain Perl data. A case is
two schema declarations in DBIO's own terms, C<from> and C<to>, the rows that
are in the tables when the upgrade runs, and what must be observable on the
server afterwards. It holds no SQL and no driver name.

A case is a hash:

  {
    name    => 'diff-fk-dropped',                 # stable id, diff- prefix
    since   => 1,                                 # table version that added it
    cards   => [ 'dbio-mysql k94' ],              # where it came from; documentation
    subject => { source => 'Child', column => 'parent_id' },   # optional
    input   => {
      from => { sources => [ { ... }, ... ] },
      to   => { sources => [ { ... }, ... ] },
      rows => [ { source => 'Parent', values => { id => 1 } }, ... ],
    },
    expect  => [ { foreign_key_count => ... }, ... ],
  }

The runner installs C<from>, creates C<rows> in order through the data seams,
upgrades to C<to> and checks C<expect> against the upgraded database. The
sources are written as in L<DBIO::Test::Conformance::Cases::DDL>; a source
keeps its moniker across C<from> and C<to> and is told apart by C<name>.
C<subject> is the object a refusal must name (the table of C<source> and,
when given, the C<column>); without it the first source of C<to>. Every case
is also held to the second postcondition of the ADR: after the upgrade, a
diff against C<to> is empty.

The expectation is always a property of the server, never SQL text. Where the
ADR says "applied or refused" (U5, U6, U13, U15, U16; for U13 both of its cases), the case is written for
the applied outcome; a driver that refuses declares that in
C<conformance_refusals> like any other refusal. The order is the order of the
ADR appendix. Names never change once published; a case that turns out wrong
is replaced by a new one with a higher C<since>: the case U10 is C<diff-indexed-column-dropped> (C<since> 3), the Diff list is at table version 4.

=head2 The deploy cases

Three cases (C<since> 4, C<diff-deploy-*>) are about the deploy class of the
driver and carry C<< input.deploy >>, a hash with the C<check> and, where the
case needs it, C<unchanged>, expectations that hold after the call that must
not have changed anything:

=over 4

=item C<diff-deploy-inherited>

The deploy class inherits C<apply> and C<upgrade> from
L<DBIO::Deploy::Base> (the same code reference); a driver takes part through
the hooks C<_check_before_apply> and C<_execute_diff>. Then C<upgrade> brings
the database to C<to>.

=item C<diff-deploy-dry-run>

C<< apply($diff, dry_run =E<gt> 1) >> returns the diff and executes nothing
(C<unchanged>). Then C<upgrade> brings the database to C<to>.

=item C<diff-deploy-destructive-guard>

A diff that drops a table throws a L<DBIO::Exception> naming
C<allow_destructive> before the first statement (C<unchanged>: the table is
there, the additive change did not run), and runs with
C<< allow_destructive =E<gt> 1 >>.

=back

The runner drives them through L<DBIO::Test::Conformance/conformance_deploy>;
a driver without that seam answers them C<na>.

=head2 Not in the list

=over 4

=item U18 C<diff-table-with-generated-column>

A generated column is declared with SQL of the engine; DBIO has no
engine-neutral way to write it, so the case is a driver-local one.

=item the check-constraint part of U13

U13 names three changes, a unique constraint, C<on_delete> and a check
constraint. A result source has no neutral declaration for a check, so the
list holds the first two, each as a case of its own: C<diff-constraint-changed>
(the unique constraint, subject C<Child.code>) and C<diff-fk-action-changed>
(C<on_delete>, subject C<Child.parent_id>, C<since> 2).

=back

=head1 METHODS

=head2 cases

  my $cases = DBIO::Test::Conformance::Cases::Diff->cases;

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
