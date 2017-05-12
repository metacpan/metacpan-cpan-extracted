package App::Office::Contacts;

use parent 'CGI::Snapp';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Digest::SHA;

use Text::Xslate 'mark_raw';

# We don't use Moo because we isa CGI::Snapp.

our $VERSION = '2.04';

# -----------------------------------------------

sub build_about_html
{
	my($self) = @_;

	$self -> log(debug => 'Contacts.build_about_html()');

	my($config)  = $self -> param('config');
#	my($user_id) = $self -> param('user_id');
#	my($user)    = $user_id ? $self -> param('db') -> person -> get_person_list($user_id, $user_id) : [{name => 'N/A'}];
#	$user        = $$user[0]{name} ? $$user[0]{name} : 'No-one is logged on';

	my(@row);

	push @row,
	{
		left => 'Program', right => "$$config{program_name} $$config{program_version}",
	},
	{
		left => 'Author', right => $$config{program_author},
	},
	{
		left => 'More help', right => qq|<a href="$$config{program_faq_url}">FAQ</a>|,
	};

	return $self -> _format_help(\@row);

} # End of build_about_html.

# -----------------------------------------------

sub build_error_html
{
	my($self) = @_;

	$self -> log(debug => 'Contacts.build_error_html()');

	return '<p align="center">No errors have been detected yet</p>';

} # End of build_error_html.

# -----------------------------------------------

sub build_web_page
{
	my($self) = @_;

	$self -> log(debug => 'Contacts.build_web_page()');

	# Generate the web page itself. This is not loaded by sub cgiapp_init(),
	# because, with Ajax, we only need it the first time the script is run.

	my($config) = $self -> param('config');
	my($param)  =
	{
		datatable_js_url      => $$config{datatable_js_url},
		demo_page_css_url     => $$config{demo_page_css_url},
		demo_table_css_url    => $$config{demo_table_css_url},
		fancy_table_css_url   => $$config{fancy_table_css_url},
		homepage_css_url      => $$config{homepage_css_url},
		html4about            => mark_raw($self -> build_about_html),
		html4add_organization => mark_raw($self -> param('view') -> organization -> build_add_html),
		html4add_person       => mark_raw($self -> param('view') -> person -> build_add_html),
		html4error            => mark_raw($self -> build_error_html),
		html4report           => mark_raw($self -> param('view') -> report -> build_report_html),
		html4search           => mark_raw($self -> param('view') -> search -> build_search_html),
	};

	return $self -> param('db') -> templater -> render('homepage.tx', $param);

} # End of build_web_page.

# -----------------------------------------------

sub _format_help
{
	my($self, $list) = @_;

	$self -> log(debug => 'Contacts._format_help()');

	my($html) = <<EOS;
<table class="display" id="help_div" cellpadding="0" cellspacing="0" border="0">
<thead>
<tr>
	<th align="left">Item</th>
	<th align="left">Explanation</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);
	my($left);
	my($right);

	for my $row (@$list)
	{
		$class = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';
		$left  = mark_raw($$row{left});
		$right = mark_raw($$row{right});
		$html  .= <<EOS;
<tr class="$class">
	<td>$left</td>
	<td>$right</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
</table>
EOS

	return $html;

} # End of _format_help.

# -----------------------------------------------

sub global_prerun
{
	my($self) = @_;

	$self -> log(debug => 'Contacts.global_prerun()');

	# Set up a few more things.

	$self -> param(system_error => '<response><error>Error: Software error</error><html>Contact your system administrator</html></response>');
	$self -> param(user_id => 0);      # 0 means we don't have anyone logged on.
	$self -> run_modes([qw/display/]); # Other controllers add their own run modes.

	# Log the CGI form parameters.

	my($q) = $self -> query;

	$self -> log(info => $q -> url(-full => 1, -path => 1) );
	$self -> log(debug => 'Request method: ' . $q -> request_method);

	for ($q -> param)
	{
		# Skip potentially big notes.

		if ($_ eq 'body')
		{
			my($note) = $q -> param($_);
			$note     = length($note) > 20 ? (substr($note, 0, 20) . '...') : $note;

			$self -> log(debug => "Param: $_: $note");
		}
		else
		{
			$self -> log(debug => "Param: $_: " . $q -> param($_) );
		}
	}

	# Set up the session. This tells us we got this far.

	$self -> log(info => 'Session id: ' . $self -> param('db') -> session -> id);

}	# End of global_prerun.

