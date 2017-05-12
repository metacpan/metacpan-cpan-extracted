package CGI::Application::Bouquet::Rose;

# Author:
#	Ron Savage <ron@savage.net.au>
#
# Note:
#	\t = 4 spaces || die.

use strict;
use warnings;

require 5.005_62;

require Exporter;

use Carp;
use CGI::Application::Bouquet::Rose::Config;
use File::Copy;
use File::Path; # For mkpath and rmtree.
use File::Spec; # For copy.
use HTML::Template;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Application::Bouquet::Rose ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.05';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
	 _docroot    => undef,
	 _exclude    => undef,
	 _module     => 'Local::Wine',
	 _output_dir => undef,
	 _remove     => 0,
	 _tmpl_path  => undef,
	 _verbose    => undef,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub log
{
	my($self, $message) = @_;

	if ($$self{'_verbose'})
	{
		print STDERR "$message\n";
	}

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, $arg) = @_;
	my($self)        = bless({}, $class);
	my($config)      = CGI::Application::Bouquet::Rose::Config -> new();

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($$arg{$arg_name}) )
		{
			$$self{$attr_name} = $$arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}

		if (! defined $$self{$attr_name})
		{
			# The '' is for when the user chops the option out of the config file,
			# and also refuses to specify a value on the command line.

			my($method)        = "get_$arg_name";
			$$self{$attr_name} = $config -> $method() || '';
		}
	}

	$$self{'_prefix'}    = "$$self{'_module'}\::CGI";
	$$self{'_dir_name'}  = "$$self{'_output_dir'}\::$$self{'_prefix'}";
	$$self{'_dir_name'}  = File::Spec -> catdir(split(/::/, $$self{'_dir_name'}) );
	$$self{'_db_module'} = "$$self{'_module'}\::Base\::DB";;
	my($file)            = $$self{'_db_module'};
	$file                =  File::Spec -> catdir(split(/::/, $file) );

	$self -> log("docroot:         $$self{'_docroot'}");
	$self -> log("exclude:         $$self{'_exclude'}");
	$self -> log("module:          $$self{'_module'}");
	$self -> log("output_dir:      $$self{'_output_dir'}");
	$self -> log("prefix:          $$self{'_prefix'}");
	$self -> log("remove:          $$self{'_remove'}");
	$self -> log("tmpl_path:       $$self{'_tmpl_path'}");
	$self -> log("verbose:         $$self{'_verbose'}");
	$self -> log("Working dir:     $$self{'_dir_name'}");
	$self -> log("Rose::DB module: $$self{'_db_module'}");

	# Ensure we can load the user's Rose::DB-based module.

	eval "require '$file.pm'";
	croak $@ if $@;

	return $self;

}	# End of new.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	if ($$self{'_remove'})
	{
		$self -> log("Removing:        $$self{'_dir_name'}");
		$self -> log('Success');

		rmtree([$$self{'_dir_name'}]);

		return 0;
	}

	my($rose_db) = $$self{'_db_module'} -> new();
	my(@table)   = $rose_db -> list_tables();

	my($data);
	my($module, @module);
	my($name);
	my($table);

	$self -> log('Processing tables:');

	for $table (@table)
	{
		($module = ucfirst $table) =~ s/_(.)/\u$1/g;

		$self -> log("Table: $table. Module: $module");

		push @module,
		{
			module_name => $module,
			table_name  => $table,
		}
	}

	@module = sort{$$a{'module_name'} cmp $$b{'module_name'} } @module;

	$self -> log('Processing templates:');

	my(@component)      = split(/::/, lc $$self{'_module'});
	my($fcgi_name)      = $component[- 1];
	my(@real_tmpl_path) = split(/::/, lc $$self{'_module'});
	my($real_tmpl_path) = File::Spec -> catdir('assets', 'templates');
	$real_tmpl_path     = File::Spec -> catdir($$self{'_docroot'}, $real_tmpl_path, @real_tmpl_path);

	$self -> log("Path to run-time templates: $real_tmpl_path");

	# Process: content.tmpl, main.menu.tmpl, search.form.tmpl, web.page.tmpl.

	my($output_dir_name) = File::Spec -> catdir('htdocs', 'assets', 'templates', @component);

	$self -> log("Creating $output_dir_name");

	mkpath([$output_dir_name], 0, 0744);

	my($output_file_name);

	for (qw/content.tmpl main.menu.tmpl search.form.tmpl web.page.tmpl/)
	{
		my($output_file_name) = File::Spec -> catfile($output_dir_name, $_);

		$self -> log("Copying $output_file_name");

		copy("$$self{'_tmpl_path'}/$_", $output_file_name);
	}

	# Process: search.fcgi.tmpl.

	$output_dir_name = File::Spec -> catdir('htdocs', 'search');

	$self -> log("Creating $output_dir_name");

	mkpath([$output_dir_name], 0, 0744);

	$output_file_name = File::Spec -> catfile($output_dir_name, "$fcgi_name.fcgi");
	my($template)     = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'search.fcgi.tmpl') );

	$template -> param(prefix => $$self{'_prefix'});

	$self -> log("Creating $output_file_name");

	open(OUT, "> $output_file_name") || die "Can't open(> $output_file_name):$ !";
	print OUT $template -> output();
	close OUT;

	# Process: CGI/CGIApp.pm.

	$self -> log("Creating $$self{'_dir_name'}");

	mkpath([$$self{'_dir_name'}], 0, 0744);

	$output_file_name   = File::Spec -> catfile($$self{'_dir_name'}, 'CGIApp.pm');
	$template           = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'cgiapp.pm.tmpl') );
	$template -> param(module    => $$self{'_module'});
	$template -> param(prefix    => $$self{'_prefix'});
	$template -> param(tmpl_path => $real_tmpl_path);

	$self -> log("Creating $output_file_name");

	open(OUT, "> $output_file_name") || die "Can't open(> $output_file_name):$ !";
	print OUT $template -> output();
	close OUT;

	# Process: CGI/Dispatcher.pm.

	$output_file_name = File::Spec -> catfile($$self{'_dir_name'}, 'Dispatcher.pm');
	$template         = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'dispatcher.pm.tmpl') );

	$template -> param(prefix => $$self{'_prefix'});

	$self -> log("Creating $output_file_name");

	open(OUT, "> $output_file_name") || die "Can't open(> $output_file_name):$ !";
	print OUT $template -> output();
	close OUT;

	# Process: CGI/MainMenu.pm.

	$output_file_name = File::Spec -> catfile($$self{'_dir_name'}, 'MainMenu.pm');
	$template         = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'main.menu.pm.tmpl') );

	$template -> param(prefix => $$self{'_prefix'});

	$self -> log("Creating $output_file_name");

	open(OUT, "> $output_file_name") || die "Can't open(> $output_file_name):$ !";
	print OUT $template -> output();
	close OUT;

	# Process: CGI/CGIApp/*.pm (1 per table).

	$output_dir_name = File::Spec -> catdir($$self{'_dir_name'}, 'CGIApp');

	$self -> log("Creating $output_dir_name");

	mkpath([$output_dir_name], 0, 0744);

	$template = HTML::Template -> new(filename => File::Spec -> catfile($$self{'_tmpl_path'}, 'generator.pl.tmpl') );

	$template -> param(dir_name    => $output_dir_name);
	$template -> param(module_loop => \@module);
	$template -> param(module      => $$self{'_module'});
	$template -> param(tmpl_path   => $$self{'_tmpl_path'});
	$template -> param(verbose     => $$self{'_verbose'} || 0);

	print $template -> output();

	$self -> log('Success');

	return 0;

} # End of run.

