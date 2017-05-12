#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework '+sql' ;
use config ;

# VERSION
our $VERSION = '1.004' ;


	# Data
	my $Just_stored = 
	[ 
	  { 
	    adapter => 0,
	    audio => 1,
	    chan_type => "tv",
	    channel => "_adummy",
	    date => '2008-06-10',
	    duration => '01:00:00',
	    episode => 2,
	    genre => undef,
	    num_episodes => 6,
	    pid => 29130,
	    repeat => 0,
	    start => '10:30:00',
	    text => "This is a test program",
	    title => "a test program",
	    video => 1,
	  },
	  { 
	    adapter => 0,
	    audio => 1,
	    chan_type => "tv",
	    channel => "_adummy",
	    date => '2008-06-11',
	    duration => '01:00:00',
	    episode => 2,
	    genre => undef,
	    num_episodes => 6,
	    pid => 29131,
	    repeat => 0,
	    start => "11:30:00",
	    text => "This is a test program",
	    title => "a test program 2",
	    video => 1,
	  },
	  { 
	    adapter => 0,
	    audio => 1,
	    chan_type => "tv",
	    channel => "_adummy",
	    date => "2008-06-12",
	    duration => "01:00:00",
	    episode => 2,
	    genre => undef,
	    num_episodes => 6,
	    pid => 29132,
	    repeat => 0,
	    start => "12:30:00",
	    text => "This is a test program",
	    title => "a test program 3",
	    video => 1,
	  },
	  { 
	    adapter => 0,
	    audio => 1,
	    chan_type => "tv",
	    channel => "_adummy",
	    date => "2008-06-13",
	    duration => "01:00:00",
	    episode => 2,
	    genre => undef,
	    num_episodes => 6,
	    pid => 29133,
	    repeat => 0,
	    start => "13:30:00",
	    text => "This is a test program",
	    title => "a test program 4",
	    video => 1,
	  },
	];

	diag( "Testing Sql" );

	if (!exists($config::TO_TEST{'App::Framework::Feature::Sql'}))
	{
	    plan skip_all => 'Module not selected for full install';
		exit 0 ;
	}


	eval {
		require DBI;
		require DBD::mysql;
	} ;
	if ($@)
	{
	    plan skip_all => 'Unable to run tests since DBI not available';
		exit 0 ;
  	}

	# Create application and run it
	go() ;




#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href) = @_ ;

	my $host = $opts_href->{host} ;
	my $test_db = $opts_href->{database} ;
	my $test_user = $opts_href->{user} || $ENV{USER} || $ENV{USERNAME} ;
	my $test_password = $opts_href->{password} ;
	my $test_table = $opts_href->{table} ;
	
	my $test_dsn = "DBI:mysql:database=$test_db;host=$host" ;
	
	
	## do some sanity checks
	diag("Checking can connect to database") ;
	my $dbh;
	eval {
			$dbh=DBI->connect($test_dsn, $test_user, $test_password,
	                      { RaiseError => 1, PrintError => 1, AutoCommit => 0 });
	};
	if ($@) {
	    plan skip_all => "Failed to connect to database : can't continue";
	    return 0 ;
	}
  	
	diag("Checking user \"$test_user\" has sufficient privileges") ;
  	eval {
		$dbh->do("DROP TABLE IF EXISTS $test_table") ;
		$dbh->do("CREATE TABLE $test_table (id INT(4), name VARCHAR(64))") ;
		my $sth = $dbh->prepare("select * FROM '$test_table'") ;
		$dbh->do("DROP TABLE IF EXISTS $test_table") ;
		$dbh->disconnect();
  	} ;
	if ($@) {
	    plan skip_all => "Failed to access  : can't continue";
	    return 0 ;
	}

	diag("Looks good, starting real tests") ;
  	
  	## If we get here then we're good to go
    plan tests => 3 +  (2 * (4 + scalar(@$Just_stored))) ;

	
	# All named transactions use the values stored in this hash
	my %sql_vars ;

	# Set up database access
	my $sql = $app->sql() ;
	ok($sql, "Got object") ;

	my %sql_vars_internal ;
	$sql->set(
			'host'		=> $host,
			'database'	=> $test_db,
			'table'		=> $test_table,
			'user'		=> $test_user,
			'password'	=> $test_password,
			'sql_vars'	=> \%sql_vars_internal,
			
			# Option to do some Sql debugging by tracing transactions to a file
			'trace'		=> $opts_href->{'debug'} ? 4 : 0,
			'trace_file'=> 'logsql.log',
			'debug' => $opts_href->{'debug'},
			
			# Prepare some named transactions
			'prepare'	=> {
				'check',  {
					'limit'	=> 1,
					'where'	=> {
						'vars'	=> [qw/pid channel/],
						'vals'	=> \%sql_vars,
					},
				},
				'select',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
						'vals'	=> \%sql_vars,
					},
				},
				'select_group',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
						'vals'	=> \%sql_vars,
					},
					'group'	=> 'channel',
				},
				'delete',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
						'vals'	=> \%sql_vars,
					},
				},
				'insert',  {
					'vars'	=> [qw/pid channel title date start duration episode num_episodes repeat text/],
					'vals'	=> \%sql_vars,
				},

				# internal
				'check_internal',  {
					'limit'	=> 1,
					'where'	=> {
						'vars'	=> [qw/pid channel/],
					},
				},
				'select_internal',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
					},
				},
				'select_group_internal',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
					},
					'group'	=> 'channel',
				},
				'delete_internal',  {
					'where'	=> {
						'sql' => '`pid`>=? AND `channel`=?',
						'vars'	=> [qw/pid channel/],
					},
				},
				'insert_internal',  {
					'vars'	=> [qw/pid channel title date start duration episode num_episodes repeat text/],
				},

			},
	) ;
	ok(1, "Set vars") ;

	## demo of running sql stored as text in a __DATA__ section
	$app->sql->sql_from_data("sqltest.sql") ;
	ok(1, "Sql from variables") ;

	
	do_test($app, \%sql_vars, '') ;
	do_test($app, \%sql_vars_internal, '_internal') ;
}

