#!/usr/bin/perl
#
# Name:
#	test-linked-menus.cgi.

use strict;
use warnings;

use CGI;
use DBI;
use DBIx::HTML::LinkedMenus;
use Error qw/ :try /;

# -----------------------------------------------

my($caption)		= 'Test DBIx::HTML::LinkedMenus';
my($q)				= CGI -> new();
my($form_name)		= 'my_form';
my($base_name)		= 'base';	# Default: 'dbix_base_menu'.
my($linked_name)	= 'linker';	# Default: 'dbix_linked_menu'.
my($base_id)		= $q -> param($base_name)	|| undef;
my($link_id)		= $q -> param($linked_name)	|| undef;

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

	my($linker) = DBIx::HTML::LinkedMenus -> new
	(
		base_menu_name		=> $base_name,
		base_prompt			=> 'Please select an item from both menus',
		base_value			=> 0,
		linked_menu_name	=> $linked_name,
		linked_prompt		=> 'Please select 2 items',
		linked_value		=> 0,
		dbh					=> $dbh,
		form_name			=> $form_name,
		base_sql			=> 'select campus_id, campus_name, campus_id from campus order by campus_name',
		linked_sql			=> 'select unit_id, unit_code from unit where unit_campus_id = ? order by unit_code',
	) || throw Error::Simple('Base SQL returned 0 rows');

	# Either call javascript_for_on_load() or call javascript_for_init_menu().
	# For usage of the @on_load array, see the call to start_html().

	#@on_load = $linker -> javascript_for_on_load();

	push(@html, $linker -> javascript_for_db() );

	if (defined($base_id) && defined($link_id) )
	{
		my(@value) = $linker -> get($base_id, $link_id);

		push(@html, $q -> th('Base') . $q -> td($base_id . ' => ' . $value[0]) );
		push(@html, $q -> th('Link') . $q -> td($link_id . ' => ' . $value[1]) );
		push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	}

	push(@html, $q -> th('Base menu') . $q -> td($linker -> html_for_base_menu() ) );
	push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	push(@html, $q -> th('Linked menu') . $q -> td($linker -> html_for_linked_menu() ) );
	push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	push(@html, $q -> th({colspan => 2}, $q -> submit({name => $caption, class => 'submit'}) ) );
	push(@html, $linker -> javascript_for_init_menu() );
}
catch Error::Simple with
{
	my($error) = $_[0] -> text();
	chomp($error);
	push(@html, $q -> th('Error') . $q -> td($error) );
};

print	$q -> header({type => 'text/html;charset=ISO-8859-1'}),
		$q -> start_html({style => {src => '/css/default.css'}, title => $caption, @on_load}),
		$q -> h1({align => 'center'}, $caption),
		$q -> start_form({action => $q -> url(), name => $form_name}),
		$q -> table
		(
			{align => 'center', border => 1, class => 'submit'},
			$q -> Tr([@html])
		),
		$q -> end_form(),
		$q -> end_html();