# -----------------------------------------------

1;

=head1 NAME

C<CGI::Application::Bouquet::Rose> - Generate a set of CGI::Application-based classes

=head1 Synopsis

=head2 Security Warning

The generated code allows SQL to be entered via a CGI form. This means you absolutely
must restrict usage of the generated code to trusted persons.

=head2 Sample Code

	Step 1: Run the steps from the synopsis for Rose::DBx::Bouquet.
	Remember, the current dir /must/ still be Local-Wine-1.06/.

	Step 2: Edit:
	o lib/Rose/DBx/Bouquet/.htcgi.bouquet.conf
   	o lib/Local/Wine/.htwine.conf

	Step 3: Run the third code generator (see scripts/rosy):
	shell> scripts/run.cgi.app.gen.pl > scripts/run.cgi.pl

	Step 4: This is the log from run.cgi.app.gen.pl:
	docroot:         /var/www
	exclude:         ^(?:information_schema|pg_|sql_)
	module:          Local::Wine
	output_dir:      ./lib
	prefix:          Local::Wine::CGI
	remove:          0
	tmpl_path:       ../CGI-Application-Bouquet-Rose/templates
	verbose:         1
	Working dir:     lib/Local/Wine/CGI
	Rose::DB module: Local::Wine::Base::DB
	Processing tables:
	Table: grape. Module: Grape
	Table: vineyard. Module: Vineyard
	Table: wine. Module: Wine
	Table: wine_maker. Module: WineMaker
	Processing templates:
	Path to run-time templates: /var/www/assets/templates/local/wine
	Creating htdocs/assets/templates/local/wine
	Copying htdocs/assets/templates/local/wine/content.tmpl
	Copying htdocs/assets/templates/local/wine/main.menu.tmpl
	Copying htdocs/assets/templates/local/wine/search.form.tmpl
	Copying htdocs/assets/templates/local/wine/web.page.tmpl
	Creating htdocs/search
	Creating htdocs/search/wine.fcgi
	Creating lib/Local/Wine/CGI
	Creating lib/Local/Wine/CGI/CGIApp.pm
	Creating lib/Local/Wine/CGI/Dispatcher.pm
	Creating lib/Local/Wine/CGI/MainMenu.pm
	Creating lib/Local/Wine/CGI/CGIApp
	Success

	Step 5: Run the fourth code generator:
	shell> perl -Ilib scripts/run.cgi.pl

	Step 6: This is the log from run.cgi.pl:
	Processing CGI::Application-based modules:
	Updating htdocs/assets/templates/local/wine/main.menu.tmpl
	Generated lib/Local/Wine/CGI/CGIApp/Grape.pm
	Generated lib/Local/Wine/CGI/CGIApp/Vineyard.pm
	Generated lib/Local/Wine/CGI/CGIApp/Wine.pm
	Generated lib/Local/Wine/CGI/CGIApp/WineMaker.pm
	Success

	Step 7: Install the templates:
	shell> scripts/install.templates.pl

	Step 8: Install Local::Wine
	shell> perl Build.PL
	shell> perl Build
	shell> sudo perl Build install

	Step 9: Install the FastCGId script:
	shell> sudo cp -r htdocs/search /var/www
	shell> sudo chmod a+x /var/www/search/wine.fcgi

	Step 10: Patch httpd.conf (see httpd/httpd.conf.patch):
	LoadModule fcgid_module modules/mod_fcgid.so
	<Location /search>
	    SetHandler fcgid-script
	    Options ExecCGI
		Order deny,allow
	    Deny from all
	    Allow from 127.0.0.1
	</Location>

	Step 11: Restart Apache:
	shell> sudo /etc/init.d/apache2 restart

	Step 12: Use a web client to hit http://127.0.0.1/search/wine.fcgi
	Start searching!

