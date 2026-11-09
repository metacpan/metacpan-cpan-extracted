package TypeModifierCases;

# The declarations t/97-ddl-type-modifier.t and t/98-ddl-type-modifier-live.t
# share (karr k116): a column's data_type and size, the type install_ddl has
# to write for it, and the type the server reads back for that
# (pg_catalog.format_type, measured on PostgreSQL 18.6).
#
# One table for both, so that what the offline test pins as written is exactly
# what the live test hands to a server.

use strict;
use warnings;

# [ data_type, size, written by install_ddl, read back by format_type ]

# The table of karr k116, row for row. Each of these came out without its
# size: a character(10) column that held one character, a bit(8) that held
# one bit, a decimal(10,2) without bound or scale, time and timestamp columns
# at the default precision, a bit varying without its limit.
sub card {
  return (
    [ 'character',   10,        'character(10)',  'character(10)' ],
    [ 'bit',         8,         'bit(8)',         'bit(8)' ],
    [ 'decimal',     [ 10, 2 ], 'decimal(10,2)',  'numeric(10,2)' ],
    [ 'timestamp',   3,         'timestamptz(3)', 'timestamp(3) with time zone' ],
    [ 'time',        0,         'time(0)',        'time(0) without time zone' ],
    [ 'varbit',      8,         'varbit(8)',      'bit varying(8)' ],
    [ 'bit varying', 8,         'bit varying(8)', 'bit varying(8)' ],
  );
}

# Every other name a built-in type with a type modifier can be declared
# under, and the pgvector types. The types are the ten of pg_type.typmodin;
# the names are the ones the grammar and the catalog know them by.
sub synonyms {
  return (
    # character(n)
    [ 'char',                        10,        'character(10)',                  'character(10)' ],
    [ 'bpchar',                      10,        'bpchar(10)',                     'character(10)' ],
    [ 'nchar',                       10,        'nchar(10)',                      'character(10)' ],
    [ 'national character',          10,        'national character(10)',         'character(10)' ],
    [ 'national char',               10,        'national char(10)',              'character(10)' ],
    # character varying(n)
    [ 'character varying',           10,        'character varying(10)',          'character varying(10)' ],
    [ 'varchar',                     10,        'character varying(10)',          'character varying(10)' ],
    [ 'char varying',                10,        'char varying(10)',               'character varying(10)' ],
    [ 'nchar varying',               10,        'nchar varying(10)',              'character varying(10)' ],
    [ 'national character varying',  10,        'national character varying(10)', 'character varying(10)' ],
    [ 'national char varying',       10,        'national char varying(10)',      'character varying(10)' ],
    # numeric(p) / numeric(p,s): a scalar is the precision
    [ 'numeric',                     [ 10, 2 ], 'numeric(10,2)',                  'numeric(10,2)' ],
    [ 'numeric',                     10,        'numeric(10)',                    'numeric(10,0)' ],
    [ 'numeric',                     [ 10 ],    'numeric(10)',                    'numeric(10,0)' ],
    [ 'decimal',                     10,        'decimal(10)',                    'numeric(10,0)' ],
    [ 'dec',                         [ 10, 2 ], 'dec(10,2)',                      'numeric(10,2)' ],
    [ 'dec',                         10,        'dec(10)',                        'numeric(10,0)' ],
    # time(p): the modifier stands behind the first word
    [ 'time',                        3,         'time(3)',                        'time(3) without time zone' ],
    [ 'time without time zone',      3,         'time(3) without time zone',      'time(3) without time zone' ],
    [ 'timetz',                      3,         'timetz(3)',                      'time(3) with time zone' ],
    [ 'time with time zone',         3,         'time(3) with time zone',         'time(3) with time zone' ],
    # timestamp(p): likewise
    [ 'timestamp without time zone', 3,         'timestamp(3) without time zone', 'timestamp(3) without time zone' ],
    [ 'timestamptz',                 3,         'timestamp(3) with time zone',    'timestamp(3) with time zone' ],
    [ 'timestamp with time zone',    3,         'timestamp(3) with time zone',    'timestamp(3) with time zone' ],
    [ 'timestamp',                   [ 6 ],     'timestamptz(6)',                 'timestamp(6) with time zone' ],
    # interval(p), and the field forms that end in the seconds
    [ 'interval',                    3,         'interval(3)',                    'interval(3)' ],
    [ 'interval',                    [ 0 ],     'interval(0)',                    'interval(0)' ],
    [ 'interval second',             3,         'interval second(3)',             'interval second(3)' ],
    [ 'interval day to second',      3,         'interval day to second(3)',      'interval day to second(3)' ],
    [ 'interval hour to second',     3,         'interval hour to second(3)',     'interval hour to second(3)' ],
    [ 'interval minute to second',   3,         'interval minute to second(3)',   'interval minute to second(3)' ],
    # a name is a name in any case, and with any space between its words
    [ 'VARCHAR',                     255,       'VARCHAR(255)',                   'character varying(255)' ],
    [ 'Timestamp  With Time Zone',   3,         'Timestamp(3)  With Time Zone',   'timestamp(3) with time zone' ],
    [ 'Bit Varying',                 8,         'Bit Varying(8)',                 'bit varying(8)' ],
  );
}

