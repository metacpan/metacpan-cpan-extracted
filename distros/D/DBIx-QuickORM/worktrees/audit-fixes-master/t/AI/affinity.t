use Test2::V0 '!meta', '!pass';

# Pure-function tests for DBIx::QuickORM::Affinity. No database needed.
#
# These also assert the documented behavior from the EXPORTS POD in
# DBIx::QuickORM::Affinity and the AFFINITY section of
# DBIx::QuickORM::Manual::Concepts (the four valid affinities are
# string, numeric, boolean, binary).

use DBIx::QuickORM::Affinity;

subtest exports => sub {
    # All four functions are exported by default.
    can_ok(__PACKAGE__, [qw/valid_affinities validate_affinity compare_affinity_values affinity_from_type/], "default exports present");
};

subtest valid_affinities => sub {
    my @all = valid_affinities();

    # Concepts manual AFFINITY section documents exactly these four.
    is(
        [@all],
        [qw/binary boolean numeric string/],
        "sorted, de-duplicated list of the four documented affinities",
    );

    # Stable / sorted regardless of how the map is iterated.
    is([valid_affinities()], [@all], "stable across calls");
};

subtest validate_affinity => sub {
    is(validate_affinity('string'),  'string',  "valid affinity returns itself");
    is(validate_affinity('numeric'), 'numeric', "numeric is valid");
    is(validate_affinity('boolean'), 'boolean', "boolean is valid");
    is(validate_affinity('binary'),  'binary',  "binary is valid");

    is(validate_affinity('bogus'), undef, "unknown affinity returns nothing");
    is(validate_affinity(''),      undef, "empty string returns nothing");
    is(validate_affinity(),        undef, "no args returns nothing");
    is(validate_affinity(undef),   undef, "undef returns nothing");
};

subtest affinity_from_type => sub {
    # Stringy
    is(affinity_from_type('char'),   'string', "char -> string");
    is(affinity_from_type('text'),   'string', "text -> string");
    is(affinity_from_type('json'),   'string', "json -> string");
    is(affinity_from_type('bpchar'), 'string', "bpchar -> string");

    # Special stringy
    is(affinity_from_type('uuid'),  'string', "uuid -> string");
    is(affinity_from_type('jsonb'), 'string', "jsonb -> string");
    is(affinity_from_type('money'), 'string', "money -> string");
    is(affinity_from_type('enum'),  'string', "enum -> string");
    is(affinity_from_type('set'),   'string', "set -> string");

    # Binary
    is(affinity_from_type('binary'), 'binary', "binary -> binary");
    is(affinity_from_type('blob'),   'binary', "blob -> binary");
    is(affinity_from_type('bytea'),  'binary', "bytea -> binary");

    # Numeric
    is(affinity_from_type('int'),              'numeric', "int -> numeric");
    is(affinity_from_type('integer'),          'numeric', "integer -> numeric");
    is(affinity_from_type('numeric'),          'numeric', "numeric -> numeric");
    is(affinity_from_type('decimal'),          'numeric', "decimal -> numeric");
    is(affinity_from_type('float'),            'numeric', "float -> numeric");
    is(affinity_from_type('real'),             'numeric', "real -> numeric");
    is(affinity_from_type('serial'),           'numeric', "serial -> numeric");
    is(affinity_from_type('double precision'), 'numeric', "multi-word 'double precision' -> numeric");
    is(affinity_from_type('smallint'),         'numeric', "smallint -> numeric");
    is(affinity_from_type('int2'),             'numeric', "int2 -> numeric");
    is(affinity_from_type('int4'),             'numeric', "int4 -> numeric");
    is(affinity_from_type('int8'),             'numeric', "int8 -> numeric");
    is(affinity_from_type('float4'),           'numeric', "float4 -> numeric");
    is(affinity_from_type('float8'),           'numeric', "float8 -> numeric");
    is(affinity_from_type('hugeint'),          'numeric', "hugeint -> numeric");
    is(affinity_from_type('utinyint'),         'numeric', "utinyint -> numeric");
    is(affinity_from_type('usmallint'),        'numeric', "usmallint -> numeric");
    is(affinity_from_type('uinteger'),         'numeric', "uinteger -> numeric");
    is(affinity_from_type('ubigint'),          'numeric', "ubigint -> numeric");
    is(affinity_from_type('uhugeint'),         'numeric', "uhugeint -> numeric");

    # Date/Time map to string per the internal table.
    is(affinity_from_type('date'),        'string', "date -> string");
    is(affinity_from_type('timestamp'),   'string', "timestamp -> string");
    is(affinity_from_type('timestamptz'), 'string', "timestamptz -> string");

    # Boolean
    is(affinity_from_type('bool'),    'boolean', "bool -> boolean");
    is(affinity_from_type('boolean'), 'boolean', "boolean -> boolean");

    subtest case_and_size_normalization => sub {
        is(affinity_from_type('VARCHAR(255)'), 'string',  "upper-case + parenthesized size stripped");
        is(affinity_from_type('INT(11)'),      'numeric', "INT(11) -> numeric");
        is(affinity_from_type('DECIMAL(10,2)'),'numeric', "DECIMAL(10,2) -> numeric");
        is(affinity_from_type('Text'),         'string',  "mixed case -> string");
        is(affinity_from_type('char (5)'),     'string',  "whitespace adjacent to size group stripped");

        # Surrounding whitespace on the type name is trimmed.
        is(affinity_from_type('char '),  'string', "trailing whitespace trimmed -> string");
        is(affinity_from_type(' char'),  'string', "leading whitespace trimmed -> string");
        is(affinity_from_type('  char  '), 'string', "surrounding whitespace trimmed -> string");
    };

    subtest prefix_resolution => sub {
        # tiny/medium/big/long/var prefixes resolve to the suffix type.
        is(affinity_from_type('tinyint'),    'numeric', "tinyint -> numeric (int)");
        is(affinity_from_type('bigint'),     'numeric', "bigint -> numeric (int)");
        is(affinity_from_type('mediumint'),  'numeric', "mediumint -> numeric (int)");
        is(affinity_from_type('varchar'),    'string',  "varchar -> string (char)");
        is(affinity_from_type('longtext'),   'string',  "longtext -> string (text)");
        is(affinity_from_type('mediumblob'), 'binary',  "mediumblob -> binary (blob)");
        is(affinity_from_type('varbinary'),  'binary',  "varbinary -> binary (binary)");
        is(affinity_from_type('TINYINT'),    'numeric', "prefix match is case-insensitive");
    };

    subtest unknown_and_empty => sub {
        is(affinity_from_type('frobnicate'), undef, "unknown type -> undef");
        is(affinity_from_type(''),           undef, "empty string -> undef");
        is(affinity_from_type(),             undef, "no args -> undef");
        is(affinity_from_type(0),            undef, "false-but-defined '0' -> undef (treated as no type)");

        # A bare prefix with no resolvable suffix falls through to undef.
        is(affinity_from_type('var'), undef, "bare 'var' (prefix only) -> undef");
    };
};

