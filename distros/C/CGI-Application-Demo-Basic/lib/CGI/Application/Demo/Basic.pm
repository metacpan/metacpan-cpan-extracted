package CGI::Application::Demo::Basic;

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

use CGI::Application::Demo::Basic::Util::Config;
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::Session;
use CGI::Simple;
use Class::DBI::Loader;

our $VERSION = '1.06';

# -----------------------------------------------

sub build_basic_pane
{
	my($self, $submit) = @_;
	my($content)       = $self -> load_tmpl('basic.tmpl');
	my($count)         = $self -> session -> param('count') || 0;

	$count++;

	$self -> session -> param(count => $count);

	my(@tr_loop);

	for my $table (sort keys %{$self -> param('cgi_app_demo_tables')})
	{
		my($class)       = ${$self -> param('cgi_app_demo_tables')}{$table};
		my(@column)      = $self -> get_columns($class);
		my(@column_name) = sort @{$column[2]};

		push @tr_loop,
		{
			th => 'Table',
			td => $table,
		},
		{
			th => 'Class',
			td => $class,
		},
		{
			th => 'Columns',
			td => join(', ', @column_name),
		},
	}

	$content -> param(count => "sub build_basic_pane has run $count time(s)");
	$content -> param(tr_loop => \@tr_loop);
	$content -> param(commands => $self -> build_commands_output
	([
		'Refresh',
	]) );
	$content -> param(notes => $self -> build_notes_output
	([
		'Hint: Click Refresh (below)',
		"Previous command: $submit",
	]) );

	return $content -> output;

}	# End of build_basic_pane.

# -----------------------------------------------

