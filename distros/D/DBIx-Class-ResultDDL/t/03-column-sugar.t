use Test2::V0;
no warnings 'once';
use Data::Dumper;
sub explain { Data::Dumper->new(\@_)->Indent(2)->Dump }

# Don't actually want to require this for the test, so mock it
$INC{'DBIx/Class/InflateColumn/Serializer.pm'}= 1;
eval 'package DBIx::Class::InflateColumn::Serializer; our $VERSION=-1;';

# test_col_defs $NAME, versions => \@VERSIONS, @COL_DEFS;
#    COL_DEF ::= [ $PERL_DECL, \%column_info ]
#            ||  { name => $COL_NAME, spec => $PERL_DECL, column_info => \%column_info }
#
# This utility function constructs a resultset with one column for each COL_DEF
# and then executes a subtest to verify that it compiles and that each column
# was created with the correct DBIC column_info.  The test is run for each
# of the ResultDDL versions listed in @VERSIONS.

my $test_n= 0;
sub test_col_defs {
	my $name= shift;
	my $default_versions= { map +($_ => 1), 0, 1 };
	my @col_tests;
	while (@_) {
		local $_= shift;
		if ($_ eq 'versions') {
			$default_versions= { map +($_ => 1), @{ shift() } };
		}
		if (ref eq 'ARRAY') {
			my ($spec, $column_info)= @$_;
			push @col_tests, { name => 'c'.@col_tests, spec => $spec, column_info => $column_info, versions => $default_versions };
		}
		elsif (ref eq 'HASH') {
			$_->{name} ||= 'c'.@col_tests;
			$_->{versions} ||= $default_versions;
			push @col_tests, $_;
		}
	}

	for my $ver (0..1) {
		my @cols= grep $_->{versions}{$ver}, @col_tests
			or next;
		subtest "$name v$ver" => sub {
			++$test_n;
			my $pkg= "test::Result$test_n";
			my $eval= <<___;
				package $pkg;
				use DBIx::Class::ResultDDL -V$ver;
				table "result$test_n";
___
			for (@cols) {
				$eval .= "col $_->{name} => $_->{spec};\n";
			}
			if( ok( eval($eval.'1'), "$name compiled" ) ) {
				for (@cols) {
					like $pkg->result_source_instance->column_info($_->{name}), $_->{column_info}, "$_->{spec}"
						or diag explain $pkg->column_info($_->{name});
				}
			} else {
				diag $eval;
				diag $@;
			}
		};
	}
}

test_col_defs(
	'numeric',
	versions => [0,1],
	[ 'integer',
		{ data_type => 'integer' }
	],
	[ 'integer, unsigned',
		{ data_type => 'integer', extra => { unsigned => 1 } }
	],
	[ 'tinyint',
		{ data_type => 'tinyint', size => 4 }
	],
	[ 'smallint',
		{ data_type => 'smallint', size => 6 }
	],
	[ 'bigint',
		{ data_type => 'bigint', size => 22 }
	],
	[ 'numeric(10,2)',
		{ data_type => 'numeric', size => [10,2] }
	],
	versions => [1],  # version 0 didn't allow numeric/decimal without precision
	[ 'numeric',
		{ data_type => 'numeric', size => DNE() }
	],
	[ 'numeric(4)',
		{ data_type => 'numeric', size => [4] }
	],
	[ 'numeric 4,3,[]',
		{ data_type => 'numeric[]', size => [4,3] }
	],
	[ 'float(10)',
		{ data_type => 'float', size => 10 }
	],
	[ 'float',
		{ data_type => 'float' }
	],
	[ 'float4',
		{ data_type => 'float4' }
	],
	[ 'double',
		{ data_type => 'double precision' }
	],
	[ 'float8',
		{ data_type => 'float8' }
	]
);

# Version 1 adds "auto_increment_type => monotonic" for SQLite
test_col_defs(
	'auto_inc',
	versions => [0],
	[ 'integer, auto_inc',
		{ data_type => 'integer', extra => DNE }
	],
	versions => [1],
	[ 'integer, auto_inc',
		{ data_type => 'integer', extra => { auto_increment_type => 'monotonic' } }
	]
);

test_col_defs(
	'char',
	versions => [0,1],
	[ 'char',
		{ data_type => 'char', size => 1, is_nullable => 0 }
	],
	[ 'char(50), null, default("foo")',
		{ data_type => 'char', size => 50, is_nullable => 1, default_value => 'foo' },
	],
	[ 'nchar',
		{ data_type => 'nchar', size => 1, is_nullable => 0 }
	],
	[ 'nchar(50)',
		{ data_type => 'nchar', size => 50 }
	],
	[ 'varchar(10)',
		{ data_type => 'varchar', size => 10, is_nullable => 0 }
	],
	[ 'nvarchar(10)',
		{ data_type => 'nvarchar', size => 10, is_nullable => 0 }
	],
	versions => [1],
	[ 'bit',
		{ data_type => 'bit', size => 1 }
	],
	[ 'char[]',
		{ data_type => 'char[]', size => 1 }
	],
	[ 'nvarchar(MAX)',
		{ data_type => 'nvarchar', size => 'MAX', is_nullable => 0 }
	],
	[ 'varbit',
		{ data_type => 'varbit', size => DNE }
	],
	[ 'varbit(20)',
		{ data_type => 'varbit', size => 20 }
	],
	[ 'varchar 3,[], null',
		{ data_type => 'varchar[]', size => 3, is_nullable => 1 }
	],
	[ 'uuid null',
		{ data_type => 'uuid', is_nullable => 1 }
	],
	{ name => 'uuid',
	  spec => 'uuid[]',
	  column_info => { data_type => 'uuid[]' }
	}
);

test_col_defs(
	'date',
	versions => [0,1],
	[ 'date',
		{ data_type => 'date' },
	],
	[ 'datetime("floating")',
		{ data_type => 'datetime', time_zone => 'floating' },
	],
	[ 'datetime("UTC")',
		{ data_type => 'datetime', time_zone => 'UTC' },
	],
);

subtest inflate_json => sub {
	skip_all('DBIx::Class::InflateColumn::Serializer is not available')
		unless eval 'require DBIx::Class::InflateColumn::Serializer';
	test_col_defs(
		'inflate_json',
		versions => [0,1],
		[ 'text, inflate_json',
			{ data_type => 'text', serializer_class => 'JSON' }
		],
		versions => [1],
		[ 'json',
			{ data_type => 'json', serializer_class => DNE }
		],
		[ 'jsonb null inflate_json',
			{ data_type => 'jsonb', is_nullable => 1, serializer_class => 'JSON' }
		],
	);
	is( eval 'package test::JSONAutoInflate; use DBIx::Class::ResultDDL qw/ -V1 -inflate_json /; [ json ]',
		[ data_type => 'json', serializer_class => 'JSON' ],
		'-inflate_json sets serializer class as default'
	) or diag $@;
};

test_col_defs(
	'arrays',
	versions => [1],
	[ 'array("text")',
		{ data_type => 'text[]' }
	],
	[ 'array(text)',
		{ data_type => 'text[]' },
	],
	[ 'array(decimal(5,3))',
		{ data_type => 'decimal[]', size => [5,3] }
	],
	[ 'array("int")',
		{ data_type => 'int[]' }
	],
	[ 'integer[]',
		{ data_type => 'integer[]' }
	]
);

done_testing;
