package Test;

no autovivification;
use strict;
use warnings;

use CGI;

#use Data::Session; # The caller did use_ok on Data::Session.

use DBI;

use DBIx::Admin::CreateTable;

use File::Basename;
use File::Spec;

use Hash::FieldHash ':all';

use Test::More;

fieldhash my %cache       => 'cache';
fieldhash my %column_type => 'column_type';
fieldhash my %creator     => 'creator';
fieldhash my %dbh         => 'dbh';
fieldhash my %directory   => 'directory';
fieldhash my %dsn         => 'dsn';
fieldhash my %dsn_attr    => 'dsn_attr';
fieldhash my %engine      => 'engine';
fieldhash my %id          => 'id';
fieldhash my %id_base     => 'id_base';
fieldhash my %id_file     => 'id_file';
fieldhash my %id_step     => 'id_step';
fieldhash my %key         => 'key';
fieldhash my %type        => 'type';
fieldhash my %password    => 'password';
fieldhash my %table_name  => 'table_name';
fieldhash my %test_count  => 'test_count';
fieldhash my %username    => 'username';
fieldhash my %value       => 'value';
fieldhash my %verbose     => 'verbose';

our $errstr  = '';
our $VERSION = '1.17';

# -----------------------------------------------

sub check_sqlite_directory_exists
{
	my($self)   = @_;
	my(@dsn)    = DBI -> parse_dsn($self -> dsn);
	my($result) = 1; # Success.

	if ($dsn[4] && ($dsn[1] =~ /^SQLite/i) )
	{
		my($file, $dir, $suffix) = fileparse($dsn[4]);
		$result                  = 0 if (! -e $dir);
	}

	return $result;

} # End of check_sqlite_directory_exists.

# -----------------------------------------------

sub create_session_from_id
{
	my($self, $id) = @_;

	return Data::Session -> new
	(
		cache            => $self -> cache,
		data_source      => $self -> dsn,
		data_source_attr => $self -> dsn_attr,
		directory        => $self -> directory,
		id               => $id,
		id_base          => $self -> id_base,
		id_file          => $self -> id_file,
		id_step          => $self -> id_step,
		password         => $self -> password,
		type             => $self -> type,
		username         => $self -> username,
		verbose          => $self -> verbose,
	) || die __PACKAGE__ . ". $Data::Session::errstr";

} # End of create_session_from_id.

# -----------------------------------------------

sub create_session_from_q
{
	my($self, $session1) = @_;
	my($q) = CGI -> new;

	$q -> param(sid  => $session1 -> id);
	$q -> param($self -> key => $self -> value);

	return Data::Session -> new
	(
		cache            => $self -> cache,
		data_source      => $self -> dsn,
		data_source_attr => $self -> dsn_attr,
		directory        => $self -> directory,
		id               => $session1 -> id,
		id_base          => $self -> id_base,
		id_file          => $self -> id_file,
		id_step          => $self -> id_step,
		name             => 'sid',
		password         => $self -> password,
		query            => $q,
		type             => $self -> type,
		username         => $self -> username,
		verbose          => $self -> verbose,
	) || die __PACKAGE__ . ". $Data::Session::errstr";

} # End of create_session_from_q.

# -----------------------------------------------

sub create_session_from_scratch
{
	my($self) = @_;

	return Data::Session -> new
	(
		cache            => $self -> cache,
		data_source      => $self -> dsn,
		data_source_attr => $self -> dsn_attr,
		directory        => $self -> directory,
		id               => $self -> id,
		id_base          => $self -> id_base,
		id_file          => $self -> id_file,
		id_step          => $self -> id_step,
		password         => $self -> password,
		type             => $self -> type,
		username         => $self -> username,
		verbose          => $self -> verbose,
	) || die __PACKAGE__ . ". $Data::Session::errstr";

} # End of create_session_from_scratch.

# -----------------------------------------------

sub create_table
{
	my($self, $table_name, $id_length) = @_;
	my($engine)      = $self -> engine;
	my($column_type) = $self -> column_type;
	my($result)      = $self -> creator -> create_table(<<SQL, {no_sequence => 1});
create table $table_name
(
id char($id_length) not null primary key,
a_session $column_type not null
) $engine
SQL

}	# End of create_table.

# -----------------------------------------------