sub build_commands_output
{
	my($self, $command)   = @_;
	my($content)          = $self -> load_tmpl('commands.tmpl');
	my(@loop)             = ();
	my($max_column_count) = $self -> param('columns_of_commands_option');
	my($row_count)        = int( (@$command + $max_column_count - 1) / $max_column_count);
	my($command_index)    = - 1;

	my($row, $col);

	for $row (1 .. $row_count)
	{
		my(@td_loop);

		for $col (1 .. $max_column_count)
		{
			$command_index++;

			next if ($command_index > $#$command);

			if (ref($$command[$command_index]) eq 'ARRAY')
			{
				push @td_loop, {td => $$command[$command_index][0], onClick => $$command[$command_index][1]};
			}
			else
			{
				push @td_loop, {td => $$command[$command_index]};
			}
		}

		push @loop, {col_loop => \@td_loop};
	}

	$content -> param(commands => $#$command == 0 ? 'Command' : 'Commands');
	$content -> param(row_loop => \@loop);

	return $content -> output;

}	# End of build_commands_output.

# -----------------------------------------------

sub build_notes_output
{
	my($self, $note) = @_;
	my($content)     = $self -> load_tmpl('notes.tmpl');
	my(@loop)        = ();

	push @loop, {td => $_} for (@$note);

	$content -> param(note_loop => \@loop);

	return $content -> output;

}	# End of build_notes_output.

# -----------------------------------------------

sub build_options_pane
{
	my($self, $submit) = @_;
	my($content)       = $self -> load_tmpl('options.tmpl');
	my(@key)           = sort keys %{${$self -> param('key')}{'option'} };

	my(@loop, $minimum, $maximum, $s);

	for (@key)
	{
		$minimum = ${$self -> param('key')}{'option'}{$_}{'minimum'};
		$maximum = ${$self -> param('key')}{'option'}{$_}{'maximum'};
		($s      = $_) =~ s/_option$//;
		$s       =~ tr/_/ /;
		$s       = "Number of $s ($minimum .. $maximum)";

		push @loop,
		{
			option => $s,
			name   => $_,
			value  => $self -> session -> param($_),
		};
	}

	$content -> param(commands => $self -> build_commands_output
	([
		['Update options', q|onClick = "set('update_options')"|],
	]) );
	$content -> param(notes => $self -> build_notes_output
	([
		'DSN: ' . $self -> param('dsn'),
		"Previous command: $submit",
	]) );
	$content -> param(tr_loop => \@loop);

	return $content -> output;

}	# End of build_options_pane.

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
	my($config) = CGI::Application::Demo::Basic::Util::Config -> new('basic.conf') -> config;

	# All this stuff is here so that we can call
	# CGI::Application::Plugin::LogDispatch's log_config, if at all,
	# in cgiapp_init (as suggested by its docs) rather than in setup.

	$self -> param(config => $config);
	$self -> param(css_url => $$config{'css_url'});
	$self -> param(dsn => $$config{'dsn'});
	$self -> param(title => $$config{'dsn'});
	$self -> param(tmpl_path => $$config{'tmpl_path'});

	# Set up the classes for each table, via the magic of Class::DBI.
	# I have used a constraint because this is a demo, and I've only
	# created one module for Class::DBI to chew on:
	# CGI::Application::Demo::Basic::Faculty.

	my($loader) = Class::DBI::Loader -> new
	(
		constraint    => '^faculty$',
		dsn           => $$config{'dsn'},
		user          => $$config{'username'},
		password      => $$config{'password'},
		options       => $$config{'dsn_attribute'},
		namespace     => '',
		relationships => 1,
	);

    $self -> setup_db_interface($loader);
	$self -> param(dbh => ${$self -> param('cgi_app_demo_classes')}[0] -> db_Main);

	# Set up interface to logger.

	$self -> log_config
	(
		LOG_DISPATCH_MODULES =>
		[{
			dbh       => $self -> param('dbh'),
			min_level => 'info',
			module    => 'CGI::Application::Demo::Basic::Util::LogDispatchDBI',
			name      => __PACKAGE__,
		},
		]
	);

	# Set up interface to CGI::Session.

	$self -> session_config
	(
		CGI_SESSION_OPTIONS => [$$config{'session_driver'}, $self -> query, {Handle => $self -> param('dbh')}],
		DEFAULT_EXPIRY      => $$config{'session_timeout'},
		SEND_COOKIE         => 0,
	);

	# Recover options from session, if possible.
	# If not, initialize them.
	# This hash holds details of the set of options.

	$self -> param(key =>
	{
		option =>
		{
			columns_of_commands_option =>
			{
				default => 3,
				maximum => 20,
				minimum => 1,
				size    => 2,
				type    => 'integer',
			},
			records_per_page_option =>
			{
				default => 100,
				maximum => 1000,
				minimum => 1,
				size    => 4,
				type    => 'integer',
			},
		},
	});

	my(@key) = keys %{${$self -> param('key')}{'option'} };

	$self -> param($_ => $self -> session -> param($_) ) for @key;

	# Pick any option to see if they've all be initialized.

	if (! $self -> param('records_per_page_option') )
	{
		my($value);

		for (@key)
		{
			$value = ${$self -> param('key')}{'option'}{$_}{'default'};

			$self -> param($_ => $value);
			$self -> session -> param($_ => $value);
		}
	}

}	# End of cgiapp_init.

# --------------------------------------------------
# Note: This code retrieves the config in order to access 'dsn'.
# This illustrates a different method of accessing config data
# than, say, sub setup. The latter uses the fact that some data
# (tmpl_path) has been copied out of the config into an app param.
# This copying took place near the start of sub cgiapp_init.
# In the same way (as the latter technique) sub start uses
# css_url, which was also copied in sub cgiapp_init.

sub db_vendor
{
	my($self)   = @_;
	my($config) = $self -> param('config');
	my($vendor) = $$config{'dsn'} =~ /[^:]+:([^:]+):/;

	return uc $vendor;

}	# End of db_vendor.

# -----------------------------------------------
# Given a class we return an array of 3 elements:
# 0: An array ref of primary column names
# 1: An array ref of all other column names
# 2: An array ref of all column names
# The names are in the order returned by the class, which is best because
# the database designer probably set up the table with the columns in a
# specific order, and the names of the primary key columns are in a
# specific order anyway. And the caller can sort the [1] if desired.

sub get_columns
{
	my($self, $class)   = @_;
	my(@column)         = $class -> columns;
	my(@primary_column) = $class -> primary_columns;

	my(%primary_column);

	@primary_column{@primary_column} = (1) x @primary_column;
	my(@other_column)                = grep{! $primary_column{$_} } @column;

	return ([@primary_column], [@other_column], [@column]);

}	# End of get_columns.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start, update_options => \&update_options);
	$self -> tmpl_path($self -> param('tmpl_path') );

}	# End of setup.

