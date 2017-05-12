+{
    connect_info => +{
	DB_R1 => +{
	    attrs => +{
		AutoCommit => 0,
		PrintError => 0,
		RaiseError => 1,
		Warn => 0,
	    },
	    dsn => 'dbi:mysql:dbname=user;host=db_r1',
	    password => undef,
	    user => 'hoge',
	},
	DB_R2 => +{
	    attrs => +{
		AutoCommit => 0,
		PrintError => 0,
		RaiseError => 1,
		Warn => 0,
	    },
	    dsn => 'dbi:mysql:dbname=user;host=db_r2',
	    password => undef,
	    user => 'hoge',
	},
    },
    clusters => +{
	DB_R => [ qw(DB_R1 DB_R2) ],
    },
};
