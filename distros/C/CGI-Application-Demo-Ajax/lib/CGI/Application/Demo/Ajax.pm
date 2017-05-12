package CGI::Application::Demo::Ajax;

# Author:
#	Ron Savage <ron@savage.net.au>
#
# Note:
#	\t = 4 spaces || die.

use base 'CGI::Application';
use strict;
use warnings;

use CGI;

use Config::Tiny;

use DBI;

use HTML::Template;

use JSON::XS;

our $VERSION = '1.04';

# -----------------------------------------------

sub build_search_form
{
	my($self) = @_;

	# Build the search form and the corresponding Javascript.

	$$self{'_search_js'}   -> param(form_action => $$self{'_form_action'});
	$$self{'_search_js'}   -> param(sid         => '');
	$$self{'_search_form'} -> param(sid         => '');

	# Keep YUI happy by ensuring the HTML is one long string...

	$$self{'_search_form'} = $$self{'_search_form'} -> output();
	$$self{'_search_form'} =~ s/\n//g;

	$self -> log('Leaving build_search_template');

	return ($$self{'_search_js'} -> output(), $$self{'_search_form'});

} # End of build_search_form.

# -----------------------------------------------

sub initialize
{
	my($self)        = @_;
	my(@search_form) = $self -> build_search_form();

	# Generate the Javascript which will be called upon page load.

	my($head_init)   = <<EJS;
make_search_name_focus();
EJS

	# Generate the Javascript which will do all the work.

	my($head_js) = <<EJS;
$search_form[0]

function make_search_name_focus(eve)
{
document.search_form.target.focus();
}
EJS

	# Generate the web page itself.

	$$self{'_content'}  -> param(content   => $search_form[1]);
	$$self{'_web_page'} -> param(container => $$self{'_content'} -> output() );
	$$self{'_web_page'} -> param(head_init => $head_init);
	$$self{'_web_page'} -> param(head_js   => $head_js);

	$self -> log('Leaving initialize');

	return $$self{'_web_page'} -> output();

} # End of initialize.

# -----------------------------------------------
# TODO: Make this sub a module one day?

sub load_config_file
{
	my($self) = @_;
	my($name) = '.htajax.conf';

	# Find this file and grab the config file from the same dir.

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|CGI/Application/Demo/Ajax.pm|);

		($path = $INC{$_}) =~ s/Ajax.pm/$name/;
	}

	# Check the global section.

	$$self{'_config'}  = Config::Tiny -> read($path);
	$$self{'_section'} = '_';

	if (! $$self{'_config'}{$$self{'_section'} }{'host'})
	{
		Carp::croak "Config file '$path' does not contain 'host' within the global section";
	}

	# Check [x] where x is host=x within the global section.

	$$self{'_section'} = $$self{'_config'}{$$self{'_section'}}{'host'};

	if (! $$self{'_config'}{$$self{'_section'}}{'tmpl_path'})
	{
		Carp::croak "Config file '$path' does not contain 'tmpl_path' within the section [$$self{'_section'}]";
	}

} # End of load_config_file.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;
	my($sth)      = $$self{'_dbh'} -> prepare("insert into $$self{'_log_table'} (message) values (?)");
	my $time      = localtime();

	$sth -> execute($time . ': ' . ($s || '') );

} # End of log.

# -----------------------------------------------

