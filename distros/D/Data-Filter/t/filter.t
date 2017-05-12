#!/usr/local/bin/perl

use Test::More tests => 26;
use File::Basename;
use warnings;
use strict;

chdir ( dirname ( $0 ) );

use lib qw(../lib lib);

use Data::Filter;

my $dataSet = arrayToHash ( [
  {
    name  => 'Jane',
    age   => '22',
  },
  {
    name  => 'Matt',
    age   => '24',
  },
  {
    name  => 'Andy',
    age   => '29',
  },
  {
    name  => 'Tim',
    age   => '30',
  },
  {
    name  => 'Jamie',
    age   => '25',
  },
] );

my $tests = {
  
  # simple equals
  'equal' => {
    'filter'    => [
      'eq',
      'name',
      'Matt',
    ],
    'expected'  => [
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },
  
  # simple equals
  'equal (numeric)' => {
    'filter'    => [
      '==',
      'age',
      24,
    ],
    'expected'  => [
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },
  
  # simple not-equals
  'not-equal' => {
    'filter'    => [
      'ne',
      'name',
      'Matt',
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },
  
  # simple not-equals
  'not-equal (numeric)' => {
    'filter'    => [
      '!=',
      'age',
      24,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # simple regex
  'regex' => {
    'filter'    => [
      're',
      'name',
      'a',
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  'regex (2)' => {
    'filter'    => [
      '=~',
      'name',
      'a',
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },
  
  # simple not-regex
  'not-regex' => {
    'filter'    => [
      'nre',
      'name',
      'a',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
    ],
  },

  'not-regex (2)' => {
    'filter'    => [
      '!~',
      'name',
      'a',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
    ],
  },

  # simple less-than
  'less-than (numeric)' => {
    'filter'    => [
      '<',
      'age',
      25,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },

  # simple less-than-or-equal
  'less-than-or-equal (numeric)' => {
    'filter'    => [
      '<=',
      'age',
      25,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # simple less-than
  'less-than' => {
    'filter'    => [
      'lt',
      'age',
      25,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },

  'less-than-or-equal' => {
    'filter'    => [
      'le',
      'age',
      25,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # simple greater-than
  'greater-than (numeric)' => {
    'filter'    => [
      '>',
      'age',
      '25',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
    ],
  },

  'greater-than-or-equal (numeric)' => {
    'filter'    => [
      '>=',
      'age',
      '25',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # simple greater-than
  'greater-than' => {
    'filter'    => [
      'gt',
      'age',
      '25',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
    ],
  },

  'greater-than-or-equal' => {
    'filter'    => [
      'ge',
      'age',
      '25',
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Tim',
        age   => '30',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # more complex
  'NOT ( less-then OR greater-than )' => {
    'filter'    => [
      Data::Filter::OP_NOT,
      [
        Data::Filter::OP_OR,
        [
          '>',
          'age',
          '25',
        ],
        [
          '<',
          'age',
          '25',
        ],
      ],
    ],
    'expected'  => [
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },
  
  # a = b AND c = d
  'equal AND equal' => {
    'filter'    => [
      Data::Filter::OP_AND,
      [
        'eq',
        'name',
        'Matt',
      ],
      [
        '==',
        'age',
        24,
      ],
    ],
    'expected'  => [
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },
  
  # a = b AND c = d
  'equal OR equal' => {
    'filter'    => [
      Data::Filter::OP_OR,
      [
        'eq',
        'name',
        'Matt',
      ],
      [
        '==',
        'age',
        24,
      ],
    ],
    'expected'  => [
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },

  # less than
  'less than' => {
    'filter'    => [
      '<',
      'age',
      30,
    ],
    'expected'  => [
      {
        name  => 'Jane',
        age   => '22',
      },
      {
        name  => 'Matt',
        age   => '24',
      },
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # less than and greater than
  'less than AND greater than' => {
    'filter'    => [
      Data::Filter::OP_AND,
      [
        '<',
        'age',
        30,
      ],
      [
        '>',
        'age',
        24,
      ],
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # between
  'between' => {
    'filter'    => [
      'between',
      'age',
      25,
      29,
    ],
    'expected'  => [
      {
        name  => 'Andy',
        age   => '29',
      },
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },
  # less than and greater than AND equals
  '( less than AND greater than ) AND equal' => {
    'filter'    => [
      Data::Filter::OP_AND,
      [
        Data::Filter::OP_AND,
        [
          '<',
          'age',
          30,
        ],
        [
          '>',
          'age',
          24,
        ],
      ],
      [
        'eq',
        'name',
        'Jamie',
      ],
    ],
    'expected'  => [
      {
        name  => 'Jamie',
        age   => '25',
      },
    ],
  },

  # equal AND not-equal
  'equal AND not-equal' => {
    'filter'    => [
      Data::Filter::OP_AND,
      [
        'eq',
        'name',
        'Jamie',
      ],
      [
        'ne',
        'name',
        'Jamie',
      ],
    ],
    'expected'  => [
    ],
  },

  # equal AND not ( equal )
  'equal AND NOT ( equal )' => {
    'filter'    => [
      Data::Filter::OP_AND,
      [
        'eq',
        'name',
        'Jamie',
      ],
      [
        Data::Filter::OP_NOT,
        [
          'eq',
          'name',
          'Jamie',
        ],
      ],
    ],
    'expected'  => [
    ],
  },

  # simple equals
  'NOT ( NOT ( equal ) )' => {
    'filter'    => [
      Data::Filter::OP_NOT,
      [
        Data::Filter::OP_NOT,
        [
          'eq',
          'name',
          'Matt',
        ],
      ],
    ],
    'expected'  => [
      {
        name  => 'Matt',
        age   => '24',
      },
    ],
  },
  
};

foreach my $test ( keys %$tests )
{
  my $filter = $tests->{ $test } { 'filter' };

  my $expected  = $tests->{ $test } { 'expected' };

  my $result = hashToArray ( filterData ( $dataSet, $filter ) );

  is_deeply ( $result, $expected, $test );
}
