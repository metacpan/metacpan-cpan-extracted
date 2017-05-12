#!/usr/bin/perl
#
# Name:
#	test-complex-popup-radio.cgi.
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

my(%popup_data) =
(
	one	=>
	{	comment		=> 'Demonstrate returning an id when the user selects a name',
		default		=> '',			# Default menu item number.
		menu		=> '',			# Menu in HTML returned from menu object.
		name		=> 'campus_1',	# CGI name of menu.
		object		=> '',			# Menu object returned from DBIx::HTML::PopupRadio.
		order		=> 1,			# Sort order of menus down the page.
		previous	=> '',			# Previous user selection for this menu.
		prompt		=> '',			# Prompt at top of menu.
		sql			=> 'select campus_id, campus_name from campus',
	},
	two =>
	{	comment		=> 'Demonstrate returning a name when the user selects a name',
		default		=> '',
		menu		=> '',
		name		=> 'campus_2',
		object		=> '',
		order		=> 2,
		previous	=> '',
		prompt		=> '',			# See how we can select the column twice.
		sql			=> 'select campus_name, campus_name from campus',
	},
	three =>
	{	comment		=> 'Demonstrate a different SQL statement',
		default		=> '',
		menu		=> '',
		name		=> 'campus_3',
		object		=> '',
		order		=> 3,
		previous	=> '',
		prompt		=> '',
		sql			=> 'select campus_id, campus_name from campus order by campus_name',
	},
	four =>
	{	comment		=> 'Demonstrate a prompt at the top of the menu (but not a default)',
		default		=> '',
		menu		=> '',
		name		=> 'campus_4',
		object		=> '',
		order		=> 4,
		previous	=> '',
		prompt		=> 'Please select a campus from the list',
		sql			=> 'select campus_id, campus_name from campus order by campus_name',
	},
	five =>
	{	comment		=> 'Demonstrate a default menu selection (but not a prompt)',
		default		=> 'Geelong',
		menu		=> '',
		name		=> 'campus_5',
		object		=> '',
		order		=> 5,
		previous	=> '',
		prompt		=> '',
		sql			=> 'select campus_id, campus_name from campus',
	},
);
my(%radio_data) =
(
	one	=>
	{	comment		=> 'Demonstrate default = scc107m, linebreak = 0',
		default		=> 'scc107m',
		linebreak	=> 0,
		menu		=> '',			# Menu in HTML returned from menu object.
		name		=> 'radio_1',	# CGI name of menu.
		object		=> '',			# Menu object returned from DBIx::HTML::PopupRadio.
		order		=> 1,			# Sort order of menus down the page.
		previous	=> '',			# Previous user selection for this menu.
		sql			=> 'select unit_id, unit_code from unit order by unit_code',
	},
	two =>
	{	comment		=> 'Demonstrate default = scc109m, linebreak = 1',
		default		=> 'scc109m',
		linebreak	=> 1,
		menu		=> '',
		name		=> 'radio_2',
		object		=> '',
		order		=> 2,
		previous	=> '',
		sql			=> 'select unit_id, unit_code from unit order by unit_id',
	},
);

my($caption)				= 'Test DBIx::HTML::PopupRadio';
my($q)						= CGI -> new();
$popup_data{$_}{'previous'}	= $q -> param($popup_data{$_}{'name'}) || '' for keys %popup_data;
$radio_data{$_}{'previous'}	= $q -> param($radio_data{$_}{'name'}) || '' for keys %radio_data;

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

	for my $key (sort{$popup_data{$a}{'order'} <=> $popup_data{$b}{'order'} } keys %popup_data)
	{
		$popup_data{$key}{'object'} = DBIx::HTML::PopupRadio -> new(dbh => $dbh, name => $popup_data{$key}{'name'}, sql => $popup_data{$key}{'sql'});

		$popup_data{$key}{'object'} -> set(default => $popup_data{$key}{'default'});

		$popup_data{$key}{'menu'} = $popup_data{$key}{'object'} -> popup_menu(prompt => $popup_data{$key}{'prompt'});

		push(@html, $q -> th('Comment') . $q -> td($popup_data{$key}{'comment'}) );
		push(@html, $q -> th("Previous $popup_data{$key}{'name'}") . $q -> td($popup_data{$key}{'previous'} . ' => ' . $popup_data{$key}{'object'} -> param($popup_data{$key}{'previous'}) ) );
		push(@html, $q -> th('Default') . $q -> td($popup_data{$key}{'default'}) );
		push(@html, $q -> th('Prompt') . $q -> td($popup_data{$key}{'prompt'}) );
		push(@html, $q -> th('SQL') . $q -> td($popup_data{$key}{'sql'}) );
		push(@html, $q -> th('Campus') . $q -> td($popup_data{$key}{'menu'}) );
		push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	}

	for my $key (sort{$radio_data{$a}{'order'} <=> $radio_data{$b}{'order'} } keys %radio_data)
	{
		$radio_data{$key}{'object'} = DBIx::HTML::PopupRadio -> new(dbh => $dbh, name => $radio_data{$key}{'name'}, sql => $radio_data{$key}{'sql'});

		$radio_data{$key}{'object'} -> set(linebreak => $radio_data{$key}{'linebreak'});

		$radio_data{$key}{'menu'} = $radio_data{$key}{'object'} -> radio_group(default => $radio_data{$key}{'default'});

		push(@html, $q -> th('Comment') . $q -> td($radio_data{$key}{'comment'}) );
		push(@html, $q -> th("Previous $radio_data{$key}{'name'}") . $q -> td($radio_data{$key}{'previous'} . ' => ' . $radio_data{$key}{'object'} -> param($radio_data{$key}{'previous'}) ) );
		push(@html, $q -> th('Default') . $q -> td($radio_data{$key}{'default'}) );
		push(@html, $q -> th('Linebreak') . $q -> td($radio_data{$key}{'linebreak'}) );
		push(@html, $q -> th('SQL') . $q -> td($radio_data{$key}{'sql'}) );
		push(@html, $q -> th('Unit') . $q -> td($radio_data{$key}{'menu'}) );
		push(@html, $q -> th('&nbsp;') . $q -> td('&nbsp;') );
	}

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