sub search
{
	my($self)   = @_;
	my($output) = [];
	my($q)      = $self -> query();
	my($target) = $q -> param('target') || '.';

	# Read the data from our multi-million dollar RDBMS.

	push @$output,
	{
		name => 'Ron',
		role => 'Programmer',
	};

	push @$output,
	{
		name => 'Zoe',
		role => 'Female dog',
	};

	push @$output,
	{
		name => 'Zigzag',
		role => 'Male dog',
	};

	$self -> log("Database returned @{[scalar @$output]} results");

	# Filter based on user input...

	@$output = grep{$$_{'name'} =~ /$target/i} @$output;

	$self -> log("Filter returned @{[scalar @$output]} results");
	$self -> log('Leaving search');

	return JSON::XS -> new() -> encode({results => $output});

} # End of search.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> load_config_file();
	$self -> run_modes([qw/initialize search/]);
	$self -> start_mode('initialize');

	# Use aliases to shorten names.

	$$self{'_form_action'}    = $$self{'_config'}{$$self{'_section'} }{'form_action'};
	$$self{'_session_driver'} = $$self{'_config'}{$$self{'_section'} }{'session_driver'};
	$$self{'_temp_dir'}       = $$self{'_config'}{$$self{'_section'} }{'temp_dir'};
	$$self{'_tmpl_path'}      = $$self{'_config'}{$$self{'_section'} }{'tmpl_path'};
	$$self{'_yui_url'}        = $$self{'_config'}{$$self{'_section'} }{'yui_url'};

	# Load all the templates.

	$self -> tmpl_path($$self{'_tmpl_path'});

	$$self{'_content'}     = $self -> load_tmpl('content.tmpl');
	$$self{'_search_form'} = $self -> load_tmpl('search.tmpl');
	$$self{'_search_js'}   = $self -> load_tmpl('search.js');
	$$self{'_web_page'}    = $self -> load_tmpl('web.page.tmpl');

	$$self{'_web_page'} -> param(yui_url => $$self{'_yui_url'});

	# Connect to the database for logging.

	$$self{'_dbh'}       = DBI -> connect("DBI:CSV:f_dir=$$self{'_temp_dir'}");
	$$self{'_log_table'} = 'ajax.log';

	$$self{'_dbh'} -> do("drop table $$self{'_log_table'}");

	my($sth) = $$self{'_dbh'} -> prepare("create table $$self{'_log_table'}(message varchar(255) )");

	$sth -> execute();

	my($q) = $self -> query();

	$self -> log('=' x 50);
	$self -> log("Param: $_ => " . $q -> param($_) ) for $q -> param();
	$self -> log('Leaving setup');

} # End of setup.

# -----------------------------------------------

1;

=head1 NAME

C<CGI::Application::Demo::Ajax> - A search engine using CGI::Application, AJAX and JSON

=head1 Synopsis

Either:

	#!/usr/bin/perl

	use CGI::Application::Demo::Ajax;

	CGI::Application::Demo::Ajax -> new() -> run();

or:

	#!/usr/bin/perl

	use strict;
	use warnings;

	use CGI::Application::Dispatch;
	use CGI::Fast;
	use FCGI::ProcManager;

	# ---------------------

	my($proc_manager) = FCGI::ProcManager -> new({processes => 2});

	$proc_manager -> pm_manage();

	my($cgi);

	while ($cgi = CGI::Fast -> new() )
	{
		$proc_manager -> pm_pre_dispatch();
		CGI::Application::Dispatch -> dispatch
		(
	 	args_to_new => {QUERY => $cgi},
	 	prefix      => 'CGI::Application::Demo',
	 	table       =>
		[
	  	''        => {app => 'Ajax', rm => 'initialize'},
	  	'/search' => {app => 'Ajax', rm => 'search'},
		],
		);
		$proc_manager -> pm_post_dispatch();
	}

=head1 Description

C<CGI::Application::Demo::Ajax> demonstrates how to use C<CGI::Application> together with AJAX and JSON.

It ships with:

=over 4

=item Two C<CGI> instance scripts: ajax.cgi and ajax

ajax.cgi is a trivial C<CGI> script, while ajax is a fancy script using C<CGI::Application::Dispatch> and C<FCGI::ProcManager>.

=item A text configuration file: .htajax.conf

This will be installed into the same directory as Ajax.pm. And that's where Ajax.pm looks for it.

By default, form_action is /cgi-bin/ajax.cgi, so you'll need to edit it to use form_action=/local/ajax.

Also, the default logging directory is /tmp, so this might call for another edit of .htajax.conf.

=item A set of C<HTML::Template> templates: *.tmpl

=item This Perl module: C<CGI::Application::Demo::Ajax>

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing distros.

=head1 Installation

All these assume your doc root is /var/www.

=head2 Install YUI