# pgvector: these already took their size (karr k56, k58) and still do.
sub pgvector {
  return (
    [ 'vector',    3, 'vector(3)',    'vector(3)' ],
    [ 'halfvec',   3, 'halfvec(3)',   'halfvec(3)' ],
    [ 'sparsevec', 3, 'sparsevec(3)', 'sparsevec(3)' ],
  );
}

# The same types without a size: nothing is added.
sub unsized {
  return (
    [ 'character',                undef, 'character',                'character(1)' ],
    [ 'bit',                      undef, 'bit',                      'bit(1)' ],
    [ 'bit varying',              undef, 'bit varying',              'bit varying' ],
    [ 'varbit',                   undef, 'varbit',                   'bit varying' ],
    [ 'varchar',                  undef, 'character varying',        'character varying' ],
    [ 'numeric',                  undef, 'numeric',                  'numeric' ],
    [ 'decimal',                  undef, 'decimal',                  'numeric' ],
    [ 'time',                     undef, 'time',                     'time without time zone' ],
    [ 'timestamp',                undef, 'timestamptz',              'timestamp with time zone' ],
    [ 'timestamp with time zone', undef, 'timestamp with time zone', 'timestamp with time zone' ],
    [ 'interval',                 undef, 'interval',                 'interval' ],
    [ 'numeric',                  [],    'numeric',                  'numeric' ],
    [ 'bit varying',              [],    'bit varying',              'bit varying' ],
  );
}

# Types without a type modifier: a size is not written, as before. The
# server takes none of these with one -- integer(11) is a syntax error,
# text(255) "type modifier is not allowed" -- and data_type => 'integer',
# size => 11 is what a schema carried over from DBIx::Class or generated from
# MySQL is full of. Such a schema deploys today and has to go on deploying.
sub without_modifier {
  return (
    [ 'integer',          11,       'bigint',           'bigint' ],
    [ 'int',              11,       'int',              'integer' ],
    [ 'bigint',           20,       'bigint',           'bigint' ],
    [ 'smallint',         6,        'smallint',         'smallint' ],
    [ 'text',             255,      'text',             'text' ],
    [ 'boolean',          1,        'boolean',          'boolean' ],
    [ 'uuid',             36,       'uuid',             'uuid' ],
    [ 'date',             10,       'date',             'date' ],
    [ 'jsonb',            1,        'jsonb',            'jsonb' ],
    [ 'bytea',            255,      'bytea',            'bytea' ],
    [ 'blob',             65535,    'bytea',            'bytea' ],
    [ 'real',             24,       'real',             'real' ],
    [ 'double',           53,       'double precision', 'double precision' ],
    [ 'double precision', 53,       'double precision', 'double precision' ],
    [ 'float',            [ 8, 2 ], 'double precision', 'double precision' ],
    [ 'money',            19,       'money',            'money' ],
    [ 'inet',             4,        'inet',             'inet' ],
  );
}

# A type this distribution does not know: an extension's, or a domain. Its
# size is left out as well. That is the behaviour as it was found, not a
# decision (karr k116): such a type may take a modifier -- PostGIS's geometry
# does -- or may not, and nothing here can tell.
sub unknown {
  return (
    [ 'citext',   10,                'citext' ],
    [ 'geometry', [ 'Point', 4326 ], 'geometry' ],
  );
}

1;
