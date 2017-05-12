+{
    connect_info => +{
	DB_W => +{
	    attrs => +{
		AutoCommit => 0,
		PrintError => 0,
		RaiseError => 1,
		Warn => 0,
	    },
	    dsn => 'dbi:mysql:dbname=user;host=db_w',
	    password => undef,
	    user => 'hoge',
	},
    },
};