# -----------------------------------------------

sub setup_db_interface
{
	my($self, $parameter ) = @_;
	my($classes)           = [];

	if (ref($parameter) eq 'ARRAY')
	{
		for my $cdbi_class (@$parameter)
		{
			# Check to see if it's loaded already.

			if (! $cdbi_class::)
			{
				my($file) = $cdbi_class;
				$file     =~ s|::|/|g;

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
		my($table)       = $cdbi_class -> table;
		$$tables{$table} = $cdbi_class;
	}

	$self -> param(cgi_app_demo_tables => $tables);

}	# End of setup_db_interface.

# -----------------------------------------------

sub start
{
	my($self)     = shift;
	my($config)   = $self -> param('config');
	my($submit)   = $self -> query -> param('submit') || '';
	my($template) = $self -> load_tmpl($$config{'tmpl_name'});
	my($content)  = $self -> build_basic_pane($submit) . $self -> build_options_pane($submit);

	$template -> param(content => $content);
	$template -> param(css_url => $self -> param('css_url') );
	$template -> param(rm => $self -> query -> param('rm') );
	$template -> param(sid => $self -> session -> id);
	$template -> param(title => $self -> param('title') );
	$template -> param(url => $self -> query -> url . $self -> query -> path_info);

	return $template -> output;

}	# End of start.

# -----------------------------------------------

sub update_options
{
	my($self) = @_;
	my(@key)  = keys %{${$self -> param('key')}{'option'} };

	$self -> log -> info('Called update_options');

	my($value, $default, $minimum, $maximum);

	for (@key)
	{
		$default = ${$self -> param('key')}{'option'}{$_}{'default'};
		$minimum = ${$self -> param('key')}{'option'}{$_}{'minimum'};
		$maximum = ${$self -> param('key')}{'option'}{$_}{'maximum'};
		$value   = $self -> query -> param($_);
		$value   = $default if (! defined($value) || ($value < $minimum) || ($value > $maximum) );

		$self -> param($_ => $value);
		$self -> session -> param($_ => $value);
	}

	return $self -> start;

}	# End of update_options.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<CGI::Application::Demo::Basic> - A vehicle to showcase C<CGI::Application>

=head1 Synopsis

basic.cgi:

	#!/usr/bin/perl

	use strict;
	use warnings;

	use CGI::Application::Demo::Basic;

	# -----------------------------------------------

	delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'PATH', 'SHELL'}; # For security.

	CGI::Application::Demo::Basic -> new -> run;

=head1 Description

C<CGI::Application::Demo::Basic> showcases C<CGI::Application>-based applications, via these components:

=over 4

=item o A set of 7 CGI instance scripts

=item o A set of 4 text configuration files

=item o A CSS file

=item o A data file to help bootstrap populating the database

=item o A set of 5 command line scripts, to bootstrap populating the database

=item o A set of 10 HTML::Templates

=item o A set of 11 Perl modules

=over 4

=item o CGI::Application::Demo::Basic

=item o CGI::Application::Demo::Basic::One

The five modules One.pm .. Five.pm, and Basic.pm, have been designed so as to be graduated in complexity from
simplistic to complex, to help you probe the preculiarities of a strange environment.

Each module ships with a corresponding config file, instance script and template. Well, actually, One.pm and Two.pm are too simple
to warrant their own config files, and One.pm does not even need a template.

=item o CGI::Application::Demo::Basic::Two

=item o CGI::Application::Demo::Basic::Three

=item o CGI::Application::Demo::Basic::Four

=item o CGI::Application::Demo::Basic::Five

=item o CGI::Application::Demo::Basic::Base

=item o CGI::Application::Demo::Basic::Faculty

=item o CGI::Application::Demo::Basic::Util::Config

=item o CGI::Application::Demo::Basic::Util::Create

The code to drop tables, create tables, and populate tables is all in this module.

This was a deliberate decision. For example, when everything is up and running,
there is no need for your per-table modules such as
C<Faculty.pm> to contain code to do with populating tables, especially constant tables
(as C<faculty> is in this demo).

=item o CGI::Application::Demo::Basic::Util::LogDispatchDBI

=back

=back

This module, C<CGI::Application::Demo::Basic>, demonstrates various features available to programs based on C<CGI::Application>:

=over 4

=item o Probing a strange environment

=item o Run modes and their subs

=item o Disk-based session handling

=item o Storing the session id in a hidden CGI form field

=item o Using the session to store user-changeable options

=item o Using C<Class::DBI> and C<Class::DBI::Loader> to auto-generate code per database table

Yes, I know C<Class::DBI> has been superceded by C<DBIx::Class> and C<Rose>.

=item o Using C<HTML::Template> style templates

=item o Changing the run mode with Javascript

=item o Overriding the default query object

This replaces a C<CGI> object with a lighter-weight C<CGI::Simple> object.

And yes, bug fixes for C<CGI::Simple> have not kept up with those for C<CGI>.

This is a demo, ok?

=item o Initialization via a configuration file

=item o Switching database servers via the config file

=item o Logging to a database table

=item o Multiple inheritance, to support MySQL, Oracle, Postgres and SQLite neatly

See C<CGI::Application::Demo::Basic::Util::LogDispatchDBI>.

=back

Note: Because I use C<Class::DBI::Loader>, which wants a primary key in every table, and I use C<CGI::Session>,
I changed the definition of my 'sessions' table - compared to what is recommended in the C<CGI::Session> docs -
from this:

	create table sessions
	(
		id char(32) not null unique,
		a_session text not null
	);

to this:

	create table sessions
	(
		id char(32) not null primary key, # I.e.: 'unique' => 'primary key'.
		a_session text not null           # For Oracle, 'text' => 'long'.
	);

Also, as you add complexity to this code, you may find it necessary to change line 10 of Base.pm from this:

	use base 'Class::DBI';

to something like this:

	use base $^O eq 'MSWin32' ? 'Class::DBI' : 'Class::DBI::Pg'; # Or 'Class::DBI::Oracle';

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See C<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing distros.

=head1 Patching config file and templates, and running CGI scripts

Unpack the distro, and you will see various files which may need to be
patched before running the CGI scripts.

Almost all config options are in text files, to handle different operating
environments.

Files and patches:

=over 4

=item o scripts/test.conf.pl

No patches needed, so run it now.

=item o scripts/create.pl

This uses lib/CGI/Application/Demo/Basic/Util/basic.conf, so patch this
file (i.e. the dsn).

If not using SQLite, you will need to create a database at this point.

Then run this script to create the tables.

=item o scripts/populate.pl

This uses the same config file as scripts/create.pl, so you can run
populate.pl straight away.

=item o scripts/drop.pl

Later, you can start over by running drop.pl, and then create.pl and populate.pl.

=item o scripts/create.1.table.pl

This just demonstates how to re-create a single table.

=item o cgi-bin/ca.demo.basic/lib.cgi

Copy all cgi-bin/ca.demo.basic/*.cgi scripts to your cgi-bin/ dir now.

Under Debian, this is /usr/lib/cgi-bin, and you will need sudo.

lib.cgi does not use any modules from this distro, so you can run it immediately,
just to make sure things outside this distro are working.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/lib.cgi>.

When that is working, move on.

=item o cgi-bin/ca.demo.basic/one.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses One.pm. It has no config file and no template file.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/one.cgi>.

This adds usage of a module based on C<CGI::Application>, but the module itself has, deliberately, no complexity of its own.
It simple displays a built-in web page.

When that is working, move on.

=item o cgi-bin/ca.demo.basic/two.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses Two.pm. It has no config file, but does have a template file,
htdocs/assets/templates/CGI/Application/Demo/Basic/Util/two.tmpl.

Copy all htdocs/assets/templates/CGI/Application/Demo/Basic/Util/*.tmpl files
to somewhere suitable.

Under Debian, I use /var/www/assets/templates/CGI/Application/Demo/Basic/Util/,
and my docroot is /var/www.

So, I use:

	sudo cp -r htdocs/assets/* /var/www/assets

This copies the CSS file too.

These templates use C<HTML::Template>.

Patch line 42 of Two.pm, which hard codes the path to the template file.

Later modules (you will be glad to know) have this path in a config file.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/two.cgi>.

This adds:

=over 4

=item o Replacing C<CGI> with C<CGI::Simple>

See C<sub cgiapp_get_query>.

=item o Using C<HTML::Template>-style templates

See C<sub cgiapp_init> and C<sub start>.

=back

When that is working, move on.

=item o cgi-bin/ca.demo.basic/three.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses Three.pm. It has both a config file,
lib/CGI/Application/Demo/Basic/Util/three.conf, and a template file,
htdocs/assets/templates/CGI/Application/Demo/Basic/three.tmpl.

Nothing in three.tmpl needs editing, but you will need to patch
the tmpl_path in three.conf.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/three.cgi>.

This adds:

=over 4

=item o Using C<CGI::Application::Demo::Basic::Util::Config> and C<Config::Tiny>

Here for the first time we read a config file.

=back

When that is working, move on.

=item o cgi-bin/ca.demo.basic/four.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses Four.pm. It has both a config file,
lib/CGI/Application/Demo/Basic/Util/four.conf, and a template file,
htdocs/assets/templates/CGI/Application/Demo/Basic/four.tmpl.

Nothing in four.tmpl needs editing, but you will need to patch css_url,
dsn and tmpl_path in four.conf.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/four.cgi>.

This adds:

=over 4

=item o Using a CSS file

=item o Getting the URL of the CSS file from the config file

=item o Getting a DSN, username, password and attributes from the config file

So, now we are testing a more complex config file.

=item o Use C<DBI>

And we use those parameters to test a direct connexion to the database.

We use this connexion to display all records in the C<faculty> table..

The C<faculty> table has no purpose other than to provide data to be displayed, either via C<DBI> or via C<Class::DBI>.

=back

When that is working, move on.

=item o cgi-bin/ca.demo.basic/five.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses Five.pm. It has both a config file,
lib/CGI/Application/Demo/Basic/Util/five.conf, and a template file,
htdocs/assets/templates/CGI/Application/Demo/Basic/five.tmpl.

Nothing in five.tmpl needs editing, but you will need to patch css_url,
dsn and tmpl_path in five.conf.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/five.cgi>.

This adds:

=over 4

=item o Using a base module, C<Base.pm>, for all table modules

Actually, there is only per-table module, Faculty.pm, at this time, but at least you can see how to use a base module to share code
across table modules.

=item o Using a dedicated module for the C<faculty> table: C<Faculty.pm>

=item o Using C<Class::DBI::Loader>

This uses C<Class::DBI> to automatically load a module-per-table.

As above, we just display all records in the C<faculty> table.

=back

By now, if successful, you will have tested all the components one-by-one.

So, the next step is obvious...

=item o cgi-bin/ca.demo.basic/basic.cgi

If using local::lib, edit line 3, otherwise delete it.

This uses Basic.pm. It has both a config file,
lib/CGI/Application/Demo/Basic/Util/basic.conf, and a template file,
htdocs/assets/templates/CGI/Application/Demo/Basic/basic.tmpl.

This is the same basic.conf whose dsn you patched above before running
create.pl.

Nothing in basic.tmpl needs editing, but you will need to patch css_url
and tmpl_path in basic.conf.

Hit C<http://127.0.0.1/cgi-bin/ca.demo.basic/basic.cgi>.

This adds

=over 4

=item o Using C<CGI::Application::Plugin::LogDispatch>

Now we log things to a database table via C<LogDispatchDBI.pm> (below).

=item o Using C<CGI::Application::Plugin::Session>

Now we use sessions stored in the database via C<CGI::Session>.

Install my module C<CGI::Session::Driver::oracle>, if necessary.

=item o C<Base.pm>

A module to share code between all per-table modules.

=item o C<Faculty.pm>

A module dedicated to a specific table.

=item o C<LogDispatchDBI.pm>

A module to customize logging via C<Log::Dispatch::DBI>.

=back

=back

=head1 Order of Execution of subs within a C<CGI::Application>-based script:

The section gives some background information on what takes place when a script
based on C<CGI::Application> is executed.

See also this article on the wiki: C<http://cgi-app.org/index.cgi?OrderOfOperations>.

=head2 Initializing your module

The instance script (basic.cgi - see Synopsis) contains 'use CGI::Application::Demo::Basic',
which causes Perl to load the file /perl/site/lib/CGI/Application/Demo/Basic.pm.

At this point the instance script is initialized, in that package C<CGI::Application::Demo::Basic>
has been loaded. The script has not yet started to run.

This package contains "use parent 'CGI::Application'", meaning C<CGI::Application::Demo::Basic> is a
descendent of C<CGI::Application>. That is, C<CGI::Application::Demo::Basic> is-a C<CGI::Application>.

This (C<CGI::Application::Demo::Basic>) is what I will call our application module.

What is confusing is that application modules can declare various hooks (a hook is an
alias for a sub) to be run before the sub corresponding to the current run mode.

Two of these hooked subs are called cgiapp_init (hook is 'init'), and cgiapp_prerun (hook is 'prerun').

Further, a sub prerun_mode is also available.

None of these 3 sub are called yet, if at all.

=head2 Calling new()

Now CGI::Application::Demo::Basic -> new is called.

This is, it initializes a new object of type C<CGI::Application>.

This includes calling the 'init' hook (sub cgiapp_init) and sub setup, if any.

Since we did in fact declare a sub cgiapp_init (hook is 'init'), that gets called,
and since we also declared a sub setup, that then gets called too.

You can see the call to setup at the very end of sub new within C<CGI::Application>.

Oh, BTW, during the call to cgiapp_init, there was a call to sub setup_db_interface,
which, via the magic of C<Class::DBI::Loader>, tucks away an array ref of a list of classes, one
per database table, in the statement $self -> param(cgi_app_demo_classes => $classes), and an
array ref of a list of table names in the statement $self -> param(cgi_app_demo_tables => $tables).

=head2 Calling run()

Now CGI::Application::Demo::Basic -> run is called.

First, this calls our sub cgiapp_get_query via a call to sub query, which we declared
in order to use a light-weight object of type C<CGI::Simple>, rather than an object of type C<CGI>.

Then, eventually, our application module's run mode sub is called, which defaults to sub start.

So, sub start is called, and it does whatever we told it to do. The app is up and running, finally.

=head1 A Note about C<HTML::Entities>

In general, a CGI::Application-type app could be outputting any type of data whatsoever,
and will need to protect that data by encoding it appropriately. For instance, we want
to stop arbitrary data being interpreted as HTML.

The sub C<HTML::Entities::encode_entities> is designed for precisely this purpose.
See that module's docs for details.

Now, in order to call that sub from within a double-quoted string, we need some sort
of interpolation facility. Hence the module C<HTML::Entities::Interpolate>.
See its docs for details.

This demo does not yet need or use C<HTML::Entities::Interpolate>.

=head1 Test Environments

I tested the new C<CGI::Application::Demo::Basic> in these environments:

=over 4

=item Debian, Perl 5.10.1, SQLite 3.6.22, Apache 2.2.14

=item Debian, Perl 5.10.1, Postgres 8.4.2, Apache 2.2.14

=back

I tested the original C<CGI::Application::Demo> in these environments:

=over 4

=item GNU/Linux, Perl 5.8.0, Oracle 10gR1, Apache 1.3.33

=item GNU/Linux, Perl 5.8.0, Postgres 7.4.7, Apache 2.0.46

=item Win2K, Perl 5.8.6, MySQL 4.1.9, Apache 2.0.52

=back

=head1 Credits

I drew significant inspiration from code in the C<CGI::Application::Plugin::BREAD> project:

C<http://charlotte.pm.org/kwiki/index.cgi?BreadProject> (off-line 2010-04-23).

=head1 Author

C<CGI::Application::Demo::Basic> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

Home page: C<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