subtest compare_affinity_values => sub {
    # POD: returns true when the two values are considered equal.

    subtest string => sub {
        ok(compare_affinity_values('string', 'a', 'a'),  "equal strings -> true");
        ok(!compare_affinity_values('string', 'a', 'b'), "different strings -> false");
        ok(compare_affinity_values('string', undef, undef), "both undef -> equal (true)");
        ok(!compare_affinity_values('string', 'a', undef),  "defined vs undef -> false");
        ok(!compare_affinity_values('string', undef, 'b'),  "undef vs defined -> false");
    };

    subtest numeric => sub {
        ok(compare_affinity_values('numeric', 1, 1.0),  "1 == 1.0 numerically -> true");
        ok(compare_affinity_values('numeric', '1', 1),  "string '1' == 1 numerically -> true");
        ok(!compare_affinity_values('numeric', 1, 2),   "1 != 2 -> false");
        ok(compare_affinity_values('numeric', undef, undef), "both undef -> equal (true)");
        ok(!compare_affinity_values('numeric', 1, undef),    "defined vs undef -> false");
    };

    subtest binary => sub {
        ok(compare_affinity_values('binary', "\x00\x01", "\x00\x01"),  "equal bytes -> true");
        ok(!compare_affinity_values('binary', "\x00", "\x01"),         "different bytes -> false");
        ok(compare_affinity_values('binary', undef, undef),            "both undef -> equal (true)");
        ok(!compare_affinity_values('binary', "\x00", undef),          "defined vs undef -> false");
    };

    subtest boolean => sub {
        # POD: for boolean, undef is treated as false. Per the comparison
        # contract (true == equal), agreeing truthiness compares equal.
        ok(compare_affinity_values('boolean', 1, 1),  "true,true -> equal (true)");
        ok(compare_affinity_values('boolean', 0, 0),  "false,false -> equal (true)");
        ok(!compare_affinity_values('boolean', 1, 0), "true,false -> not equal (false)");
        ok(!compare_affinity_values('boolean', 0, 1), "false,true -> not equal (false)");

        # undef counts as false for boolean.
        ok(compare_affinity_values('boolean', undef, 0),     "undef == false -> equal (true)");
        ok(compare_affinity_values('boolean', undef, undef), "undef == undef -> equal (true)");
        ok(!compare_affinity_values('boolean', undef, 1),    "undef vs true -> not equal (false)");
        ok(!compare_affinity_values('boolean', 1, undef),    "true vs undef -> not equal (false)");
    };

    subtest errors => sub {
        like(
            dies { compare_affinity_values(undef, 1, 1) },
            qr/'affinity' is required/,
            "missing affinity croaks",
        );
        like(
            dies { compare_affinity_values('bogus', 1, 1) },
            qr/'bogus' is not a valid affinity/,
            "invalid affinity croaks",
        );
    };
};

subtest declared_type_affinity_names => sub {
    # Regression: user-declared scalar-ref SQL types the audit named must
    # resolve to an affinity instead of returning undef (which croaks at
    # Column->affinity).
    is(affinity_from_type('datetime'),              'string',  "datetime => string");
    is(affinity_from_type('character'),             'string',  "character => string");
    is(affinity_from_type('character varying'),     'string',  "character varying => string");
    is(affinity_from_type('character varying(50)'), 'string',  "sized character varying => string");
    is(affinity_from_type('smallserial'),           'numeric', "smallserial => numeric");
};

done_testing;
