use Test2::V1
  -target => { CLASS => 'Data::Table::Gherkin' },
  -pragmas,
  qw( is isa_ok like note plan subtest warning );
plan 6;

subtest 'Improper Gherkin data table' => sub {
  plan 10;

  like warning { is CLASS->parse( <<'GDT' ), undef, 'Return no object' },
Annie M. G. | Schmidt  | 1911-05-20 |
GDT
    qr/\AWrong start of row \(row number 1\)/, 'Wrong start of row';
  like warning { is CLASS->parse( <<'GDT', { has_header => 1 } ), undef, 'Return no object' },
firstName   | lastName | birthDate  |
GDT
    qr/\AWrong start of row \(row number 0\)/, 'Wrong start of row';
  like warning { is CLASS->parse( <<'GDT', { has_header => 1 } ), undef, 'Return no object' },
|firstName   | lastName | firstName  |
GDT
    qr/\AColumn headers are not unique \(row number 0\)/, 'Wrong header row';
  like warning { is CLASS->parse( <<'GDT' ), undef, 'Return no object' },
| Annie M. G. | Schmidt  | 1911-05-20 |
| Roald       | Dahl     | 1916-09-13
GDT
    qr/\AWrong end of row \(row number 2\)/, 'Wrong end of row';
  like warning { is CLASS->parse( <<'GDT' ), undef, 'Return no object' },
| Annie M. G. | Schmidt  | 1911-05-20 |
| Roald       | Dahl     | 1916-09-13 |
| Astrid      | Lindgren |
GDT
    qr/\AWrong number of columns in row \(row number 3\)/, 'Wrong column number'
};

subtest 'Minimal Gherkin data table' => sub {
  plan 4;

  my $self = CLASS->parse( <<'GDT' );
||
GDT

  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    1,          'Number of rows';
  is $self->no_columns, 1,          'Number of columns';
  is $self->rows,       [ [ '' ] ], 'Get rows'
};

subtest 'Gherkin data table without header' => sub {
  plan 4;

  my $self = CLASS->parse( <<'GDT' );
| Annie M. G. | Schmidt  | 1911-05-20 |
| Roald       | Dahl     | 1916-09-13 |
| Astrid      | Lindgren | 1907-11-14 |
GDT

  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    3, 'Number of rows';
  is $self->no_columns, 3, 'Number of columns';
  is $self->rows,
    [
    [ 'Annie M. G.', 'Schmidt',  '1911-05-20' ],
    [ 'Roald',       'Dahl',     '1916-09-13' ],
    [ 'Astrid',      'Lindgren', '1907-11-14' ]
    ],
    'Get rows'
};

subtest 'Gherkin data table with header' => sub {
  plan 4;

  my $self = CLASS->parse( <<'GDT', { has_header => 1 } );
| firstName   | lastName | birthDate  |
| Annie M. G. | Schmidt  | 1911-05-20 |
| Roald       | Dahl     | 1916-09-13 |
| Astrid      | Lindgren | 1907-11-14 |
GDT

  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    3, 'Number of rows';
  is $self->no_columns, 3, 'Number of columns';
  is $self->rows,
    [
    { firstName => 'Annie M. G.', lastName => 'Schmidt',  birthDate => '1911-05-20' },
    { firstName => 'Roald',       lastName => 'Dahl',     birthDate => '1916-09-13' },
    { firstName => 'Astrid',      lastName => 'Lindgren', birthDate => '1907-11-14' }
    ],
    'Get rows'
};

subtest 'How to escape and unescape pipe, newline, and backslash' => sub {
  plan 4;

  my $self = CLASS->parse( <<'GDT' );
|part 1 | part 2 \| still\npart 2 | part 3 \\| part 4 |
GDT
  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    1,                                                                 'Number of rows';
  is $self->no_columns, 4,                                                                 'Number of columns';
  is $self->rows,       [ [ 'part 1', "part 2 | still\npart 2", 'part 3 \\', 'part 4' ] ], 'Get rows'
};

subtest 'Gherkin data tables read from filehandle in paragraph mode' => sub {
  plan 8;

  my $self = CLASS->parse( \*DATA );
  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    3, 'Number of rows';
  is $self->no_columns, 3, 'Number of columns';
  is $self->rows,
    [
    [ 'Annie M. G.', 'Schmidt',  '1911-05-20' ],
    [ 'Roald',       'Dahl',     '1916-09-13' ],
    [ 'Astrid',      'Lindgren', '1907-11-14' ]
    ],
    'Get rows';

  $self = CLASS->parse( \*DATA, { has_header => 1 } );
  isa_ok $self, [ CLASS ], 'Create object';
  is $self->no_rows,    3, 'Number of rows';
  is $self->no_columns, 2, 'Number of columns';
  is $self->rows,
    [ { item => 'book', price => 500 }, { item => 'sharpener', price => 30 }, { item => 'pencil', price => 15 } ],
    'Get rows'
}

__DATA__
| Annie M. G. | Schmidt  | 1911-05-20 |
| Roald       | Dahl     | 1916-09-13 |
| Astrid      | Lindgren | 1907-11-14 |

| item      | price |
| book      | 500   |
| sharpener | 30    |
| pencil    | 15    |
