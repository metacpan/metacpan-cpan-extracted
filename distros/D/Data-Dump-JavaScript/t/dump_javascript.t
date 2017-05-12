use strict;
use warnings;
use Test::More;
use Encode qw( decode );
use Data::Dump::JavaScript qw( dump_javascript true false );

# Encode array
my $bytes = dump_javascript [];
is $bytes, '[]', 'encode []';
$bytes = dump_javascript [[]];
is $bytes, '[[]]', 'encode [[]]';
$bytes = dump_javascript [[], []];
is $bytes, '[
  [],
  []
]', 'encode [[], []]';
$bytes = dump_javascript [[], [[]], []];
is $bytes, '[
  [],
  [[]],
  []
]', 'encode [[], [[]], []]';

# Encode string
$bytes = dump_javascript ['foo'];
is $bytes, "['foo']", 'encode [\'foo\']';
$bytes = dump_javascript ["hello\nworld!"];
is $bytes, '[\'hello\nworld!\']', 'encode [\'hello\nworld!\']';
$bytes = dump_javascript ["hello\t\"world!"];
is $bytes, '[\'hello\t\"world!\']', 'encode [\'hello\t\"world!\']';
$bytes = dump_javascript ["hello\x{0003}\x{0152}world\x{0152}!"];
is decode('UTF-8', $bytes), "['hello\\u0003\x{0152}world\x{0152}!']",
  'encode [\'hello\x{0003}\x{0152}world\x{0152}!\']';
$bytes = dump_javascript ["123abc"];
is $bytes, "['123abc']", "encode ['123abc']";
$bytes = dump_javascript ["\x00\x1f \a\b/\f\r"];
is $bytes, '[\'\\u0000\\u001F \\u0007\\b\/\f\r\']',
  'encode ["\x00\x1f \a\b/\f\r"]';
$bytes = dump_javascript '';
is $bytes, "''", "encode ''";
$bytes = dump_javascript "hell\no";
is $bytes, '\'hell\no\'', 'encode \'hell\no\'';

# Encode object
$bytes = dump_javascript {};
is $bytes, '{}', 'encode {}';
$bytes = dump_javascript {foo => {}};
is $bytes, '{
  foo: {}
}', 'encode {foo => {}}';
$bytes = dump_javascript {foo => 'bar'};
is $bytes, "{
  foo: 'bar'
}", 'encode {foo => \'bar\'}';
$bytes = dump_javascript {foo => []};
is $bytes, '{
  foo: []
}', 'encode {foo => []}';
$bytes = dump_javascript {foo => ['bar']};
is $bytes, "{
  foo: ['bar']
}", 'encode {foo => [\'bar\']}';
$bytes = dump_javascript {foo => 'bar', baz => 'yada'};
is $bytes, "{
  baz: 'yada',
  foo: 'bar'
}",
  'encode {foo => \'bar\', baz => \'yada\'}';

is dump_javascript({ foo => undef }), '{
  foo: null
}', 'encode {foo => undef}';

# Encode name
$bytes = dump_javascript [true];
is $bytes, '[true]', 'encode [true]';
$bytes = dump_javascript [undef];
is $bytes, '[null]', 'encode [undef]';
$bytes = dump_javascript [true, false];
is $bytes, '[
  true,
  false
]', 'encode [true, false]';
$bytes = dump_javascript(true);
is $bytes, 'true', 'encode true';
$bytes = dump_javascript(false);
is $bytes, 'false', 'encode false';
$bytes = dump_javascript undef;
is $bytes, 'null', 'encode undef';

# Encode number
$bytes = dump_javascript [1];
is $bytes, '[1]', 'encode [1]';
$bytes = dump_javascript ['1'];
is $bytes, "['1']", "encode ['1']";
$bytes = dump_javascript ['-122.026020'];
is $bytes, "['-122.026020']", 'encode [\'-122.026020\']';
$bytes = dump_javascript [-122.026020];
is $bytes, '[-122.02602]', 'encode [-122.026020]';
$bytes = dump_javascript [1, -2];
is $bytes, '[
  1,
  -2
]', 'encode [1, -2]';
$bytes = dump_javascript ['10e12', [2]];
is $bytes, "[
  '10e12',
  [2]
]", 'encode [\'10e12\', [2]]';
$bytes = dump_javascript [10e12, [2]];
is $bytes, '[
  10000000000000,
  [2]
]', 'encode [10e12, [2]]';
$bytes = dump_javascript [37.7668, [20]];
is $bytes, '[
  37.7668,
  [20]
]', 'encode [37.7668, [20]]';
$bytes = dump_javascript 0;
is $bytes, '0', 'encode 0';
$bytes = dump_javascript 23.3;
is $bytes, '23.3', 'encode 23.3';

done_testing;
