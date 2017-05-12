package t::lib::TestApp;

use Data::Dumper;

use Time::Piece;

use Dancer;
use Dancer::Plugin::Log::DB;


get '/01_prepare_env/*/*' => sub {
	my ($message_field_name, $timestamp_field_name) = splat;
	log_db_dbh->do("CREATE TABLE logs (_id INTEGER PRIMARY KEY AUTOINCREMENT, $message_field_name TEXT, $timestamp_field_name DATE)");
};

get '/01_prepare_env_a/*/*' => sub {
	my ($field1_name, $field2_name) = splat;
	log_db_dbh->do("CREATE TABLE logs (_id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, timestamp DATE, $field1_name TEXT, $field2_name TEXT)");
};

get '/01_prepare_env_b/*/*' => sub {
	my ($message_field_name, $timestamp_field_name) = splat;
	log_db_dbh->do("CREATE TABLE logs_table (_id INTEGER PRIMARY KEY AUTOINCREMENT, $message_field_name TEXT, $timestamp_field_name DATE)");
};



get '/02_add_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;

	my $entry = {
		message => $message,
		timestamp => $timestamp eq 'undef' ? time : $timestamp
	};
		
	eval {
		log_db $entry;
	};
	if ($@) {
		return 0;
	}
	return 1;	
};

get '/02_check_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;
	undef($timestamp) 
		if ($timestamp eq 'undef');
	# $timestamp = time 
	# 	unless $timestamp eq 'undef';
	
	my $where = 'message = ?';
	if ($timestamp) {
		$where .= ' AND timestamp = ?';
	}

	my @bind = ($message);
	if ($timestamp) {
		push @bind, sprintf("%s %s", localtime($timestamp)->ymd, localtime($timestamp)->hms);
	}
	
	my $sth = log_db_dbh->prepare("SELECT * FROM logs WHERE $where");
	$sth->execute(@bind);
	
	if ($sth->fetchrow_arrayref) {
		return 1;
	}
	
	return 0;
};

get '/03_add_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;
	
	my $entry = {
		message => $message,
		timestamp => $timestamp eq 'undef' ? time : $timestamp
	};
	
	eval {
		log_db $entry;
	};
	if ($@) {
		return 0;
	}
	return 1;
};

get '/03_check_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;
	undef($timestamp) 
		if ($timestamp eq 'undef');
	
	my $where = 'message_field = ?';
	if ($timestamp) {
		$where .= ' AND timestamp_field = ?';
	}
	
	my @bind = ($message);
	if ($timestamp) {
		push @bind, sprintf("%s %s", localtime($timestamp)->ymd, localtime($timestamp)->hms);
	}
	
	my $sth = log_db_dbh->prepare("SELECT * FROM logs WHERE $where");
	$sth->execute(@bind);
	
	if ($sth->fetchrow_arrayref) {
		return 1;
	}
	
	return 0;
};

get '/04_add_common_log_entry/*/*/*/*' => sub {
	my ($message, $timestamp, $field1, $field2) = splat;

	my $entry = {
		message => $message,
		timestamp => $timestamp eq 'undef' ? time : $timestamp,
		field1 => $field1,
		field2 => $field2
	};

	eval {
		log_db $entry;
	};
	if ($@) {
		return 0;
	}
	return 1;
};

get '/04_check_common_log_entry/*/*/*/*' => sub {
	my ($message, $timestamp, $field1, $field2) = splat;
	undef($timestamp) 
		if ($timestamp eq 'undef');

	my $where = 'message = ? AND field1 = ? AND field2 = ?';
	if ($timestamp) {
		$where .= ' AND timestamp = ?';
	}

	my @bind = ($message, $field1, $field2);
	if ($timestamp) {
		push @bind, sprintf("%s %s", localtime($timestamp)->ymd, localtime($timestamp)->hms);
	}

	my $sth = log_db_dbh->prepare("SELECT * FROM logs WHERE $where");
	$sth->execute(@bind);

	if ($sth->fetchrow_arrayref) {
		return 1;
	}

	return 0;
};

get '/05_add_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;

	my $entry = {
		message => $message,
		timestamp => $timestamp eq 'undef' ? time : $timestamp,
		nonexisent_field => 'test',
	};

	eval {
		log_db $entry;
	};
	if ($@) {
		return 0;
	}
	return 1;	
};

get '/06_check_common_log_entry/*/*' => sub {
	my ($message, $timestamp) = splat;
	undef($timestamp) 
		if ($timestamp eq 'undef');
	# $timestamp = time 
	# 	unless $timestamp eq 'undef';
	
	my $where = 'message = ?';
	if ($timestamp) {
		$where .= ' AND timestamp = ?';
	}

	my @bind = ($message);
	if ($timestamp) {
		push @bind, sprintf("%s %s", localtime($timestamp)->ymd, localtime($timestamp)->hms);
	}
	
	my $sth = log_db_dbh->prepare("SELECT * FROM logs_table WHERE $where");
	$sth->execute(@bind);
	
	if ($sth->fetchrow_arrayref) {
		return 1;
	}
	
	return 0;
};

get '/99_remove_env' => sub {
	# Clean up testing database
	log_db_dbh->do("DROP TABLE IF EXISTS logs");
	log_db_dbh->do("DROP TABLE IF EXISTS logs_table");
};
