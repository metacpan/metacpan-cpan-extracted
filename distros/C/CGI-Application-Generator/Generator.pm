package CGI::Application::Generator;
use strict;
use warnings;

$CGI::Application::Generator::VERSION = '1.0';

use HTML::Template;



=pod

=head1 NAME

CGI::Application::Generator - Dynamically build CGI::Application modules

=head1 SYNOPSIS

  use CGI::Application::Generator;

  # Required methods
  my $cat = CGI::Application::Generator->new();
  $cat->package_name('My::Widget::Browser');
  $cat->start_mode('list_widgets');
  $cat->run_modes(qw/
	list_widgets 
	add_widget 
	insert_widget
	edit_widget 
	update_widget
	delete_widget
  /);


  # Optional methods
  $cat->base_module('My::CGI::Application');
  $cat->use_modules(qw/My::DBICreds My::Utilities/);
  $cat->new_dbh_method('My::DBICreds->new_dbh()');
  $cat->tmpl_path('Path/To/My/Templates/');


  # Output-related methods
  $cat->app_module_tmpl('my_standard_cgiapp.tmpl');
  $cat->output_app_module();


=head1 DESCRIPTION


CGI::Application::Generator provides a means by which a CGI::Application 
module can be created from code, as opposed to being written by hand.  The 
goal of this module is two-fold:

  1. To ease the creation of new CGI::Application modules.
  2. To allow standardization of CGI::Application coding
     styles to be more uniformly applied.


It is also the hope of this module that Computer Assisted 
Software Engineering (CASE) tools will eventually emerge 
which will allow the development process for web-based applications
to be greatly improved.  These CASE tools could more easily 
convert visual notation (such as UML state-transition diagrams)
into method calls to this module, thereby creating actual code.


B<What This Module Does Not Do>

CGI::Application::Generator is intended to create a shell of 
an application module based on the specification you provide.
It will not output a completely functional application without
additional coding.  It will, however, handle the creation of all 
the structural parts of your application common to all
CGI::Application-based modules.

CGI::Application::Generator is not a system for HTML templates.
If you're looking for a Perl module which will allow you
to separate Perl from HTML then I recommend you download and install
HTML::Template.


=head1 METHODS


=over 4

=cut





############################
#####  PUBLIC METHODS  #####
############################


=pod

=item new()

  my $cat = CGI::Application::Generator->new();

Instantiate a new CGI::Application::Generator object.  This object
stores the state of your application module while you build it.

=cut

sub new {
	my $class = shift;

	my $self = {
		__PACKAGE_NAME       => '',
		__START_MODE         => '',
		__RUN_MODES          => [],
		__BASE_MODULE        => 'CGI::Application',
		__USE_MODULES        => [],
		__NEW_DBH_METHOD     => '',
		__TMPL_PATH          => '',
		__APP_MODULE_TMPL    => 'CGI/Application/Generator/app_module.tmpl',
		__CGI_SCRIPT_TMPL    => 'CGI/Application/Generator/cgi_script.tmpl',
	};

	bless($self, $class);

	return $self
}



=pod

=item package_name()

  $cat->package_name('My::Web::Application');
  my $package_name = $cat->package_name();

Set or get the name of the package (Perl module name).  This is the 
package name which will be assigned to your CGI::Application module.

=cut