sub dump
{
	my($self) = @_;

	$self -> log('cache:       ' . $self -> cache);
	$self -> log('column_type: ' . $self -> column_type);
	$self -> log('creator:     ' . $self -> creator);
	$self -> log('dbh:         ' . $self -> dbh);
	$self -> log('directory:   ' . $self -> directory);
	$self -> log('dsn:         ' . $self -> dsn);
	$self -> log('dsn_attr:    ' . $self -> hashref2string($self -> dsn_attr) );
	$self -> log('engine:      ' . $self -> engine);
	$self -> log('id:          ' . $self -> id);
	$self -> log('id_base:     ' . $self -> id_base);
	$self -> log('id_file:     ' . $self -> id_file);
	$self -> log('id_step:     ' . $self -> id_step);
	$self -> log('key:         ' . $self -> key);
	$self -> log('password:    ' . $self -> password);
	$self -> log('table_name:  ' . $self -> table_name);
	$self -> log('test_count:  ' . $self -> test_count);
	$self -> log('type:        ' . $self -> type);
	$self -> log('username:    ' . $self -> username);
	$self -> log('value:       ' . $self -> value);
	$self -> log('verbose:     ' . $self -> verbose);

} # End of dump.

# -----------------------------------------------

sub init
{
	my($self, $arg)    = @_;
	$$arg{cache}       ||= ''; # new(cache => ...).
	$$arg{column_type} = '';
	$$arg{creator}     = '';
	$$arg{dbh}         = '';
	$$arg{directory}   ||= File::Spec -> tmpdir;  # new(directory => ...).
	$$arg{dsn}         ||= ''; # new(dsn => ...).
	$$arg{dsn_attr}    ||= ''; # new(dsn_attr => ...).
	$$arg{engine}      = '';
	$$arg{id}          ||= 0;  # new(id => ...).
	$$arg{id_base}     ||= 0;  # new(id_base => ...).
	$$arg{id_file}     ||= File::Spec -> catdir(File::Spec -> tmpdir, 'data.session.id');  # new(id_file => ...).
	$$arg{id_step}     ||= 1;  # new(id_step => ...).
	$$arg{key}         = 'Perl';
	$$arg{password}    ||= ''; # new(password => ...).
	$$arg{table_name}  = 'sessions';
	$$arg{test_count}  = 0; # The caller did use_ok on Data::Session.
	$$arg{type}        ||= ''; # new(type => ...).
	$$arg{username}    ||= ''; # new(username => ...).
	$$arg{value}       = 'Language';
	$$arg{verbose}     ||= 0;  # new(verbose => ...).

} # End of init.

# -----------------------------------------------

sub hashref2string
{
	my($self, $h) = @_;
	$h ||= {};

	return '{' . join(', ', map{"$_ => $$h{$_}"} sort keys %$h) . '}';

} # End of hashref2string.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;
	$s ||= '';

	print STDERR "# $s\n";

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, %arg)  = @_;

	$class -> init(\%arg);

	# Expected format: new(type => 'driver:Pg;id:MD5;serialize:FreezeThaw').

	if (! $arg{type})
	{
		die __PACKAGE__ . '. No type specified in $obj -> new(...)';
	}

	# Expected format: new(dsn => 'dbi:Pg:dbname=test').

	if (! $arg{dsn})
	{
		die __PACKAGE__ . '. No dsn specified in $obj -> new(...)';
	}

	my($self) = from_hash(bless({}, $class), \%arg);

	return $self;

} # End of new.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	($self -> verbose > 1) && $self -> dump;

	# Special code for SQLite. The table /must/ exist.
	#
	# However, for tests, we always re-create the table, although
	# users would not normally do this. The reason is that if a
	# test is for id:Static, serialize:DataDumper, and the next
	# test is for serialize::FreezeThaw, the static id means the
	# 2nd test uses the first id's data, which is in DataDumper format.
	#
	# For BerkeleyDB, Files and Memcached, skip, since we do not have database tables.

	if ($self -> type !~ /driver:(?:BerkeleyDB|File|Memcached)/)
	{
		# We rig it to use an id length of 128, since the table
		# is deleted and re-created below before being written to.

		$self -> setup_table(128);
	}

	my($session1) = $self -> create_session_from_scratch;

	isa_ok($session1, 'Data::Session', '1st session object');

	$self -> test_count($self -> test_count + 1);

	$self -> log('id 1: ' . $session1 -> id);

	# For BerkeleyDB, Files and Memcached, skip, since we do not have database tables.

	if ($self -> type !~ /driver:(?:BerkeleyDB|File|Memcached)/)
	{
		# This time use the real length of the ID.

		$self -> setup_table($session1 -> id_class -> id_length);
	}

	# Set up some test data to play with.

	my($key)   = $self -> key;
	my($value) = $self -> value;

	$session1 -> param($key => $value);
	$session1 -> param("$key$key" => "$value$value");
	$session1 -> flush;

	# Create a session using the first session's id.

	my($session2) = $self -> test_session_from_id($session1);

	# Create a session using a query object based on the first session.

	my($session3) = $self -> test_session_from_q($session1);

	# Test save_param and load_param.

	my($session4) = $self -> test_save_load_param($session1);

	# Testing setting a parameter to undef.

	$self -> test_setting_getting_undef;

	# Clean up. All sessions must be deleted, otherwise they get flushed by Session::Data's DESTROY.

	$session1 -> delete;
	$session2 -> delete;
	$session3 -> delete;
	$session4 -> delete;

	done_testing($self -> test_count);

	# Return 1 to keep the outer done_testing happy.

	return 1;

} # End of run.

