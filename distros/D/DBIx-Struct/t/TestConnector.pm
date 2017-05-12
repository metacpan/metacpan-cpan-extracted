package TestSth;

sub new {
	my ($class, $data_info, $data) = @_;
	my $self = {
		pos       => 0,
		data_info => $data_info || [],
		data      => $data || [],
	};
	$self->{NAME} = $self->{data_info};
	for (my $i = 0 ; $i < @$data_info ; ++$i) {
		$self->{NAME_hash}{$data_info->[$i]} = $i;
	}
	$self->{TYPE} = [0 x @$data_info];
	bless $self, $class;
}

sub fetchall_arrayref {
	my ($self, $attr) = @_;
	my $ret = [];
	if ($attr && ref ($attr)) {
		for (my $j = 0 ; $j < @{$self->{data}} ; ++$j) {
			my $d = $self->{data}[$j];
			push @$ret, {};
			my $cr = $ret->[-1];
			for (my $i = 0 ; $i < @{$self->{data_info}} ; ++$i) {
				my $f = $self->{data_info}[$i];
				$cr->{$f} = $d->[$i];
			}
		}
	} else {
		return $self->{data};
	}
	return $ret;
}

sub fetch {
	my ($self) = @_;
	return if $self->{pos} >= @{$self->{data}};
	return $self->{data}[$self->{pos}++];
}

sub fetchrow_arrayref {
	my ($self, $attr) = @_;
	my $ret = $self->fetch;
	return if not $ret;
	if ($attr && ref ($attr)) {
		my $hr = {};
		for (my $i = 0 ; $i < @{$self->{data_info}} ; ++$i) {
			my $f = $self->{data_info}[$i];
			$hr->{$f} = $ret->[$i];
		}
		$ret = $hr;
	}
	$ret;
}

sub fetchrow_hashref {
	my ($self) = @_;
	my $ar = $self->fetch;
	return if not $ar;
	my $ret = {};
	for (my $i = 0 ; $i < @{$self->{data_info}} ; ++$i) {
		my $f = $self->{data_info}[$i];
		$ret->{$f} = $ar->[$i];
	}
	$ret;
}

sub finish {

}

sub execute {
	my ($self, @params) = @_;
	$TestConnector::sql_bind = "'" . join ("','", @params) . "'";
	if (@params && $params[0] =~ /^\d+$/) {
		$self->{pos} = $params[0] - 1;
	}
	return "0E0";
}

package TestDBH;

our %tables = (
	prim => {
		data_info => ['id', 'payload'],
		data => [[1, 'pay1'], [2, 'pay2']]
	},
	list => {
		data_info => ['id', 'ref'],
		data => [[1, 'reference1'], [2, 'reference2']]
	},
	pl_assoc => {
		data_info => ['id_prim', 'id_list'],
		data => [[1, 2], [2, 1]],
	}
);

