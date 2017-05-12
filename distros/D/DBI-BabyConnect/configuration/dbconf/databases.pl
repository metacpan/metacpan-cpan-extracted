# Databases definitions

{

BABYDB_001 =>
{
	Driver => 'Mysql',
	#Server=>'gracy.youetl.com',
	Server=>'',
	UserName=>'root',
	Password=>'abcdef',
	# Mysql defines a database name, CAREFUL it may be case sensitive!
	DataName=>'BABYDB',
	PrintError=>1,
	RaiseError=>1,
	AutoRollback => 0,
	AutoCommit=>1,
	LongTruncOk=>1,
	LongReadLen => 900000,
},


BABYDB_002 =>
{
	Driver => 'Mysql',
	#Server=>'gracy.youetl.com',
	Server=>'',
	UserName=>'root',
	Password=>'abcdef',
	# Mysql defines a database name, CAREFUL it may be case sensitive!
	DataName=>'BABYDB',
	PrintError=>1,
	RaiseError=>1,
	AutoRollback => 0,
	AutoCommit=>1,
	LongTruncOk=>1,
	LongReadLen => 900000,
},

BABYDB_003 =>
{
	Driver => 'Mysql',
	#Server=>'gracy.youetl.com',
	Server=>'',
	UserName=>'root',
	Password=>'abcdef',
	# Mysql defines a database name, CAREFUL it may be case sensitive!
	DataName=>'BABYDB',
	PrintError=>1,
	RaiseError=>1,
	AutoRollback => 0,
	AutoCommit=>1,
	LongTruncOk=>1,
	LongReadLen => 900000,
},

BABYDB_004 =>
{
	Driver => 'Mysql',
	#Server=>'gracy.youetl.com',
	Server=>'',
	UserName=>'root',
	Password=>'abcdef',
	# Mysql defines a database name, CAREFUL it may be case sensitive!
	DataName=>'BABYDB',
	PrintError=>1,
	RaiseError=>1,
	AutoRollback => 0,
	AutoCommit=>1,
	LongTruncOk=>1,
	LongReadLen => 900000,
},

# to test with Apache::BabyConnect, eg/perl/onemore.pl
ACADABRA_0123456 =>
{
	Driver => 'Mysql',
	#Server=>'gracy.youetl.com',
	Server=>'',
	UserName=>'root',
	Password=>'abcdef',
	# Mysql defines a database name, CAREFUL it may be case sensitive!
	DataName=>'BABYDB',
	PrintError=>1,
	RaiseError=>1,
	AutoRollback => 0,
	AutoCommit=>1,
	LongTruncOk=>1,
	LongReadLen => 900000,
},

# an Oracle descriptor
OK =>
 	{
		Driver => 'Oracle',
		Server=>'OK.WORLD',
		UserName=>'okok',
		Password=>'okoksc',
		PrintError=>1,
		RaiseError=>1,
		AutoRollback => 1,
		AutoCommit=>0,
		LongTruncOk=>1,
		LongReadLen => 900000,
	}

};