=head1 Description

C<CGI::Application::Bouquet::Rose> is a pure Perl module.

It uses a database schema, and code generated by C<Rose::DBx::Bouquet>, to generate
C<CGI::Application-based> source code.

The result is an CGI script which implements a search engine customised to the given database.

At run-time, a menu of database tables is displayed in the web client, and when one is chosen, a CGI form
is displayed which allows the user to enter any value for any column. These values are the search keys, and
may include SQL tokens such as '%' and '_'.

The N rows returned by the search are displayed as a HTML table, and you can page back and forth around this
data set.

This documentation uses Local::Wine as the basis for all discussions. See the FAQ for the availability
of the Local::Wine distro.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<CGI::Application::Bouquet::Rose>.

This is the class's contructor.

Usage: C<< CGI::Application::Bouquet::Rose -> new() >>.

This method takes a hashref of options.

Call C<new()> as C<< new({option_1 => value_1, option_2 => value_2, ...}) >>.

Available options:

=over 4

=item doc_root

This takes a directory name, which is the name of your web server's document root.

If not specified, the value defaults to the value in lib/Rose/DBx/Bouquet/.htcgi.bouquet.conf.

The default value is /var/www, which suits me.

=item exclude

This takes a regexp (without the //) of table names to exclude.

Code is generated for each table which is I<not> excluded.

If not specified, the value defaults to the value in lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

The default value is ^(?:information_schema|pg_|sql_), which suits users of C<Postgres>.

=item output_dir

This takes the path where the output modules are to be written.

If not specified, the value defaults to the value in lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

The default value is ./lib.

=item tmpl_path

This is the path to C<CGI::Application::Bouquet::Rose's> template directory.

These templates are input to the code generation process.

If not specified, the value defaults to the value in lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

The default value is ../CGI-Application-Bouquet-Rose/templates.

Note: The point of the '../' is because I assume you have done 'cd Local-Wine-1.06'
or the equivalent for whatever module you are working with.

=item verbose

This takes either a 0 or a 1.

Write more or less progress messages to STDERR, during code generation.

The default value is 0.

=back

=head1 FAQ

=over 4

=item Availability of Local::Wine

Download Local::Wine from http://savage.net.au/Perl-modules/Local-Wine-1.06.tgz

The schema is at: http://savage.net.au/Perl-modules/wine.png

C<CGI::Application::Bouquet::Rose> ships with C<cgi.app.gen.pl> in the bin/ directory, whereas
C<Local::Wine> ships with various programs in the scripts/ directory.

Files in the /bin directory get installed via 'make install'. Files in the scripts/ directory
are not intended to be installed; they are only used during the code-generation process.

Note also that 'make install' installs lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf, and
- depending on your OS - you may need to change its permissions in order to edit it.

=item Minimum modules required when replacing Local::Wine with your own code

Short answer:

=over 4

=item Local::Wine

=item Local::Wine::Config

You can implement this module any way you want. It just has to provide the same methods.

=item Local::Wine::Base::Create

=item Local::Wine::DB

This module will use the default type and domain, where 'type' and 'domain' are Rose concepts.

=item Local::Wine::Object

=back

Long answer:

See the docs for Local::Wine.

=item Why isn't Local::Wine on CPAN?

To avoid the problem of people assuming it can be downloaded and used just like any other module.

=item How does this module interact with Rose?

See the FAQ for <Rose::DBx::Bouquet>.

=item What is the syntax used for search terms at run-time?

SQL. So, to find the name of a grape starting with S, you'd type S%.

And yes, I know there is the potential for sabotage with such a system. This means you absolutely
must restrict usage of the generated code to trusted persons.

=item Can I search in Primary Keys?

Yes. They are text fields like any other column.

=item What happens when I enter several seach terms on the CGI form?

The values are combined with 'and'. There is no provision for using 'or'.

=item Do you ever write to the database?

No.

My intention is to provide CRUD features one day.

=item How do you handle sessions?

Sessions are not implemented, simply because they are not needed.

The only data which needs to be passed from CGI form to form is the database paging state,
and that is done with a hidden form field.

=item How are HTML entities handled?

Output from the database is encoded using HTML::Entities::Interpolate.

=item A note on option management

You'll see a list of option names and default values near the top of this file, in the hash %_attr_data.

Some default values are undef, and some are scalars.

My policy is this:

=over 4

=item If the default is undef...

Then the real default comes from a config file, and is obtained via the *::Config module.

=item If the default is a scalar...

Then that scalar is the default, and cannot be over-ridden by a value from a conf file.

=back

=item But why have such a method of handling options?

Because I believe it makes sense for the end user (you, dear reader), to have the power to change
configuration values without patching the source code. Hence the conf file.

However, for some values, I don't think it makes sense to do that. So, for those options, the default
value is a scalar in the source code of this module.

=item Is this option arrangement permanent?

Yes.

Options whose defaults are already in the config file will never be deleted from that file.

However, options not currently in the config file may be made available via the config file,
depending on feedback.

Also, the config file is an easy way of preparing for more user-editable options.

=back

=head1 Method: log($message)

If C<new()> was called as C<< new({verbose => 1}) >>, write the message to STDERR.

If C<new()> was called as C<< new({verbose => 0}) >> (the default), do nothing.

=head1 Method: run()

Do everything.

See C<bin/cgi.app.gen.pl> for an example of how to call C<run()>.

=head1 Author

C<CGI::Application::Bouquet::Rose> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