Browse to http://developer.yahoo.com/yui/, download, and unzip into htdocs:

	shell>cd /var/www
	shell>sudo unzip ~/Desktop/yui_2.7.0b.zip

This creates /var/www/yui, and yui_url in .htajax.conf must match.

=head2 Install the module

Install this as you would for any C<Perl> module:

Unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

=head2 Install the C<HTML::Template> files.

	shell>cd /var/www
	shell>sudo mkdir -p assets/templates/cgi/application/demo/ajax
	shell>cp distro's/htdocs/*.tmpl to assets/templates/cgi/application/demo/ajax

Alternately, edit the now installed .htajax.conf, to adjust tmpl_path.

=head2 Install the trivial instance script

	shell>cp distro's/htdocs/ajax.cgi to /usr/lib/cgi-bin
	shell>sudo chmod 755 /usr/lib/cgi-bin/ajax.cgi

=head2 Install the fancy instance script

	shell>cd /var/www
	shell>sudo mkdir local
	shell>cp distro's/htdocs/ajax to local
	shell>sudo chmod 755 local/ajax

=head2 Configure C<Apache> to use local/ajax

If in fancy mode, add these to httpd.conf:

	LoadModule fcgid_module modules/mod_fcgid.so

and:

	<Location /local>
		SetHandler fcgid-script
		Options ExecCGI
		Order deny,allow
		Deny from all
		Allow from 127.0.0.1
	</Location>

And restart C<Apache>.

=head2 Start searching

Point your broswer at http://127.0.0.1/cgi-bin/ajax.cgi (trivial script), or
http://127.0.0.1/local/ajax (fancy script, nice-and-clean URL).

=head1 The Flow of Control

Here's a step-by-step description of what's happening:

=over 4

=item You initialize the process

Point your web client at http://127.0.0.1/cgi-bin/ajax.cgi or http://127.0.0.1/local/ajax.

This is equivalent to C<< CGI::Application::Demo::Ajax -> new() -> run() >>.

Since there is no run mode input, the code defaults to Ajax.pm's sub initialize(). See sub setup() for details.

=item The code assembles the default web page

The work is done in Ajax.pm's sub initialize().

This page is sent from the server to the client.

It contains the contents of web.page.tmpl, with both search.js and search.tmpl embedded therein.

Of course, it also contains a minimal set of YUI Javascript files.

=item The client accepts the response

The default web page is displayed.

=item You input a search term

The C<CGI> form in search.tmpl is set to not submit, but rather to call the Javascript function search_onsubmit(),
which lives in search.js.

It's actually the copy of this code, now inside web.page.tmpl, now inside your client, which gets executed.

=item The C<CGI> form is submitted

Here, Javascript does the submit, in such a way as to also specify a call-back (Javascript) function, search_callback(),
which will handle the response from the server.

This function also lives in search.js.

=item Ajax.pm runs again

This time a run mode was submitted, either as form data or as path info data.

And this means that when using the fancy script, you don't need the line in search.tmp referring to the hidden form
variable 'rm', because of the path info '/search' in search_onsubmit().

=item sub search() carries out the search.

The run mode causes Ajax.pm's sub search() to be the sub which gets executed this time.

It assembles the results, and uses C<JSON::XS> to encode them.

=item The server replies

The results of the search are sent to the client.

=item The client accepts the response

When the client receives the message, these events occur, in this order:

=over 4

=item Control passes to search_callback(), the call-back function

=item The data is decoded from JSON to text by a YAHOO.lang.JSON object

=item The data is moved into a YAHOO.util.LocalDataSource object

=item The data is formatted as it's moved into a YAHOO.widget.DataTable object

=back

This object displays its data automatically. Actually, the object's constructor displays the data, which is why
we call new by assigning the object to a Javascript variable, data_table.

=back

=head2 Next

It should be obvious that the code in Ajax.pm's sub search() can be extended in any manner, to pass more complex
hash refs to the Javascript function search_callback().

This data can then be ignored by the Javascript, or you can extend the responseSchema and column_defs to display it.

Given this framework, extending these data structures is basically effortless.

=head1 Author

C<CGI::Application::Demo::Ajax> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2009, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