our %table_infos = (
	fkipk => {
		data_info => [
			'UK_TABLE_CAT',     'UK_TABLE_SCHEM', 'UK_TABLE_NAME',     'UK_COLUMN_NAME',
			'FK_TABLE_CAT',     'FK_TABLE_SCHEM', 'FK_TABLE_NAME',     'FK_COLUMN_NAME',
			'ORDINAL_POSITION', 'UPDATE_RULE',    'DELETE_RULE',       'FK_NAME',
			'UK_NAME',          'DEFERABILITY',   'UNIQUE_OR_PRIMARY', 'UK_DATA_TYPE',
			'FK_DATA_TYPE'
		],
		list => [
			[   undef, 'public', 'list', 'id', undef, 'public', 'pl_assoc', 'id_list', 2, '3',
				'0', 'pl_assoc_id_list_fkey', 'list_pkey', '7', 'PRIMARY', 'int4', 'int4'
			]
		],
		prim => [
			[   undef, 'public', 'prim', 'id', undef, 'public', 'pl_assoc', 'id_prim', 1, '3',
				'0', 'pl_assoc_id_prim_fkey', 'prim_pkey', '7', 'PRIMARY', 'int4', 'int4'
			]
		],
		pl_assoc => undef,
	},
	fkifk => {
		data_info => [
			'UK_TABLE_CAT',     'UK_TABLE_SCHEM', 'UK_TABLE_NAME',     'UK_COLUMN_NAME',
			'FK_TABLE_CAT',     'FK_TABLE_SCHEM', 'FK_TABLE_NAME',     'FK_COLUMN_NAME',
			'ORDINAL_POSITION', 'UPDATE_RULE',    'DELETE_RULE',       'FK_NAME',
			'UK_NAME',          'DEFERABILITY',   'UNIQUE_OR_PRIMARY', 'UK_DATA_TYPE',
			'FK_DATA_TYPE'
		],
		pl_assoc => [
			[   undef, 'public', 'list', 'id', undef, 'public', 'pl_assoc', 'id_list', 2, '3',
				'0', 'pl_assoc_id_list_fkey', 'list_pkey', '7', 'PRIMARY', 'int4', 'int4'
			],
			[   undef, 'public', 'prim', 'id', undef, 'public', 'pl_assoc', 'id_prim', 1, '3',
				'0', 'pl_assoc_id_prim_fkey', 'prim_pkey', '7', 'PRIMARY', 'int4', 'int4'
			]
		],
		list => undef,
		prim => undef,
	},
	pki => {
		data_info => [
			'TABLE_CAT',              'TABLE_SCHEM',
			'TABLE_NAME',             'COLUMN_NAME',
			'KEY_SEQ',                'PK_NAME',
			'DATA_TYPE',              'pg_tablespace_name',
			'pg_tablespace_location', 'pg_schema',
			'pg_table',               'pg_column'
		],
		prim => [
			[   undef,  'public', 'prim', 'id',     '1',    'prim_pkey',
				'int4', undef,    undef,  'public', 'prim', 'prim_pkey'
			]
		],
		list => [
			[   undef,  'public', 'list', 'id',     '1',    'list_pkey',
				'int4', undef,    undef,  'public', 'list', 'list_pkey'
			]
		],
		pl_assoc => undef,
	},
	ci => {
		data_info => [
			'TABLE_CAT',        'TABLE_SCHEM',
			'TABLE_NAME',       'COLUMN_NAME',
			'DATA_TYPE',        'TYPE_NAME',
			'COLUMN_SIZE',      'BUFFER_LENGTH',
			'DECIMAL_DIGITS',   'NUM_PREC_RADIX',
			'NULLABLE',         'REMARKS',
			'COLUMN_DEF',       'SQL_DATA_TYPE',
			'SQL_DATETIME_SUB', 'CHAR_OCTET_LENGTH',
			'ORDINAL_POSITION', 'IS_NULLABLE',
			'pg_type',          'pg_constraint',
			'pg_schema',        'pg_table',
			'pg_column',        'pg_enum_values'
		],
		pl_assoc => [
			[   undef,     'public', 'pl_assoc', 'id_prim',  4,         'integer',
				4,         undef,    undef,      undef,      1,         undef,
				undef,     undef,    undef,      undef,      1,         'YES',
				'integer', undef,    'public',   'pl_assoc', 'id_prim', undef
			],
			[   undef,     'public', 'pl_assoc', 'id_list',  4,         'integer',
				4,         undef,    undef,      undef,      1,         undef,
				undef,     undef,    undef,      undef,      2,         'YES',
				'integer', undef,    'public',   'pl_assoc', 'id_list', undef
			]
		],
		prim => [
			[   undef,                                'public',
				'prim',                               'id',
				4,                                    'integer',
				4,                                    undef,
				undef,                                undef,
				0,                                    undef,
				'nextval(\'prim_id_seq\'::regclass)', undef,
				undef,                                undef,
				1,                                    'NO',
				'integer',                            undef,
				'public',                             'prim',
				'id',                                 undef
			],
			[   undef,  'public', 'prim',   'payload', -1,        'text',
				undef,  undef,    undef,    undef,     1,         undef,
				undef,  undef,    undef,    undef,     2,         'YES',
				'text', undef,    'public', 'prim',    'payload', undef
			]
		],
		list => [
			[   undef,                                'public',
				'list',                               'id',
				4,                                    'integer',
				4,                                    undef,
				undef,                                undef,
				0,                                    undef,
				'nextval(\'list_id_seq\'::regclass)', undef,
				undef,                                undef,
				1,                                    'NO',
				'integer',                            undef,
				'public',                             'list',
				'id',                                 undef
			],
			[   undef,  'public', 'list',   'ref',  -1,    'text',
				undef,  undef,    undef,    undef,  1,     undef,
				undef,  undef,    undef,    undef,  2,     'YES',
				'text', undef,    'public', 'list', 'ref', undef
			]
		]
	},
	ti => {
		data_info => [
			'TABLE_CAT',              'TABLE_SCHEM',
			'TABLE_NAME',             'TABLE_TYPE',
			'REMARKS',                'pg_tablespace_name',
			'pg_tablespace_location', 'pg_schema',
			'pg_table'
		],
		data => [
			[undef, 'public', 'list', 'TABLE', undef, undef, undef, 'public', 'list'],
			[   undef, 'public', 'pl_assoc', 'TABLE', undef, undef,
				undef, 'public', 'pl_assoc'
			],
			[undef, 'public', 'prim', 'TABLE', undef, undef, undef, 'public', 'prim']
		]
	},
	pk => {
		prim     => ["id"],
		list     => ["id"],
		pl_assoc => [],
	}
);