sub package_name {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__PACKAGE_NAME';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item start_mode()

  $cat->start_mode('show_form');
  my $start_mode = $cat->start_mode();

Set or get the name of the run-mode which will be assigned 
as "start mode" in the output CGI::Application module.

=cut

sub start_mode {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__START_MODE';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item run_modes()

  $cat->run_modes(qw/show_form edit_widget delete_widget/);
  my @run_modes = $cat->run_modes();

Set or get the list of run-modes in your module.  This method expects an array (or array-ref).

=cut

sub run_modes {
	my $self = shift;
	my (@data) = ( @_ );

	my $prop_key = '__RUN_MODES';

	# If data is provided, set it!
	if (@data) {
		if (ref($data[0]) eq 'ARRAY') {
			# Copy Array via array-ref
			$self->{$prop_key} = [ @{$data[0]} ];
		} else {
			# Copy Array
			$self->{$prop_key} = [ @data ];
		}
	}

	# If we've gotten this far, return the value!
	return @{$self->{$prop_key}};
}




=pod

=item base_module()

  $cat->base_module('MyCustom::CGIAppBase');
  my $base_module = $cat->base_module();

Set or get the name of the module from which your module will 
inherit.  By default, this will be set to 'CGI::Application'.

=cut

sub base_module {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__BASE_MODULE';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item use_modules()

  $cat->use_modules(qw/DBI Net::SMTP Data::FormValidator/);
  my @use_modules = $cat->use_modules();

Set or get the list of Perl modules which should be 
included in your module.

=cut

sub use_modules {
	my $self = shift;
	my (@data) = ( @_ );

	my $prop_key = '__USE_MODULES';

	# If data is provided, set it!
	if (@data) {
		if (ref($data[0]) eq 'ARRAY') {
			# Copy Array via array-ref
			$self->{$prop_key} = [ @{$data[0]} ];
		} else {
			# Copy Array
			$self->{$prop_key} = [ @data ];
		}
	}

	# If we've gotten this far, return the value!
	return @{$self->{$prop_key}};
}



=pod

=item new_dbh_method()

  $cat->new_dbh_method('DBI->connect(DBD::mysql::MyDatabase)');
  my $new_dbh_method = $cat->new_dbh_method();

Set or get the code which creates a new DBI-compatible database
handle ($dbh).  If specified, the CGI::Application module will
automatically call this code at run-time, in the setup() method, to 
connect to the database and store the database handle object reference 
in a CGI::Application param, 'DBH'.  In teardown() this database 
handle will be disconnected.  Access to the $dbh will be automatically
set up in each run-mode method.


=cut

sub new_dbh_method {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__NEW_DBH_METHOD';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item tmpl_path()

  $cat->tmpl_path('Path/To/My/Templates/');
  my $tmpl_path = $cat->tmpl_path();

Set or get the path in which the templates
for your module will be stored.

=cut

sub tmpl_path {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__TMPL_PATH';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item app_module_tmpl()

  $cat->app_module_tmpl('path/to/my_app_style.tmpl');
  my $app_module_tmpl = $cat->app_module_tmpl();

Set or get the path and filename of the HTML::Template which 
should be used by CGI::Application::Generator to create
your Perl module.  By default an internal template will be used.
You may implement your own template if you want to have 
special output for your organization's programming style.

=cut

sub app_module_tmpl {
	my $self = shift;
	my ($data) = @_;

	my $prop_key = '__APP_MODULE_TMPL';

	# If data is provided, set it!
	if (defined($data)) {
		$self->{$prop_key} = $data;
	}

	# If we've gotten this far, return the value!
	return $self->{$prop_key};
}



=pod

=item output_app_module()

  my $module_source = $cat->output_app_module();

The output_app_module() method returns a scalar containing the 
source code of the module you've specified.  Generally, you would 
store this output in a file named "MyModule.pm" which would then 
be used by your instance script.

For example, the following code would build the shell of a basic 
CGI application via CGI::Application::Generator:

  use CGI::Application::Generator;

  my $c = CGI::Application::Generator->new();
  $c->package_name('WidgetBrowser');
  $c->start_mode('show_form');      
  $c->run_modes(qw/show_form do_search view_details/);
  $c->use_modules(qw/DBI/);
  $c->new_dbh_method('DBI->connect("DBD:mysql:WIDGETCORP")');
  $c->tmpl_path('WidgetBrowser/');

  open(OUTPUT, ">WidgetBrowser.pm") || die($!);
  print OUTPUT $c->output_app_module();
  close(OUTPUT);

=cut

sub output_app_module {
	my $self = shift;

	my $t = HTML::Template->new_file(
		$self->app_module_tmpl(), 
		global_vars => 1,
		path => \@INC,
	);

	$t->param(
		package_name => $self->package_name(),
		base_module => $self->base_module(),
		start_mode => $self->start_mode(),
		run_modes => [ map { {mode_name=>$_} } ($self->run_modes()) ],
		use_modules => [ map { {module_name=>$_} } ($self->use_modules()) ],
		tmpl_path => $self->tmpl_path(),
		new_dbh_method => $self->new_dbh_method(),
	);

	return $t->output();
}





#############################
#####  PRIVATE METHODS  #####
#############################



1;






=pod

=back

=head1 AUTHOR

Jesse Erlbaum <jesse@erlbaum.net>

B<Support Mailing List>

If you have any questions, comments, bug reports or feature 
suggestions, post them to the support mailing list!
To join the mailing list, simply send a blank message to
"cgiapp-subscribe@lists.erlbaum.net".


=head1 SEE ALSO

L<CGI::Application>, L<HTML::Template>, L<perl>


=head1 LICENSE

CGI::Application::Generator - 
Dynamically build CGI::Application modules from template
Copyright (C) 2003 Jesse Erlbaum <jesse@erlbaum.net>

This module is free software; you can redistribute it
and/or modify it under the terms of either:

a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option)
any later version,

or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.  See either the GNU General Public License or the
Artistic License for more details.

You should have received a copy of the Artistic License
with this module, in the file ARTISTIC.  If not, I'll be
glad to provide one.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut
