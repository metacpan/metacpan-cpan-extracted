package CGI::Application::Demo::Basic::Five;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use base 'CGI::Application';
use strict;
use warnings;

require 5.005_62;

use CGI::Application::Demo::Basic::Base;
use CGI::Application::Demo::Basic::Faculty;
use CGI::Application::Demo::Basic::Util::Config;
use CGI::Simple;
use Class::DBI::Loader;

our $VERSION = '1.06';

# -----------------------------------------------

sub cgiapp_get_query
{
	my($self) = @_;

	return CGI::Simple -> new;

}	# End of cgiapp_get_query.

# -----------------------------------------------

sub cgiapp_init
{
	my($self)   = @_;
	my($config) = CGI::Application::Demo::Basic::Util::Config -> new('five.conf') -> config;

	$self -> param(config => $config);
	$self -> param(tmpl_path => $$config{'tmpl_path'});

	# Set up the classes for each table, via the magic of Class::DBI.
	# I have used a constraint because this is a demo, and I've only
	# created one module for Class::DBI to chew on:
	# CGI::Application::Demo::Basic::Faculty.

	my($loader) = Class::DBI::Loader -> new
	(
		constraint		=> '^faculty$',
		dsn				=> $$config{'dsn'},
		user			=> $$config{'username'},
		password		=> $$config{'password'},
		namespace		=> '',
		relationships	=> 1,
	);

    $self -> setup_db_interface($loader);
	$self -> param(dbh => ${$self -> param('cgi_app_demo_classes')}[0] -> db_Main);

}	# End of cgiapp_init.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start);
	$self -> tmpl_path($self -> param('tmpl_path') );

}	# End of setup.

# -----------------------------------------------

sub setup_db_interface
{
	my($self, $parameter )	= @_;
	my($classes)			= [];

	if (ref($parameter) eq 'ARRAY')
	{
		for my $cdbi_class (@$parameter)
		{
			# Check to see if it's loaded already.

			if (! $cdbi_class::)
			{
				my($file)	= $cdbi_class;
				$file		=~ s|::|/|g;

				eval
				{
					require "$file.pm";

					$cdbi_class -> import;
				};

				die "CGI::Application::Demo::Basic::setup_db_interface: Couldn't require class: $cdbi_class: $@" if ($@);
			}

			push @$classes, $cdbi_class;
		}
	}
	elsif (ref($parameter) =~ /^Class::DBI::Loader/)
	{
		push @$classes, $_ for $parameter -> classes;
	}
	else
	{
		my($ref) = ref($parameter);

		die "CGI::Application::Demo::Basic::setup_db_interface: Invalid parameter\nParameter must either be an array reference of Class::DBI classes or a Class::DBI::Loader object\nYou gave me a $ref object.";
	}

	$self -> param(cgi_app_demo_classes => $classes);

	my($tables) = {};

	for my $cdbi_class (@{$self -> param('cgi_app_demo_classes')})
	{
		my($table)			= $cdbi_class -> table;
		$$tables{$table}	= $cdbi_class;
	}

	$self -> param(cgi_app_demo_tables => $tables);

}	# End of setup_db_interface.

# -----------------------------------------------

sub start
{
	my($self)		= shift;
	my($config)		= $self -> param('config');
	my($template)	= $self -> load_tmpl($$config{'tmpl_name'});
	my($db_vendor)  = CGI::Application::Demo::Basic::Base -> db_vendor;
	my(@content)	=
	(
		'Time: ' . scalar localtime,
		'URL: ' . $self -> query -> url,
		'PathInfo: ' . $self -> query -> path_info,
		"CGI::Simple V $CGI::Simple::VERSION",
		"Class::DBI::Loader V $Class::DBI::Loader::VERSION",
		"DBI V $DBI::VERSION",
		'Template name: ' . $$config{'tmpl_name'},
		'Template path: ' . $self -> param('tmpl_path'),
		'DSN: ' . $$config{'dsn'},
		'Username: ' . $$config{'username'},
		'dbh: ' . $self -> param('dbh'),
		"DB vendor: $db_vendor",
	);

	# Test Class::DBI::Loader.

	my $iterator = CGI::Application::Demo::Basic::Faculty -> retrieve_all;

	while ($_ = $iterator -> next)
	{
		push @content, qq|<span class="$$config{'css_class'}">| . $_ -> faculty_id . ': ' . $_ -> faculty_name . '</span>';
	}

	$$self{'table'}	= 'log';
	my($sql)        = $db_vendor eq 'ORACLE'
		? "insert into $$self{'table'} (id, lvl, message, timestamp) values (log_seq.nextval, ?, ?, localtimestamp)"
		: $db_vendor eq 'SQLITE'
		? "insert into $$self{'table'} (lvl, message, timestamp) values (?, ?, 'now')"
		: "insert into $$self{'table'} (lvl, message, timestamp) values (?, ?, now() )"; # MySQL, Postgres.
	my($sth) = $self -> param('dbh') -> prepare($sql);

	$sth -> execute('info', __PACKAGE__ . ": Testing SQL: $sql");
	$sth -> finish;

	$template -> param(css_url => $$config{'css_url'});
	$template -> param(li_loop => [map{ {item => $_} } @content]);
	$template -> param(title => __PACKAGE__);

	$self -> param('dbh') -> disconnect;

	return $template -> output;

}	# End of start.

# -----------------------------------------------

1;