# -----------------------------------------------

sub setup_table
{
	my($self, $id_length) = @_;

	$self -> dbh(DBI -> connect($self -> dsn, $self -> username, $self -> password, $self -> dsn_attr)
		|| die __PACKAGE__ . ". Can't connect to " . $self -> dsn);
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> dbh, verbose => 0) );

	my($vendor) = $self -> creator -> db_vendor;

	$self -> column_type($vendor eq 'ORACLE' ? 'long' : $vendor eq 'POSTGRESQL' ? 'bytea' : 'text');
	$self -> engine($vendor =~ /(?:Mysql)/i ? 'engine=innodb' : '');
	$self -> creator -> drop_table($self -> table_name);
	$self -> create_table($self -> table_name, $id_length);

	if ($self -> table_exists == 0)
	{
		die __PACKAGE__ . ". Can't create '" . $self -> table_name . "' table";
	}

} # End of setup_table.

# -----------------------------------------------

sub table_exists
{
	my($self)      = @_;
	my($table_sth) = $self -> dbh -> table_info(undef, undef, '%', 'TABLE');
	my($result)    = 0;

	for my $table_data (@{$table_sth -> fetchall_arrayref({})})
	{
		if ($$table_data{'TABLE_NAME'} eq $self -> table_name)
		{
			$result = 1;
		}
	}

	return $result;

} # End of table_exists.

# -----------------------------------------------

sub test_cookie_and_http_header
{
	my($self) = @_;

	$self -> log;
	$self -> log("Testing HTTP header generation");

	my($session) = $self -> create_session_from_scratch;

	$session -> expire(10);

	my($my_header) = $session -> http_header;
	my($q)          = CGI -> new;
	my($cgi_cookie) = $q -> cookie(-name => 'CGISESSID', -value => $session -> id, -expires => '+10s');
	my($cgi_header) = $q -> header(-cookie => $cgi_cookie, -type => 'text/html');

	ok($my_header eq $cgi_header, 'HTTP header created via CGI directly matches one via http_header()');

	# Return test count.

	return 1;

} # End of test_cookie_and_http_header.

# -----------------------------------------------