# -----------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log(debug => 'Contacts.teardown()');
	$self -> param('db') -> session -> flush;
	$self -> logger -> log_object -> disconnect; # The logger's log_object has its own dbh.
	$self -> logger -> simple -> disconnect;     # The logger's 'simple' object has a dbh.

} # End of teardown.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts - A web-based contacts manager

=head1 Synopsis

A classic CGI script, I<contacts.cgi>:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use CGI;
	use CGI::Snapp::Dispatch;

	# ---------------------

	my($cgi) = CGI -> new;

	CGI::Snapp::Dispatch -> new -> dispatch
	(
		args_to_new => {QUERY => $cgi},
		prefix      => 'App::Office::Contacts::Controller',
		table       =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

A L<Plack> script, I<contacts.psgi>:

	#!/usr/bin/env perl
	#
	# Run with:
	# starman -l 127.0.0.1:5003 --workers 1 httpd/cgi-bin/office/contacts.psgi &
	# or, for more debug output:
	# plackup -l 127.0.0.1:5003 httpd/cgi-bin/office/contacts.psgi &

	use strict;
	use warnings;

	use CGI::Snapp::Dispatch;

	use Plack::Builder;

	# ---------------------

	my($app) = CGI::Snapp::Dispatch -> new -> as_psgi
	(
		prefix => 'App::Office::Contacts::Controller',
		table  =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

	builder
	{
		enable "ContentLength";
		enable 'Static',
		path => qr!^/(assets|favicon)!,
		root => '/dev/shm/html';
		$app;
	};

The scripts discussed here, I<contacts.cgi> and I<contacts.psgi>, are shipped with this module,
in the httpd/ directory.

For more on Plack, see L<My intro to Plack|http://savage.net.au/Perl/html/plack.for.beginners.html>.

=head1 Description

C<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

Here 'private' means you can specify which contacts are not to appear in the search results of other
people using the same database. You do this by setting their visibility to 'Just me'.

C<App::Office::Contacts> uses the light-weight module L<Moo>.

Major features:

=over 4

=item o utf8-aware

=item o Any number of people

=item o Any number of organizations

=item o People can have any number of occupations

=item o Organizations can have any number of staff

=item o People and organizations can have any number of notes

These are displayed with the most recent notes first.

=item o Supports using any database server having a Perl interface

This is controlled via a config file.

=item o 1 to 4 email addresses per person or organization

4 was chosen just to limit the amount of screen real estate occupied. It can be easily changed.

=item o 1 to 4 phone numbers per person or organization

=item o Installers can provide their own FAQ page

=item o On-screen information hidden in tabs is updated if appropriate

For example, if you add a person to the staff list for an organization, and the details for that person
are on another, hidden, tab (the organization tab must have the focus), then the list of occupations for
that peson is updated as soon as they are added.

=item o jQuery-style autocomplete is used for various fields

The list of fields which support autocomplete are listed both on the appropriate forms and on the default
FAQ page.

=item o An add-on package supports importing vCards, as probably output by your email client

=item o An add-on package supports donations per person and per organization

But L<App::Office::Contacts::Donations> has not yet been updated to match V 2.00 of C<App::Office::Contacts>.

=back

Screen shots:

L<The database schema|http://savage.net.au/Module-reviews/images/Contacts/contacts.schema.png>.

L<Sample search results|http://savage.net.au/Module-reviews/images/Contacts/search.results.png>.

L<Sample personal details|http://savage.net.au/Module-reviews/images/Contacts/personal.details.png>.
The organizational details form is very similar.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing distros.

=head1 Installation

=head2 Installation Pre-requisites

=head3 A note to beginners

At various places I refer to a file, C<share/.htoffice.contacts.conf>,
shipped with this distro.

Please realize that if you edit this file, you must ensure the copy you are editing
is the one used by the code at run-time.

After a module such as this is installed, the code will look for that file
in the directory where I<you> have installed this config file, by running:

	shell> perl scripts/copy.config.pl

The module which reads the file is L<App::Office::Contacts::Util::Config>.

scripts/copy.config.pl installs C<.htoffice.contacts.conf> into a shared directory.

So, if you unpack the distro and edit the file within the unpacked code, you will still need
to copy the patched version by running:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

There is no need to restart your web server after updating this file.

=head3 jQuery, jQuery UI and DataTables

This module does not ship with any of these Javascript libraries. You can get them from:

	http://jquery.com/
	http://jqueryui.com/
	http://datatables.net/

Most development was done using jQuery V 1.8.1, which ships with jQuery V 1.9.2. Lastly, DataTables
V 1.9.4 was used too.

See C<share/.htoffice.contacts.conf>, around lines 23 .. 25 and 61 .. 63, where it
specifies the URLs used by the code to access these libs.

As always, do this after patching the config file:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head3 The database server

I use Postgres.

So, I create a user and a database, via psql, using:

	shell>psql -U postgres
	psql>create role contact login password 'contact';
	psql>create database contacts owner contact encoding 'UTF8';
	psql>\q

Then, to view the database after using the shipped Perl scripts to create and populate it:

	shell>psql -U contact contacts
	(password...)
	psql>...

If you use another server, patch C<share/.htoffice.contacts.conf>,
around lines 22 and 36, where it specifies the database DSN and the CGI::Session driver.

As always, do this after patching the config file:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head2 Installing the module

=head3 The Module Itself

Install C<App::Office::Contacts> as you would for any C<Perl> module:

Run:

	cpanm App::Office::Contacts

or run

	sudo cpan App::Office::Contacts

or unpack the distro, and then either:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

Either way, you need to install all the other files which are shipped in the distro.

=head3 Install the L<Text::Xslate> files

Copy the C<htdocs/assets/> directory, and all its subdirectories, from the distro to the doc root directory
of your web server.

Specifically, my doc root is C</dev/shm/html/>, so I end up with C</dev/shm/html/assets/>.

=head3 The Configuration File

Next, tell L<App::Office::Contacts> your values for some options. This includes the path to the files used
by L<Text::Xslate>.

For that, see C<share/.htoffice.contacts.conf> as discussed above.

After editing the config file, ensure you run C<scripts/copy.config.pl>. It will copy
the config file using L<File::ShareDir>, to a directory where the run-time code in
L<App::Office::Contacts> will look for it.

	shell>cd App-Office-Contacts-1.00
	shell>perl scripts/copy.config.pl
	shell>perl scripts/find.config.pl

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head3 Install the FAQ web page

In C<share/.htoffice.contacts.conf> there is a line:

	program_faq_url = /assets/templates/app/office/contacts/faq.html

This page is displayed when the user clicks FAQ on the About tab.

A sample page is shipped in C<htdocs/assets/templates/app/office/contacts/faq.html>.

So, copying the C<htdocs/assets/> directory, as above, will have installed this file.
Alternately, replace it with your own.

As always after editing the config file, run:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head3 Install the trivial CGI script and the Plack script

Copy the C<httpd/cgi-bin/office/> directory to the C<cgi-bin/> directory of your web server,
and make I<contacts.cgi> executable.

My C<cgi-bin/> dir is C</usr/lib/cgi-bin/>, so I end up with C</usr/lib/cgi-bin/office/contacts.cgi>.

Now I can run C<http://127.0.0.1/cgi-bin/office/contacts.cgi> (but not yet!).

=head3 Creating and populating the database

The distro contains a set of text files which are used to populate constant tables.
All such data is in the data/ directory.

This data is loaded into the 'contacts' database using programs in the distro.
All such programs are in the scripts/ directory.

After unpacking the distro, create and populate the database:

	shell>cd App-Office-Contacts-1.00
	# Naturally, you only drop /pre-existing/ tables :-),
	# so use drop.tables.pl later, when re-building the db.
	#shell>perl -Ilib scripts/drop.tables.pl -v
	shell>perl -Ilib scripts/create.tables.pl -v
	shell>perl -Ilib scripts/populate.tables.pl -v
	shell>perl -Ilib scripts/populate.fake.data.pl -v

Notes:

=over 4

=item If using -Ilib, Perl looks in the current directory structure for the modules

That is, Perl does not use the installed version of the code, if any.

=item The code looks in the shared directory structure for C<.htoffice.contacts.conf>

If you unpack the distro, and run:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

it will copy the config file to the install dir, and report where it is.

Alternately, edit the installed copy rather than the copy shipped with the distro.

=back

So, if you leave out the '-Ilib', Perl will use the version of the code which has been
formally installed.

=head3 Start testing

Point your broswer at C<http://127.0.0.1/cgi-bin/contacts.cgi>.

Your first search can then be just 'a', without the quotes.

=head1 Object attributes

=over 4

=item o See the parent module L<CGI::Snapp>

=back

=head1 Methods

=head2 build_about_html($user_id)

Creates a HTML table for the About tab.

Note: The code does not currently use $user_id. It is present as provision if the code is patched to
identify logged-on users. See the L</FAQ> for a discussion of this issue.

=head2 build_web_page()

Creates the basic web page in response to the very first request from the user.

=head2 global_prerun()

Contains code shared by this module and L<App::Office::Contacts::Donations>.

=head2 teardown()

Shuts down database connexions, etc, as the program is exiting.

=head1 FAQ

=head2 How do I delete an organization or person?

Search for them, and then set their visibility to No-one. Hence they stay in the database but are no
longer visible.

=head2 Is utf8 supported in V 2.00?

Yes. L<Text::CSV::Encoded> is used in C<App::Office::Contacts::Util::Import> to read data/fake.people.txt.

See L</Creating and populating the database> for a discussion of scripts/populate.fake.people.pl.

Do a search for Brocard, the author of the original L<GraphViz>, and you will find LE<233>on Brocard.

Also, see lines 48 .. 52 in the config file for options to control the utf8 setting in the connect() attributes
as used by L<DBI>. These are the defaults:

	mysql_enable_utf8 = 1
	# pg_enable_utf8 == 0 for DBD::Pg V 3.0.0 in my code.
	pg_enable_utf8    = 0
	sqlite_unicode    = 1

These values are used in App::Office::Contacts::Util::Logger lines 44 .. 57.

=head2 Why not allow multiple Facebook and Twitter tags per org or person?

This is under consideration.

=head2 How can I update the spouses table?

You cannot. I have not yet decided how to provide an on-screen mechanism to update this table.

=head2 How is the code structured?

MVC (Model-View-Controller).

The sample scripts I<contacts.cgi> and I<contacts> use

	prefix => 'App::Office::Contacts::Controller'

so the files in C<lib/App/Office/Contacts/Controller> and C<lib/App/Office/Contacts/Controller/Exporter> are the
modules which are run to respond to http requests.

Files in C<lib/App/Office/Contacts/View> implement views, and those in C<lib/App/Office/Contacts/Database>
implement the model.

Files in C<lib/App/Office/Contacts/Util> are a mixture:

=over 4

=item Config.pm

This is used by all code.

=item Create.pm

This is just used to create tables, populate them, and drop them.

Hence it will not be used by C<CGI> scripts, unless you write such a script yourself.

=item Validator.pm

This is used to validate CGI form data.

=back

=head2 Why did you use Sub::Exporter?

The way I wrote the code, various pairs of classes, e.g.
L<App::Office::Contacts::Controller::Note> and
L<App::Office::Contacts::Donations::Controller::Note>, could share a lot of code,
but they had incompatible parents. Sub::Exporter solved this problem.

And since Controller.pm is derived from CGI::Snapp and not Moo, we cannot use Moo::Role.

=head2 In the source, it seems you use singular words for the names of arrays and array refs.

Yes I do. I think in terms of the nature of each element, not the storage mechanism.

I have switched to plurals for the names of database tables though.

=head2 What is the database schema?

L<The database schema|http://savage.net.au/Module-reviews/images/Contacts/contacts.schema.png>.

The file was created with dbigraph.pl.

dbigraph.pl ships with C<GraphViz::DBI>. I patched it to use C<GraphViz::DBI::General>.

The command is:

	dbigraph.pl --dsn 'dbi:Pg:dbname=contacts' --user contact --pass contact > docs/contacts.schema.png

The username and password are as shipped in C<share/.htapp.office.contacts.conf>.

As always after editing the config file, run:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head2 Why do the email_addresses and phone_numbers tables have upper-case fields?

Because the search feature always uses upper-case. And, e.g., phones can have eXtension information built-in,
as in '123456x78'. So the 'x' in a search request needs to be upper-cased. And yes, I have worked on a
personnel + phone number system (at Monash University) which stores (Malaysian) phone numbers like that.

The case for email addresses is rather more obvious.

=head2 Does the database server have pre-requisites?

The code is DBI-based, of course.

Also, the code assumes the database server supports $dbh -> last_insert_id(undef, undef, $table_name, undef).

=head2 What engine type do you use when I use MySQL?

Engine type defaults to innodb when you use MySQL in the dsn.

See C<share/.htapp.office.contacts.conf> for the dsn and the source code of L<App::Office::Contacts::Util::Create>
for the create statements.

As always after editing the config file, run:

	shell> perl scripts/copy.config.pl
	shell> perl scripts/find.config.pl (as a cross-check)

Alternately, edit the installed copy rather than the copy shipped with the distro.

=head2 How do I add tables to the schema?

Do all of these things:

=over 4

=item o Choose a new name which does not conflict with names used by my add-on packages!

=item o Add the table initialization code to C<App::Office::Contacts::Util::Create>

You will need code to create, drop and (perhaps) populate your new table.

There are many examples already in that module.

=item o Add your code to utilize the new table

=back

=head2 Please explain the program, text file, and database table names

Programs are shipped in scripts/, and data files in data/.

I prefer to use '.' to separate words in the names of programs.

However, for database table names, I use '_' in case '.' would case problems.

Programs such as mail.labels.pl and populate.tables.pl, use table names for their data file
names. Hence the '_' in the names of their data files.

=head2 Where do I get data for Localities and Postcodes?

In Australia, a list of localities and postcodes is available from
L<http://www1.auspost.com.au/postcodes/>.

In America, you can buy a list from companies such as L<http://www.zipcodeworld.com/index.htm>,
who are an official re-seller of US Mail database.

The licence says the list cannot be passed on in its original format, but encoding it with
L<DBD::SQLite> solves that problem :-).

=head2 Is printing supported?

Not specifically, although a huge range of labels is supported via L<PostScript::MailLabels>.

Printing might one day be shipped as C<App::Office::Contacts::Export::StickyLabels>.

=head2 What is it with user_id and creator_id?

Ahhh, you have been reading the source code, eh? Well done!

Originally (i.e. in my home-use module Local::Contacts), users had to log on to use this code.

So, there was a known user at all times, and the modules used user_id to identify that user.

Then, when records in (some) tables were created, the value of user_id was stored in the creator_id field.

Now I take the view that you should implement Single Sign-on, meaning this set of modules is never
responsible to tracking who is logged on.

Hence this line in C<App::Office::Contacts::Controller>:

	$self -> param(user_id => 0); # 0 means we don't have anyone logged on.

That in turn means there is now no knowledge of the id of the user who is logged on, if any.

To match this, various table definitions have been changed, so that instead of C<App::Office::Contacts::Util::Create> using:

	creator_id integer not null, references people(id),

the code says:

	creator_id integer not null,

This allows a user_id of 0 to be stored in those tables.

Also, the transaction logging code (since deleted) could identify the user who made each edit.

=head2 What is special about Person id == 1?

Nothing. Very early versions of the code reserved this id, but that is not done now.

=head2 What about Occupation title id == 1?

In a similar manner (to Person id == 1), there is a special occupation title with id == 1, whose name is '-'.

This allow you to indicate someone works for a given organization without knowing exactly what their job is.

You can search for all such special code with 'ack Special'. ack is part of L<App::Ack>.

Do I<not> delete this occupation! It is needed. The delete/update occupation code checks to ensure you
do not delete it with this module, but of course there is always the possibility that you delete it using
some other tool.

=head2 What about Organization id == 1?

In a similar manner (to Occupation id == 1), there is a special organization with id == 1, whose name is '-'.

You can search for all such special code with 'ack Special'. ack is part of L<App::Ack>.

Do I<not> delete this organization! It is needed. The delete/update organization code checks to ensure you
do not delete it with this module, but of course there is always the possibility that you delete it using
some other tool.

=head2 What data files have fake data in them?

Their names match "data/fake.$table_name.txt".

=head2 Why use File::ShareDir and not File::HomeDir?

Some CPAN testers test with users who do not have home directories.

=head2 How many database handles are used?

2. One for DBIx::Simple (See L<App::Office::Contacts::Util::Logger>), which is used throughout
L<App::Office::Contacts::Database>, and one for L<Log::Handler::Output::DBI> (for which also see
L<App::Office::Contacts::Util::Logger>), which is used just for logging.

=head2 What scripts ship with this module?

All scripts are shipped in the scripts/ directory.

=over 4

=item o check.org.cgi.fields.pl

This compares the CGI form field names in the add_org_form CGI form to their equivalents in the
Javascript in htdocs/assets/templates/app/office/contacts/homepage.tx, and reports discrepancies.

The form is shipped in docs/add.organization.form.html which I copied from the web page displayed
when the program starts.

=item o check.template.pl

This just prints the output of a HTML template, to help debugging.

=item o copy.config.pl

This copy share/.htapp.office.contactcs.conf to a shared directory, as per the dist_dir() method in
L<File::ShareDir>.

=item o create.tables.pl

This creates the database tables. See L</Creating and populating the database>.

=item o drop.tables.pl

This drops the database tables. See L</Creating and populating the database>.

=item o export.as.csv.pl

This exports just the name and upper-case name from the people table. This is not really useful,
but does provide a template if you wish to expand the code.

It outputs to the file specified by the output_file option.

=item o export.as.html.pl

This exports just the name and upper-case name from the people table. This is not really useful,
but does provide a template if you wish to expand the code.

It has a C<standalone_page> option for using either a web page or just a table as the template.

It outputs a string.

=item o find.config.pl

This tells you where share/.htapp.office.contactcs.conf is installed, after running copy.config.pl.

=item o populate.db.sh

A bash script which runs a set of programs.

Warning: This includes drop.tables.pl.

=item o populate.fake.data.pl

This populates some database tables. See L</Creating and populating the database>.

=item o populate.tables.pl

This populates vital database tables. See L</Creating and populating the database>.

=item o utf8.1.pl

This helps me fight the dread utf8.

=item o utf8.2.pl

This prints singly- and doubly-encoded and decoded string, as a debugging aid.

=back

=head1 TODO

=over 4

=item o report.tx has a hidden field 'report_id'

This will be replaced with a menu when donations are re-implemented in V 2.00 of *::Donations.

=item o Adjust focus after Enter is hit inputting occupations

Currently, the focus goes to the Reset button and not the Add button in these cases (Occupation and Staff).

=item o If Search or Report get an error, the status line turns red (good) but still says OK (bad).

The error message is lost in these cases, and I cannot explain that.

=item o Should basic.table.tx be used instead of incorporating HTML in the source code?

See View::*::format_*().

The 2 enclosing divs in basic.table.tx could be optional, perhaps via a separate template.

=item o Some View::*::report_*() methods do too much

Code could be shifted into Database::*::save_*().

=item o Add date-of-birth

=item o Re-write L<App::Office::Contacts::Donations> for V 2.00

=item o Re-write L<App::Office::Contacts::Import::vCards> for V 2.00

Done.

=item o Write L<App::Office::Contacts::Sites> V 2.00

This provides N sites per person or organization.

The country/state/locality/postcode (zipcode) data will be shipped in SQLite format,
as part of this module.

Data for Australia and America with be included in the distro.

Note: The country/etc data is imported into whatever database you choose to use for
your contacts database, even if that is another SQLite database.

=back

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Office-Contacts>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
