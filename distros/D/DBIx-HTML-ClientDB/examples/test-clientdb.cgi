#!/usr/bin/perl
#
# Name:
#	test-clientdb.cgi.
#
# Purpose:
#	Test DBIx::HTML::ClientDB.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use strict;
use warnings;

use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use DBI;
use DBIx::HTML::ClientDB;
use Error qw/ :try /;

# -----------------------------------------------

delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'SHELL'}; # For security.

my($caption)	= 'Test DBIx::HTML::ClientDB';
my($q)			= CGI -> new();
my($id)			= $q -> param('dbix_client_menu') || '';

my(@on_load, @html);

try
{
	my($dbh) = DBI -> connect
	(
		'DBI:mysql:test:127.0.0.1',
		'root',
		'pass',
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

	my($object) = DBIx::HTML::ClientDB -> new(max_width => 0, dbh => $dbh, border => 1, default => 'scc109m', row_headings => 'Unit code,Unit code,Campus name,Unit name', sql => "select unit_code, unit_code, campus_name, unit_name from unit, campus where unit_campus_id = campus_id order by unit_code");
	my($db)		= $object -> javascript_for_client_db();
	my($table)	= $object -> table();

	if ($object -> size() == 0)
	{
		$table = 'SQL returned no rows';
	}
	else
	{
		# Either call javascript_for_client_on_load() or javascript_for_client_init().
		# For usage of the @on_load array, see the call to start_html().

		#@on_load	= $object -> javascript_for_client_on_load();
		$table		= $db . $table;
	}

	if ($id)
	{
		my(@data) = $object -> param($id);
		push(@html, $q -> th('Previous selection') . $q -> td(join('<br />', @data) ) );
		push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	}

	push(@html, $q -> th('Please choose a unit') . $q -> td($table) );
	push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	push(@html, $q -> th({colspan => 2}, $q -> submit({name => $caption, class => 'submit'}) ) );
	push(@html, $object -> javascript_for_client_init() );
}
catch Error::Simple with
{
	my($error) = 'Error::Simple: ' . $_[0] -> text();
	chomp($error);
	push(@html, $q -> th('Error') . $q -> td($error) );
};

print	$q -> header({type => 'text/html;charset=ISO-8859-1'}),
		$q -> start_html({style => {src => '/css/default.css'}, title => $caption, @on_load}),
		$q -> h1({align => 'center'}, $caption),
		$q -> start_form({action => $q -> url(), name => 'dbix_client_form'}),
		$q -> table
		(
			{align => 'center', border => 1, class => 'submit'},
			$q -> Tr([@html])
		),
		$q -> end_form(),
		$q -> end_html();