sub test_expire_a_session_parameter
{
	my($self)  = @_;
	my($count) = 0;
	my($delay) = 1; # Second.
	my(%data)  =
	(
		key_1 =>
		{
			expire => 0,
			value  => 'value_1',
		},
		key_2 =>
		{
			expire => $delay,
			value  => 'value_2',
		},
	);

	my($id);

	# 1: Create a session, and when it goes out of scope, it's saved to storage.

	{
		my($session) = $self -> create_session_from_scratch;
		$id          = $session -> id;

		for my $key (keys %data)
		{
			$session -> expire($key => $data{$key}{expire});
			$session -> param($key  => $data{$key}{value});
		}
	}

	# 2: Sleep beyond the expiry time, and read the session back in.

	$self -> log;
	$self -> log("Testing expire a session parameter. Sleeping for $delay second ...");

	$delay = 3 * $delay;

	sleep($delay);

	my($session) = $self -> create_session_from_id($id);
	my($ptime)   = $session -> ptime;

	for my $key (sort keys %$ptime)
	{
		$self -> log("Recovered $key: $$ptime{$key}");
	}

	# We should have lost key_2 by now.

	my($data);

	for my $key (keys %data)
	{
		$data = $session -> param($key);

		if ($key eq 'key_1')
		{
			ok(defined $data, "Data for key $key not expired, and hence retrieved from storage");
		}
		else
		{
			ok(! defined $data, "Data for key $key expired, and hence not retrieved from storage");
		}

		# This is not called, because we're running after the inner done_testing().
		#$self -> test_count($self -> test_count + 1);

		$count++;

	}

	# Return test count.

	return $count;

} # End of test_expire_a_session_parameter.

# -----------------------------------------------

sub test_expire_the_session
{
	my($self)  = @_;
	my($key)   = 'Perl';
	my($value) = 'Language';
	my($count) = 0;
	my($delay) = 1; # Second.

	my($id);

	# 1: Create a session, and when it goes out of scope, it's saved to storage.

	{
		my($session) = $self -> create_session_from_scratch;
		$id          = $session -> id;

		$session -> expire($delay);
		$session -> param($key => $value);

		my($secs) = $session -> expire;

		ok($delay == $secs, 'Expiry time set and retrieved');

		# This is not called, because we're running after the inner done_testing().
		#$self -> test_count($self -> test_count + 1);

		$count++;
	}

	# 2: Sleep beyond the expiry time, and read the session back in.

	$self -> log;
	$self -> log("Testing expire the session. Sleeping for $delay second ...");

	$delay = 3 * $delay;

	sleep($delay);

	my($session) = $self -> create_session_from_id($id);

	# We should have lost $key by now.

	my($data) = $session -> param($key);

	ok(! defined $data, 'Data expired, and hence not retrieved from storage');

	# This is not called, because we're running after the inner done_testing().
	#$self -> test_count($self -> test_count + 1);

	$count++;

	# Return test count.

	return $count;

} # End of test_expire_the_session.

# -----------------------------------------------

sub test_save_load_param
{
	my($self, $session1) = @_;

	# 1: Stuff some data into a query object.

	my($q1)   = CGI -> new;
	my(%data) =
	(
		key_1 => 'value_1',
		key_2 => 'value_2',
	);

	my($key);

	for $key (keys %data)
	{
		$q1 -> param($key => $data{$key});
	}

	# 2: Test save param, copying data from a query object to a session.

	my($session4) = $self -> create_session_from_scratch;

	$session4 -> save_param($q1, [keys %data]);

	my($total1) = '';
	my($total2) = '';

	for $key (keys %data)
	{
		$total1 .= $data{$key};
		$total2 .= $session4 -> param($key);
	}

	ok($total1 eq $total2, 'Data recovered from save_param() matches');

	$self -> test_count($self -> test_count + 1);

	# 3: Test load param, copying data from a session to a query object.

	my($q2) = $session4 -> load_param(undef, [keys %data]);
	$total1 = '';
	$total2 = '';

	for $key (keys %data)
	{
		$total1 .= $data{$key};
		$total2 .= $q2 -> param($key);
	}

	ok($total1 eq $total2, 'Data recovered from load_param() matches');

	$self -> test_count($self -> test_count + 1);

	return $session4;

} # End of test_save_load_param.

# -----------------------------------------------

sub test_session_from_id
{
	my($self, $session1) = @_;
	my($session2) = $self -> create_session_from_id($session1 -> id);

	isa_ok($session2, 'Data::Session', '2nd session object');

	$self -> test_count($self -> test_count + 1);

	($self -> verbose > 1) && $self -> log('id 2: ' . $session2 -> id);

	my($key)   = $self -> key;
	my($data)  = $session2 -> param($key);
	my($value) = $self -> value;

	ok($value eq $data, "Data stored (session1) and retrieved (session2)");

	$self -> test_count($self -> test_count + 1);

	return $session2;

} # End of test_session_from_id.

# -----------------------------------------------

