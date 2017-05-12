#!/usr/bin/perl
#
use strict ;
use App::Framework '+Sql' ;

# VERSION
our $VERSION = '1.001' ;

	# Create application and run it
	App::Framework->new()->go() ;



#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;
	
	# options
	my %opts = $app->options() ;

	# All named transactions use the values stored in this hash
	my %sql_vars ;

	# Set up database access
	$app->sql(
			'database'	=> $opts{'database'},
			'table'		=> $opts{'table'},
			'user'		=> $opts{'user'},
			'password'	=> $opts{'password'},
			
			# Option to do some Sql debugging by tracing transactions to a file
			'trace'		=> $opts{'debug'} ? 4 : 0,
			'trace_file'=> 'logsql.log',
			'debug' => $opts{'debug'},
			
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
			},
	) ;

	## demo of running sql stored as text in a __DATA__ section
	print "== Create table ===\n" ;
	$app->sql->sql_from_data("listings2.sql") ;

	## Do some inserts
	my $pid = $$ ;
	my $start_pid = $pid ;
	my $start_chan = '_adummy' ;
	
	%sql_vars = (
		'pid'	=> $start_pid,
		'channel' => $start_chan,
		'title' => 'a test program',
		'date' => '2008-06-10',
		'start' => '10:30',
		'duration' => '01:00',
		'episode' => 2,
		'num_episodes' => 6,
		'repeat' => 0,
		'text' => "This is a test program",
	) ;

	print "Insert pid=$sql_vars{'pid'}...\n" ;
	$app->sql->sth_query('insert') ;


	%sql_vars = (
		'pid'	=> ++$pid,
		'channel' => $start_chan,
		'title' => 'a test program 2',
		'date' => '2008-06-11',
		'start' => '11:30',
		'duration' => '01:00',
		'episode' => 2,
		'num_episodes' => 6,
		'repeat' => 0,
		'text' => "This is a test program",
	) ;
	print "Insert pid=$sql_vars{'pid'}...\n" ;
	$app->sql->sth_query('insert') ;
	
	%sql_vars = (
		'pid'	=> ++$pid,
		'channel' => $start_chan,
		'title' => 'a test program 3',
		'date' => '2008-06-12',
		'start' => '12:30',
		'duration' => '01:00',
		'episode' => 2,
		'num_episodes' => 6,
		'repeat' => 0,
		'text' => "This is a test program",
	) ;
	print "Insert pid=$sql_vars{'pid'}...\n" ;
	$app->sql->sth_query('insert') ;
	
	%sql_vars = (
		'pid'	=> ++$pid,
		'channel' => $start_chan,
		'title' => 'a test program 4',
		'date' => '2008-06-13',
		'start' => '13:30',
		'duration' => '01:00',
		'episode' => 2,
		'num_episodes' => 6,
		'repeat' => 0,
		'text' => "This is a test program",
	) ;
	print "Insert pid=$sql_vars{'pid'}...\n" ;
	$app->sql->sth_query('insert') ;
	
	
	
	show($app, \%sql_vars, $start_pid, $start_chan, "Just stored...") ;
	show($app, \%sql_vars, 0, $start_chan, "All stored...") ;
	show($app, \%sql_vars, 0, $start_chan, "Grouped", 'select_group') ;
	
	print "Delete..\n" ;
	$sql_vars{'pid'} = $start_pid ;
	$app->sql->sth_query('delete') ;
	
	show($app, \%sql_vars, 0, $start_chan, "After delete...") ;

}

#----------------------------------------------------------
sub show
{
	my ($app, $sql_vars_href, $pid, $chan, $title, $query_name) = @_ ;

	print "== $title =================\n" ;

	$query_name ||= 'select' ;
	
	## now get results back
	$sql_vars_href->{'pid'} = $pid ;
	$sql_vars_href->{'channel'} = $chan ;
	
	## demo a select transaction - could have done this as:
	# my @results = $app->sth_query_all('select');
	#
	$app->sql->sth_query($query_name) ;
	while (my $href = $app->sql->next($query_name))
	{
		foreach my $key (sort keys %$href)
		{
			print "$key=$href->{$key} " ;
		}
		print "\n" ;
	}
	
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

-database=s	Database name [default=test]

Specify the database name to use

-table=s	Table name [default=listings2]

Specify a different table (note that this example will only ensure that table 'listings2' is created')

-user=s User

Your MySql user

-password=s	Pass

Your MySql password


__#=============================================================================================================================
__DATA__ listings2.sql

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
-- Table structure for table `listings2`
-- 

DROP TABLE IF EXISTS `listings2`;
CREATE TABLE IF NOT EXISTS `listings2` (
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