sub do_test
{
	my ($app, $vars_href, $name) = @_ ;

	foreach my $test_href (@$Just_stored)
	{
		foreach my $key (keys %$test_href)
		{
			$vars_href->{$key} = $test_href->{$key} ;
		}

$app->prt_data("Set vars : $vars_href = ", $vars_href) ;	

		$app->sql->sth_query("insert$name") ;
		ok(1, "insert") ;
	}

	# All stored...
	my $All_stored = $Just_stored ;
	
	# Grouped
	my $Grouped = 
	[ # ARRAY(0x8a12e74)
	  { # HASH(0x8962974)
	    adapter => 0,
	    audio => 1,
	    chan_type => "tv",
	    channel => "_adummy",
	    date => "2008-06-10",
	    duration => "01:00:00",
	    episode => 2,
	    genre => undef,
	    num_episodes => 6,
	    pid => 29130,
	    repeat => 0,
	    start => "10:30:00",
	    text => "This is a test program",
	    title => "a test program",
	    video => 1,
	  },
	];
	
	# After delete...
	my $After_delete = [] ;

	my $pid = 29130 ;
	my $start_pid = $pid ;
	my $start_chan = '_adummy' ;
	
	check($app, $vars_href, $start_pid, $start_chan, $Just_stored, "select$name") ;
	check($app, $vars_href, 0,          $start_chan, $All_stored,  "select$name") ;
	check($app, $vars_href, 0,          $start_chan, $Grouped,     "select_group$name") ;
	
	$vars_href->{'pid'} = $start_pid ;
	$app->sql->sth_query("delete$name") ;
	
	check($app, $vars_href, 0, $start_chan, $After_delete, "select$name") ;

}

#----------------------------------------------------------
sub check
{
	my ($app, $sql_vars_href, $pid, $chan, $expected_ref, $query_name) = @_ ;

	## now get results back
	$sql_vars_href->{'pid'} = $pid ;
	$sql_vars_href->{'channel'} = $chan ;
	
	## demo a select transaction - could have done this as:
	# my @results = $app->sql->sth_query_all('select');
	#
	my @results = $app->sql->sth_query_all($query_name) ;

	## compare results
	is_deeply(\@results, $expected_ref, "Table contents match expected");
}




#=================================================================================
# SETUP
#=================================================================================

__DATA__

[SUMMARY]
Tests the application object with SQL

[DESCRIPTION]

B<$name> will ensure that table 'listings2' is created in the specified database. It will then
add some rows, show them, and then delete them.


[OPTIONS]

-host=s	Database host [default=localhost]

Specify the database host machine

-database=s	Database name [default=test]

Specify the database name to use

-table=s	Table name [default=sqltest]

Specify a different table (note that this example will only ensure that table 'sqltest' is created')

-user=s User

Your MySql user

-password=s	Pass

Your MySql password


__#=============================================================================================================================
__DATA__ sqltest.sql

-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Feb 26, 2009 at 12:13 PM
-- Server version: 5.0.51
-- PHP Version: 5.2.6
-- 
-- Database: `test`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `sqltest`
-- 

DROP TABLE IF EXISTS `sqltest`;
CREATE TABLE IF NOT EXISTS `sqltest` (
  `pid` varchar(128) NOT NULL,
  `title` varchar(128) NOT NULL,
  `date` date NOT NULL,
  `start` time NOT NULL,
  `duration` time NOT NULL,
  `episode` int(11) default NULL,
  `num_episodes` int(11) default NULL,
  `repeat` varchar(128) default NULL,
  `text` longtext NOT NULL,
  `channel` varchar(128) NOT NULL,
  `adapter` tinyint(8) NOT NULL default '0' COMMENT 'DVB adapter number',
  `genre` varchar(256) default NULL,
  `chan_type` varchar(256) NOT NULL default 'tv',
  `audio` tinyint(1) default '1',
  `video` tinyint(1) default '1',
  KEY `pid` (`pid`),
  KEY `chan_date_start_duration` (`channel`,`date`,`start`,`duration`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

__#=============================================================================================================================
__END__