sub test_session_from_q
{
	my($self, $session1) = @_;
	my($session3) = $self -> create_session_from_q($session1);

	isa_ok($session3, 'Data::Session', '3rd session object');

	$self -> test_count($self -> test_count + 1);

	($self -> verbose > 1) && $self -> log('id 3: ' . $session3 -> id);

	my($key)   = $self -> key;
	my($data)  = $session3 -> param($key);
	my($value) = $self -> value;

	ok($value eq $data, "Data stored (session1) and retrieved (session3)");

	$self -> test_count($self -> test_count + 1);

	$key  = "$key$key";
	$data = $session3 -> param($key);

	ok("$value$value" eq $data, "More data stored (session1) and retrieved (session3)");

	$self -> test_count($self -> test_count + 1);

	return $session3;

} # End of test_session_from_q.

# -----------------------------------------------

sub test_setting_getting_undef
{
	my($self)     = @_;
	my($key1)     = 'stealth';
	my($value1)   = undef;
	my($key2)     = 'null';
	my($value2)   = 'null';
	my($session1) = $self -> create_session_from_scratch;

	$session1 -> param($key1 => $value1);
	$session1 -> param($key2 => $value2);
	$session1 -> flush;

	my($session2) = $self -> create_session_from_id($session1 -> id);

	ok(! defined $session2 -> param($key1), 'Stored and retrieved undef');

	$self -> test_count($self -> test_count + 1);

	ok($session2 -> param($key2) eq $value2, "Stored and retrieved 'null'");

	$self -> test_count($self -> test_count + 1);

	$session1 -> delete;
	$session2 -> delete;

} # End of test_setting_getting_undef.

# -----------------------------------------------

sub test_validation_of_time_strings
{
	my($self) = @_;
	my(%map)  =
	(
		'-10'  =>      -10,
		'+10d' =>   864000,
		 '10M' => 25920000,
	);
	my($session) = $self -> create_session_from_scratch;
	my($count)   = 0;

	my($seconds_in, $seconds_out);

	for my $time (qw/-10 +10d 10M/)
	{
		$count++;

		$seconds_in  = $map{$time};
		$seconds_out = $session -> validate_time($time);

		ok($seconds_in == $seconds_out, "Validated time string $time");

		# This is not called, because we're running after the inner done_testing().
		#$self -> test_count($self -> test_count + 1);
	}

	$session -> delete;

	# Return test count.

	return $count;

} # End of test_validation_of_time_strings.

# -----------------------------------------------

sub traverse
{
	my($self) = @_;

	($self -> verbose > 1) && $self -> dump;

	# Special code for SQLite. The table /must/ exist.
	#
	# However, for tests, we always re-create the table, although
	# users would not normally do this. The reason is that if a
	# test is for id:Static, serialize:DataDumper, and the next
	# test is for serialize::FreezeThaw, the static id means the
	# 2nd test uses the first id's data, which is in DataDumper format.
	#
	# For Files, skip, since we do not have database tables.

	if ($self -> type !~ /driver:File/)
	{
		# We rig it to use an id length of 32, since the table
		# is deleted and re-created below before being written to.

		$self -> setup_table(32);
	}

	my($session1) = $self -> create_session_from_scratch;

	isa_ok($session1, 'Data::Session', '1st session object');

	$self -> test_count($self -> test_count + 1);

	$self -> log('id1: ' . $session1 -> id);

	# Stash ids for the traversal below.

	my(%id);

	$id{$session1 -> id} = 1;

	# For Files, skip, since we do not have database tables.

	if ($self -> type !~ /driver:File/)
	{
		# This time use the real length of the ID.

		$self -> setup_table($session1 -> id_class -> id_length);
	}

	# Create another 4 sessions, and then run a traverse().

	for my $count (1 .. 4)
	{
		$session1            = $self -> create_session_from_scratch;
		$id{$session1 -> id} = 1;

		# Set some test data to play with.

		$session1 -> param($self -> key => $self -> value);
		$session1 -> flush;
	}

	my($count) = 0;
	my($sub)   = sub
	{
		my($id) = @_;

		$count++;

		if ($id{$id})
		{
			$self -> log("$count: Recovered known id $id from traverse");
		}
		else
		{
			$self -> log("$count: Recovered unknown id $id from traverse");
		}
	};

	$session1 -> traverse($sub);

} # End of traverse.

# -----------------------------------------------

1;
