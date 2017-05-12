#!/usr/bin/perl
#
# Name:
#	test-simple-popup-radio.cgi.
#
# Purpose:
#	Test DBIx::HTML::PopupRadio.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use strict;
use warnings;

use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use DBI;
use DBIx::HTML::PopupRadio;
use Error qw/ :try /;

# -----------------------------------------------

delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'SHELL'}; # For security.

my($caption)	= 'Test DBIx::HTML::PopupRadio';
my($q)			= CGI -> new();
my($previous)	= $q -> param('dbix_menu') || '';

my(@html);

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

	my($popup_object) = DBIx::HTML::PopupRadio -> new(dbh => $dbh, sql => "select campus_id, campus_name from campus order by campus_name");

	# Or, use this code instead to trigger the msg: SQL returned no rows.

	#my($popup_object) = DBIx::HTML::PopupRadio -> new(dbh => $dbh, sql => "select campus_id, campus_name from campus where campus_name = 'x' order by campus_name");

	$popup_object -> set(default => 'Melbourne');

	my($popup_menu)	= $popup_object -> popup_menu();
	$popup_menu		= 'SQL returned no rows' if ($popup_object -> size() == 0);

	push(@html, $q -> th('Previous selection') . $q -> td($previous . ' => ' . $popup_object -> param($previous) ) );
	push(@html, $q -> th('Please choose a campus') . $q -> td($popup_menu) );
	push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	push(@html, $q -> th({colspan => 2}, $q -> submit({name => $caption, class => 'submit'}) ) );
}
catch Error::Simple with
{
	my($error) = 'Error::Simple: ' . $_[0] -> text();
	chomp($error);
	push(@html, $q -> th('Error') . $q -> td($error) );
};

print	$q -> header({type => 'text/html;charset=ISO-8859-1'}),
		$q -> start_html({style => {src => '/css/default.css'}, title => $caption}),
		$q -> h1({align => 'center'}, $caption),
		$q -> start_form({action => $q -> url(), name => 'dbix_form'}),
		$q -> table
		(
			{align => 'center', border => 1, class => 'submit'},
			$q -> Tr([@html])
		),
		$q -> end_form(),
		$q -> end_html();