sub new {
	bless {}, $_[0];
}

sub prepare {
	my ($dbh, $query) = @_;
	$TestConnector::sql_query = $query;
	my ($table) = $query =~ m{from \s*(\S+)}i;
	TestSth->new($tables{$table}{data_info}, $tables{$table}{data});
}

sub primary_key_info {
	my ($dbh, undef, undef, $table) = @_;
	TestSth->new($table_infos{pki}{data_info}, $table_infos{pki}{$table});
}

sub primary_key {
	my ($dbh, undef, undef, $table) = @_;
	return @{$table_infos{pk}{$table}};
}

sub foreign_key_info {
	my ($dbh, undef, undef, $pktable, undef, undef, $fktable) = @_;
	my $k = defined ($pktable) ? "fkipk" : "fkifk";
	TestSth->new($table_infos{$k}{data_info},
		$table_infos{$k}{$pktable || $fktable});
}

sub column_info {
	my ($dbh, undef, undef, $table, undef) = @_;
	TestSth->new($table_infos{ci}{data_info}, $table_infos{ci}{$table});
}

sub type_info {
	my ($dbh, $data_type) = @_;
	return {TYPE_NAME => 'integer'};
}

sub table_info {
	my ($dbh, undef, undef, undef, undef) = @_;
	TestSth->new($table_infos{ti}{data_info}, $table_infos{ti}{data});
}

sub selectrow_array {
	my ($dbh, $query, $attr, @params) = @_;
	$TestConnector::sql_query = $query;
	$TestConnector::sql_bind = "'" . join ("','", @params) . "'";
	return @{[1]} if $query =~ /returning /;
	return ();
}

sub do {
	my ($dbh, $query, $attr, @params) = @_;
	$TestConnector::sql_query = $query;
	$TestConnector::sql_bind = "'" . join ("','", @params) . "'";
	return "0E0";
}

sub errstr {
	my ($dbh) = @_;
	print STDERR "error: $TestConnector::sql_query; $TestConnector::sql_bind\n";
	return "ERROR!!!";
}

package TestConnector;

our $sql_query = '';
our $sql_bind  = '';

sub new {
	bless {}, $_[0];
}

sub run {
	my ($self, $cref) = @_;
	local $_ = TestDBH->new;
	$cref->();
}

sub mode {
	1;
}

sub driver { {driver => 'Pg'} }

sub query {
#	print "query: $sql_query\n";
#	print "bind: $sql_bind\n";
	return ($sql_query, $sql_bind);
}

1;
