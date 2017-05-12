package CGI::Application::Framework;

use strict;
use warnings;

=head1 NAME

CGI::Application::Framework - Fully-featured MVC web application platform

=head1 VERSION

Version 0.26

=cut

our $VERSION = '0.26';

use base qw / CGI::Application Exporter /;
use vars qw / @EXPORT_OK $AUTOLOAD /;

@EXPORT_OK = qw (
                 load_tmpl
                 session
                 redirect
                 make_link
                 AUTOLOAD
                 make_self_url
                 get_session_id
                 );

use Carp;
use Data::Dumper;

use CGI::Application::Framework::Constants qw (
                                               SESSION_FIRST_TIME
                                               SESSION_IN_COOKIE
                                               SESSION_IN_HIDDEN_FORM_FIELD
                                               SESSION_IN_URL
                                               SESSION_MISSING
                                              );

use CGI::Application::Plugin::ValidateRM qw / check_rm /;
use CGI::Application::Plugin::Config::Context;
use CGI::Application::Plugin::AnyTemplate;
use CGI::Application::Plugin::LogDispatch;
use Log::Dispatch::Config ();
use Apache::SessionX;

use CGI::Enurl ();
use Digest::MD5;
use Time::HiRes;
use File::Basename qw ( fileparse );
use File::Spec;
use Cwd 'abs_path';
use Module::Load;

__PACKAGE__->add_callback('init',                  '_framework_init');
__PACKAGE__->add_callback('postrun',               '_framework_postrun');
__PACKAGE__->add_callback('prerun',                '_framework_prerun');
__PACKAGE__->add_callback('template_pre_process',  '_framework_template_pre_process');
__PACKAGE__->add_callback('template_post_process', '_framework_template_post_process');

=head1 NOTE

This is alpha-quality software which is being continually developed and
refactored.  Various APIs B<will> change in future releases.  There are
bugs.  There are missing features.  Feedback and assistance welcome!

=head1 SYNOPSIS

=head2 Application Layout

A C<CGI::Application::Framework> project has the following layout:

    /cgi-bin/
             app.cgi                 # The CGI script
    /framework/
         framework.conf              # Global CAF config file

         projects/
             MyProj/
                framework.conf       # MyProj config file

                common-templates/    # login templates go here

                common-modules/
                     CDBI/
                         MyProj.pm   # The Class::DBI project module

                         MyProj/
                             app.pm  # The Class::DBI application module

                     MyProj.pm       # The project module

                applications/
                    framework.conf            # "All applications" config file
                    myapp1/
                         framework.conf       # myapp1 config file

                         myapp1.pm            # An application module
                         templates/
                            runmode_one.html  # templates for myapp1
                            runmode_two.html

                    myapp2/
                         framework.conf       # myapp2 config file
                         myapp2.pm            # An application module
                         templates/
                            runmode_one.html  # templates for myapp2
                            runmode_two.html


=head2 The CGI Script

You call your application with an URL like:

    http://www.example.com/cgi-bin/app.cgi/MyProj/myapp

By default, CAF applications are divided first into C<Projects> and then
into C<applications>.  Based on the URL above, the Project is called
C<MyProj> and the application within that project is called C<myapp>.

The actual CGI script (C<app.cgi>) is tiny.  It looks like this:

    #!/usr/bin/perl

    use strict;
    use CGI::Application::Framework;
    use CGI::Carp 'fatalsToBrowser';

    CGI::Application::Framework->run_app(
        projects => '../caf/projects',
    );


=head2 An application module

Your application module (C<myapp.pm>) looks like a standard
C<CGI::Application>, with some extra features enabled.

    package myapp1;

    use strict;
    use warnings;

    use base qw ( MyProj );

    sub setup {
        my $self = shift;
        $self->run_modes([qw( runmode_one )]);
        $self->start_mode('runmode_one');
    }

    sub rumode_one {
        my $self = shift;

        $self->template->fill({
            name => $self->session->{user}->fullname,
        });
    }


=head2 A template

The template is named (by default) after the run mode that called it.
In this case, it's C<runmode_one.html>:

    <html>
    <body>
    <h1>Welcome</h1>
    Hello there, <!-- TMPL_VAR NAME="name" -->
    </body>
    </html>

=head2 The project module

Your common project module (MyProj.pm) contains a lot of code, but most
of it can be copied directly from the examples:

    package MyProj;

    use warnings;
    use strict;

    use base 'CGI::Application::Framework';

    # Called to determine if the user filled in the login form correctly
    sub _login_authenticate {
        my $self = shift;

        my $username = $self->query->param('username');
        my $password = $self->query->param('password');

        my ($user) = CDBI::Project::app::Users->search(
		    username => $username
		);

        if ($password eq $user->password) {
            return(1, $user);
        }
        return;
    }

    # Called to determine if the user filled in the re-login form correctly
    sub _relogin_authenticate {
        my $self = shift;

        my $password = $self->query->param('password');
        my $user = CDBI::Project::app::Users->retrieve(
    	    $self->session->{uid}
    	);
        if ($password eq $user->password) {
            return(1, $user);
        }
        return;
    }

    # _login_profile and _relogin_profile are
    # definitions for Data::FormValidate, as needed by
    # CGI::Application::Plugin::ValidateRM
    sub _login_profile {
        return {
            required => [ qw ( username password ) ],
            msgs     => {
                any_errors => 'some_errors', # just want to set a true value here
                prefix     => 'err_',
            },
        };
    }
    sub _relogin_profile {
        return {
            required => [ qw ( password ) ],
            msgs     => {
                any_errors => 'some_errors', # just want to set a true value here
                prefix     => 'err_',
            },
        };
    }

    # Return extra values for the login template for when
    sub _login_failed_errors {
        my $self = shift;

        my $is_login_authenticated = shift;
        my $user = shift;

        my $errs = undef;

        if ( $user && (!$is_login_authenticated) ) {
            $errs->{'err_password'} = 'Incorrect password for this user';
        } elsif ( ! $user ) {
            $errs->{'err_username'} = 'Unknown user';
        } else {
            die "Can't happen! ";
        }
        $errs->{some_errors} = '1';

        return $errs;
    }

    # Return error values for the relogin template
    sub _relogin_failed_errors {

        my $self = shift;

        my $is_login_authenticated = shift;
        my $user = shift;

        my $errs = undef;

        if ( $user && (!$is_login_authenticated) ) {

    	    $errs->{err_password} = 'Incorrect password for this user';

        } elsif ( ! $user ) {

    	    $errs->{err_username} = 'Unknown username';

            $self->log_confess("Can't happen! ");
        }
        $errs->{some_errors} = '1';

        return $errs;
    }

    # Here we handle the logic for sessions timing out or otherwise becoming invalid
    sub _relogin_test {
        my $self = shift;

        if ($self->session->{_timestamp} < time - 600) {
            return 1;
        }
        return;
    }

    # Whenever a session is created, we have the opportunity to
    # fill it with any values we like
    sub _initialize_session {
        my $self = shift;
        my $user = shift;

        $self->session->{user}  = $user;
    }

    # Provide values to the relogin template
    sub _relogin_tmpl_params {
        my $self = shift;

    	return {
    	    username => $self->session->{'user'}->username;
    	};
    }

    # Provide values to the login template
    sub _login_tmpl_params {
        my $self = shift;
    }

=head2 The database classes

By convention, the database classes are also split into Project and
application.  First the project level C<CDBI::MyProj>:

    package CDBI::MyProj;

    use base qw( CGI::Application::Framework::CDBI );

    use strict;
    use warnings;

    1;

Next, the application-specific C<CDBI::Project::app>

    package CDBI::Project::app;

    use Class::DBI::Loader;

    use base qw ( CDBI::MyProj );

    use strict;
    use warnings;

    sub db_config_section {
        'db_myproj';
    }

    sub import {
        my $caller = caller;
        $caller->new_hook('database_init');
        $caller->add_callback('database_init', \&setup_tables);
    }

    my $Already_Setup_Tables;
    sub setup_tables {

        return if $Already_Setup_Tables;

        my $config = CGI::Application::Plugin::Config::Context->get_current_context;
        my $db_config = $config->{__PACKAGE__->db_config_section};

        my $loader = Class::DBI::Loader->new(
            dsn           => $db_config->{'dsn'},
            user          => $db_config->{'username'},
            password      => $db_config->{'password'},
            namespace     => __PACKAGE__,
            relationships => 0,
        );

        $Already_Setup_Tables = 1;
    }
    1;


=head2 Configuration

By default, there are four levels of configuration files in a CAF
application:  I<global>, I<project>, I<all apps> and I<application>:

    /caf/
         framework.conf                 # Global CAF config file

         projects/
             MyProj/
                framework.conf          # MyProj config file

                applications/
                    framework.conf      # "All applications" config file
                    myapp1/
                         framework.conf # myapp1 config file

                    myapp2/
                         framework.conf # myapp2 config file

When an application starts, the application-level framework.conf is
loaded.  This config file typically contains the line:

    <<include ../framework.conf>>

Which includes the "all apps" configuration file.  Similarly this
configuration file includes the project-level configuration file, and so
on up the chain until we reach the top-level C<framework.conf>.

CAF uses the C<Config::Context> configuration system, which is
compatible with multiple configuration file formats.  The default
configuration format is C<Config::General>, which means apache-style
config files:


    md5_salt        = bsdjfgNx/INgjlnVlE%K6N1BvUq9%#rjkfldBh

    session_timeout = 300

    <SessionParams>
        object_store  = Apache::Session::DB_File
        LockDirectory = ../caf/sessions/locks
        FileName      = ../caf/sessions/database
    </SessionParams>

    <TemplateOptions>
        include_path_common common-templates

        # template types include: HTMLTemplate, TemplateToolkit and Petal

        default_type        HTMLTemplate

    </TemplateOptions>

    <SystemTemplateOptions>
        include_path_common common-templates

        default_type HTMLTemplate
        <HTMLTemplate>
            cache              1
            global_vars        1
            die_on_bad_params  0
        </HTMLTemplate>
    </SystemTemplateOptions>

    <LogDispatch>
        <LogName file>
            module    = Log::Dispatch::File
            filename  = ../caf/logs/webapp.log
            min_level = debug
            mode      = append
        </LogName>

        append_newline = 1
        format         = [%P][%d] %F %L %p - %m%n

    </LogDispatch>

    <db_myproj>
        dsn           = DBI:mysql:dbname=project
        username      = dbuser
        password      = seekrit
    </db_myproj>


=head1 DESCRIPTION

C<CGI::Application::Framework> is a web development plaform built upon
C<CGI::Application>.  It incorporates many modules from CPAN in order to
provide a feature-rich environment, and makes it easy to write robust,
secure, scalable web applications.

It has the following features:

=over 4

=item *

Model-View-Controller (MVC) development with L<CGI::Application>

=item *

Choice of templating system (via L<CGI::Application::Plugin::AnyTemplate>)

=over 4

=item *

L<HTML::Template>

=item *

L<HTML::Template::Expr>

=item *

L<Template::Toolkit|Template>

=item *

L<Petal>

=back

=item *

Form Validatation and Sticky Forms (via L<CGI::Application::Plugin::ValidateRM>)

=item *

Easy (optional) L<Class::DBI> integration

=item *

Session Management (L<Apache::SessionX>)

=item *

Authentication

=item *

Login Managment

=over 4

=item *

login form

=item *

relogin after session timeout

=item *

form state is saved after relogin

=back

=item *

Powerful configuration system (via L<CGI::Application::Plugin::Config::Context>)

=item *

Link Integrity system

=item *

Logging (via L<CGI::Application::Plugin::Log::Dispatch>)

=back

=head1 STARTUP (app.cgi and the run_app method)

You call your application with an URL like:

    http://www.example.com/cgi-bin/app.cgi/MyProj/myapp?rm=some_runmode

This instructs CAF to run the application called C<myapp> which can be
found in the project called C<MyProj>.  When CAF finds this module, it
sets the value of the C<rm> param to C<some_runmode> and runs the
application.

All of your applications are run through the single CGI script.  For
instance, here are some examples:

    http://www.example.com/cgi-bin/app.cgi/Admin/users?rm=add
    http://www.example.com/cgi-bin/app.cgi/Admin/users?rm=edit
    http://www.example.com/cgi-bin/app.cgi/Admin/documents?rm=publish
    http://www.example.com/cgi-bin/app.cgi/Library/search?rm=results

The actual CGI script (C<app.cgi>) is tiny.  It looks like this:

    #!/usr/bin/perl

    use strict;
    use CGI::Application::Framework;
    use CGI::Carp 'fatalsToBrowser';

    CGI::Application::Framework->run_app(
        projects => '../caf/projects',
    );

All the magic happens in the C<run_app> method.  This method does a lot
of magic in one go:

  * examines the value of the URL's C<PATH_INFO>
  * determines the correct application
  * finds the application's config file
  * finds the application's module file
  * adds paths to @INC, as appropriate
  * adds paths to the application's TMPL_PATH
  * passes on any PARAMS or QUERY to the application's new() method
  * runs the application

The only required option is the location of the CAF C<projects>
directory.  The full list of options are:

=over 4

=item projects

Location of the CAF top-level projects directory.  Required.

=item app_params

Any extra parameters to pass as the C<PARAMS> option to the
application's C<new> method.  I<undefined by default.>

=item query

A L<CGI> query object to pass as the C<QUERY> option to the
application's C<new> method.  I<undefined by default>

=item common_lib_dir

Where the Perl modules for this project are stored.  Defaults to:

    $projects/$project_name/common-modules

The value of this parameter will be added to the application's @INC.

=item common_template_dir

Where the templates common to all apps in this project are stored.  Defaults to:

    $projects/$project_name/common-templates

=item app_dir

Where the application Perl modules are stored.  Defaults to:

    $projects/$project_name/applications/$app_name/

The value of this parameter will be added to the application's @INC.

=item app_template_dir

Where the application-specific template files are.  Defaults to:

    $app_dir/templates

=item module

The filename of the application module.  Defaults to:

    $app_name.pm

=back

The C<run_app> method in CAF was inspired by Michael Peter's
L<CGI::Application::Dispatch> module, and implements a similar concept.

=cut

sub run_app {
    my $class = shift;

    my %params = @_;

    my $projects = $params{'projects'}
        or croak "CAF->run_app error: run_app needs a projects dir\n";

    -d $projects
        or croak "CAF->run_app error: projects dir does not exist \n";

    my ($project_name, $app_name);
    if ($ENV{'PATH_INFO'} =~ m{^/?(\w*)/(\w*).*$}) {
       $project_name = $1;
       $app_name     = $2;
    }

    # TODO: add option to chdir to appdir

    $project_name
        or croak "CAF->run_app error: can't find project name from PATH_INFO\n";

    $app_name
        or croak "CAF->run_app error: can't find app name from PATH_INFO\n";

    my $app_params       = $params{'app_params'} || {};

    my $query            = $params{'query'} || undef;

    my $common_lib_dir      = $params{'common_lib_dir'}
                            || "$projects/$project_name/common-modules";

    my $common_template_dir = $params{'common_template_dir'}
                            || "$projects/$project_name/common-templates";

    my $app_dir             = $params{'app_dir'}
                            || "$projects/$project_name/applications/$app_name/";

    my $app_template_dir    = $params{'app_template_dir'}
                            || "$app_dir/templates";

    my $module              = $params{'module'}
                            || "$app_name.pm";


    $class->_add_to_inc($common_lib_dir);
    $class->_add_to_inc($app_dir);

    my @template_dirs = map { abs_path($_) } (
        $app_template_dir,
        $common_template_dir,
    );

    require $module;

    my %args = (
        TMPL_PATH => \@template_dirs,
        PARAMS    => {
            framework_app_dir => abs_path($app_dir),
            %$app_params
        }
    );

    $args{'QUERY'} = $query if $query;

    my $app = $app_name->new(%args);

    $app->run;
    return $app;
}

my %Added_To_INC;

sub _add_to_inc {
    my ($self, $path) = @_;

    $path = abs_path($path);

    unless ($Added_To_INC{$path}) {
        unshift @INC, $path;
        $Added_To_INC{$path} = 1;
    }
}

=head1 TEMPLATES

CAF uses the L<CGI::Application::Plugin::AnyTemplate> system.
C<AnyTemplate> allows you to use any supported Perl templating system,
and switch between them while using the same API.

Currently supported templating systems include L<HTML::Template>,
L<HTML::Template::Expr>, L<Template::Toolkit|Template> and L<Petal>.

=head2 Syntax

The syntax is pretty flexible.  Pick a style that's most comfortable for
you.

=over 4

=item CGI::Application::Plugin::TT style syntax

    $self->template->process('edit_user', \%params);

or (with slightly less typing):

    $self->template->fill('edit_user', \%params);

=item CGI::Application load_tmpl style syntax

    my $template = $self->template->load('edit_user');
    $template->param('foo' => 'bar');
    $template->output;

=back

=head2 Defaults

If you don't specify a filename, the system loads a template named after
the current run mode.

If you do specify a filename, you typically omit the filanme's extension.
The correct extension is added according to the template's type.

    sub add_user {
        my $self =  shift;

        $self->template->fill;  # shows add_user.html
                                #    or add_user.tmpl
                                #    or add_user.xhtml
                                # (depending on template type)
    }

    sub del_user {
        my $self =  shift;

        $self->template('are_you_sure')->fill;
                                # shows are_you_sure.html
                                #    or are_you_sure.tmpl
                                #    or are_you_sure.xhtml
                                # (depending on template type)
    }


The default template type is specified in the CAF configuration file.
along with the other template options.

=head2 Template Configuration

Here are the template options from the default top-level
C<framework.conf>:

    <TemplateOptions>
        include_path_common common-templates

        # template types include: HTMLTemplate, TemplateToolkit and Petal

        default_type        HTMLTemplate

        # Default options for each template type
        <HTMLTemplate>
            cache              1
            global_vars        1
            die_on_bad_params  0
        </HTMLTemplate>
        <TemplateToolkit>
            POST_CHOMP 1
        </TemplateToolkit>
        <Petal>
            POST_CHOMP 1
        </Petal>
    </TemplateOptions>

=head2 System Templates

In addition to regular templates there are also I<system templates>.
These are used to display the templates for the various runmodes that are
called automatically:

    * invalid_checksum.html
    * invalid_session.html
    * login.html
    * login_form.html
    * relogin.html
    * relogin_form.html

You can use a different set of options for the system templates than you
use for your ordinary templates.  For instance you can use
L<Template::Toolkit|Template> for your run mode templates, but use
L<HTML::Template> for the login and relogin forms.

The options for the I<system templates> are defined in the
C<SystemTemplateOptions> section in the top level C<framework.conf>:

    <SystemTemplateOptions>
        include_path_common common-templates

        default_type HTMLTemplate

        <HTMLTemplate>
            cache              1
            global_vars        1
            die_on_bad_params  0
        </HTMLTemplate>
    </SystemTemplateOptions>

With both C<TemplateOptions> and C<SystemTemplateOptions> the
configuration structure maps very closely to the data structure expected
by L<CGI::Application::Plugin::AnyTemplate>.  See the docs for that
module for further configuration details.

=head2 Where Templates are Stored

=head3 Application Templates

By default, your application templates are stored in the C<templates>
subdirectory of your application directory:

    /framework/
         projects/
             MyProj/
                applications/
                    myapp1/
                         templates/
                            runmode_one.html  # templates for myapp1
                            runmode_two.html

                    myapp2/
                         templates/
                            runmode_one.html  # templates for myapp2
                            runmode_two.html



=head3 Project Templates

By default, project templates are stored in the C<common-templates>
subdirectory of your project directory:

         projects/
             MyProj/
                common-templates/    # login and other common
                                     # templates go here


=head3 Pre- and Post- process

You can hook into the template generation process so that you can modify
every template created.  Details for how to do this can be found in the docs
for to L<CGI::Application::Plugin::AnyTemplate>.

=head1 EMBEDDED COMPONENTS

Embedded Components allow you to include application components within
your templates.

For instance, you might include a I<header> component a the top of every
page and a I<footer> component at the bottom of every page.

These componenets are actually first-class run modes.  When the template
engine finds a special tag marking an embedded component, it passes
control to the run mode of that name.  That run mode can then do
whatever a normal run mode could do.  But typically it will load its own
template and return the template's output.

This output returned from the embedded run mode is inserted into the
containing template.

The syntax for embed components is specific to each type of template
driver.

=head2 Syntax

L<HTML::Template> syntax:

    <TMPL_VAR NAME="CGIAPP_embed('some_run_mode')">

L<HTML::Template::Expr> syntax:

    <TMPL_VAR EXPR="CGIAPP_embed('some_run_mode')">

L<Template::Toolkit|Template> syntax:

    [% CGIAPP.embed("some_run_mode") %]

L<Petal> syntax:

    <span tal:replace="structure CGIAPP/embed 'some_run_mode'">
        this text gets replaced by the output of some_run_mode
    </span>


In general, the code for C<some_run_mode> looks just like any run mode.
For detailed information on how to use the embedded component system,
including how to pass parameters to run modes, see the docs for
C<CGI::Application::Plugin::AnyTemplate>.

=head1 SESSIONS

A I<session> is a scratchpad area that persists even after your
application exits.  Each user has their own individual session.

So if you store a value in the session when Gordon is running the
application, that value will be private for Gordon, and independent of
the value stored for Edna.

Sessions are accessible via C<< $self->session >>:

   $self->session->{'favourite_colour'} = 'blue';

   # time passes... and eventually the application is run a second time by
   # the same user...

   my $colour = $self->session->{'favourite_colour'};

   $self->template->fill('colour' => $colour);

=head1 LINKS

When using C<CGI::Application::Framework>, it is not recommended that you
create your own hyperlinks from page to page or that you modify the links
that CAF creates.  When you create an URL with one of the URL-generation
methods, CAF adds a checksum value to the URL.  When the URL is
followed, CAF verifies its integrity by validating the checksum.

If the user tampers with the checksum, they are redirected to a page
with a severe warning, and their session is destroyed.

So it's best to create URL's using the utility methods provided.

Having said that, these routines are still not very friendly, and there
is still work to be done in this area.

TODO:

  * easily make links to another app in the same project
  * easily make links to an app in a different project

=over 4

=item make_self_url

    my $url = $self->make_self_url;

=item make_link

    my $url = $self->make_link(url => $self->query->url);
    my $url = $self->make_link(url => $other_url);

Options for make_link

=over 4

=item url

The base URL (without query string).  Defaults to the URL for the current application.

=item params

=item with_checksum


=back

=cut

# sub new_make_link {
#
# }

=item redirect

This is just a utility method to perform an HTTP redirect:

    $self->redirect($self->make_link(url => $other_url));

=back

=head1 LOGGING

You can send logging messages via the C<log> method:

   $self->log->info('Information message');
   $self->log->debug('Debug message');

The various log levels available are:

 debug
 info
 notice
 warning
 error
 critical
 alert
 emergency

You can set up handlers for any of these levels in the C<framework.conf>
file. By default, the single handler installed only logs messages that
are of the C<warning> level or higher (i.e. it only logs messages of the
following levels: C<warning>, C<error>, C<critical>, C<alert>,
C<emergency>).

    <LogDispatch>
        <LogName file>
            module    = Log::Dispatch::File
            filename  = ../framework/projects/logs/webapp.log
            min_level = warning
            mode      = append
        </LogName>

        append_newline = 1
        format         = [%P][%d] %F %L %p - %m%n

    </LogDispatch>

If you change the C<min_level> line to:

    min_level = info

Then the handler will also log all C<info> and C<notice> messages as well.
If you change it to:

    min_level = debug

Then the handler will log all messages.

The following methods in C<$self> are useful for logging a message and
exiting the application all in one step:

=over 4

=item log_croak

Logs your message, indicating the caller, and then dies with the same message:

    $self->log_croak("Something bad happened");

=item log_confess

Logs your message with a full stacktrace, and then dies with the same message and stacktrace:

    $self->log_confess("Something bad happened - here's a ton of info");

=back

The following methods in C<$self> are useful for logging a message and
also printing a standard warning message to STDERR in the same step:

=over 4

=item log_carp

Logs your message, indicating the caller and then gives off a warning with the same message:

    $self->log_carp("Something strange is happening");

=item log_cluck

Logs your message with a full stack trace, and then gives off a warning with the same message and stacktrace:

    $self->log_cluck("Something strange is happening - here's a ton of info");

=back

=head1 AUTHENTICATION

Currently, all users of a CAF application have to login in order to use
the system.  This will change in a future release.

=head3 Application Flow

If the user is not logged in yet, they are taken to the login page.  If
they log in successfully, they are taken to the run mode they were
originally destined for.  Otherwise they are returned to the login page
and presented with an error message.

After the user has logged in, you may force them to log in again if
certain conditions are met.  For instance, you might to decide to force
users who have been idle for a certain period of time to log in again.

=head2 Runmodes

If you want, you can override the following runmodes.  A good place to do this is in
your project module.

=over 4

=item login

This runmode presents the login screen.

=item relogin

This runmode presents the login screen with the user's name already
filled in.

=item invalid_session

This runmode displays "invalid session" template.

=item invalid_checksum

This runmode displays "invalid checksum" template.


=back


=head2 Authentication Hooks

You B<MUST> provide the following authentication methods to define the
behaviour of your application.  A good place to do this is in your
project module. You can copy the methods in the Example project module
to get some sensible defaults.

=over 4

=item _login_authenticate

This method is expected to look at the C<$query> object and determine if
the user has successfully logged in.  The method should
return a two-element list indicating whether the user exists and whether
or not the password was correct:

    (0, undef) --> Unknown user
    (0, $user) --> user was found, incorrect password given
    (1, $user) --> user was found, password given correct


=item _relogin_authenticate

This method is similar to _login_authenticate.  It is expected to
determine the user's id from the session, and the password from the
query object.

The method should return a two-element list indicating whether the user
exists and whether or not the password was correct:

    (0, undef) --> Unknown user
    (0, $user) --> user was found, incorrect password given
    (1, $user) --> user was found, password given correct

=item _login_profile

This is a Data::FormValidate definition, needed by
CGI::Application::Plugin::ValidateRM

The specifics of this should match the needs of your C<login.html>
form-displaying HTML::Template.

=item _relogin_profile

This is a Data::FormValidate definition, needed by
CGI::Application::Plugin::ValidateRM

The specifics of this should match the needs of your C<relogin.html>
form-displaying HTML::Template.

=item _login_failed_errors

It has already been determined that the user did not successfully log
into the application.  So, create some error messages for the HTML
template regarding the 'login' mode to display.  This subroutine returns
$err which is a hashref to key/value pairs where the key is the name of
the template variable that should be populated in the event of a
certain kind of error, and the value is the error message it should
display.

Framework.pm provides $is_login_authenticated and $user
parameters to this subroutine so that this sub can perform the necessary
login checks.

Note that this isn't the same as that the login form was not
well-constructed.  Determining what is and what is not a syntactically
valid login form, and the generation of any needed error messages
thereof, is handled by the aspect of Framework.pm that calls uses
_login_profile, so make sure that whatever you need to do along these
lines is reflected there.


=item _relogin_failed_errors

Similar to _login_failed_errors but for the C<relogin.html>

=item _relogin_test

Here you do whatever you have to do to check to see if a transfer from
run mode -to- run mode within an application is good.  The
return value should be:

     1 - the relogin test has been successfully passed
         (implying no relogin authentication check)

     0 - the relogin test has been failed
         (implying a relogin authentication check is forced)

For example, a good candidate is to check for a "timeout".
If the user hasn't loaded a page within the application in
some duration of time then return 1 -- meaning that a
reauthentication isn't necessary.  If a reauthentication is
necessary then return 0.

=item _initialize_session

This method can be used to set whatever session variables make sense in
your application (or really in your collection of applications that use
this base class) given that a first-time successful login has just
occured.

=item _relogin_tmpl_params

This is used to provide template variables to the "relogin" form In this
case, the logical things to provide to the relogin form are uid and
username;  your application logic might differ.  Likely you should keep
all of this information the C<< $self->session >>, and you probably
should have populated the data into the session in the
C<_initialize_session> method.

=item _login_tmpl_params

This is used to provide template variables to the "login" form.

=back

=head1 CONFIGURATION

C<CGI::Application::Framework> uses
C<CGI::Application::Plugin::Config::Context> for its configuration
system.  C<Config::Context> supports multiple configuration backends:
C<Config::General>, C<Config::Scoped>, and C<XML::Simple>.

By default C<Config::General> format is used.  This format is similar to
Apache's configuration format.

It allows for single values:

    colour = red
    flavour = pineapple


And it allows for sections and subsections:

    <produce>
        <apple>
            colour red
        </apple>
        <strawberry>
            colour green
        </strawberry>
    </produce>

Additionally the C<Config::Context> allows for dynamic configuration
based on the runtime context of the current application.

This is similar to Apache's configuration contexts.  It looks like this:

    <Location /shop>
        title = ACME Coyote Supply Ltd.
    </Location>

    <LocationMatch admin>
        title = ACME Widgets INC - Site Administration
    </LocationMatch>

This allows you to use a single configuration file for multiple
applications.  It also allows you to make a single application
accessible through multiple URLs or virtual hosts; and the the way
the application is called determines its configuration.

Contexts are merged as well:

    <Location /shop>
        title = ACME Coyote Supply Ltd.
    </Location>

    <LocationMatch rockets>
        subtitle = - Rocket Launchers
    </LocationMatch>

    <LocationMatch tnt>
        subtitle = - Dynamite
    </LocationMatch>

    <LocationMatch magnets>
        subtitle = - Giant Magnets
    </LocationMatch>

By convention, in CAF projects there are four levels of configuration file:
Site-wide (also calld top-level), project and appplication:

    /framework/
         framework.conf              # Global CAF config file

         projects/
             MyProj/
                framework.conf       # MyProj config file

                applications/
                    framework.conf            # "All apps" config file
                    myapp1/
                         framework.conf       # myapp1 config file

                    myapp2/
                         framework.conf       # myapp2 config file



When a web request comes in to the system, these files are read in the
order of bottom to top:  application, then "all apps" then project, then
site. Settings made in the lower level files override settings made in
the higher level files.  Each framework.conf contains the line:

    <<include ../framework.conf>>

Which pulls in the configuration of its parent.

So the combination of context based matching plus per-application config
files gives you a lot of flexibility.

Configuration isn't just limited to setting options in your application.
Your application can pull its current configuration and put it into its
template.

For instance (using a single project wide config, matching on application URL):

    # in project framework.conf
    <location /bookshop>
        <extra_template_params>
            title      = ACME Roadrunner Reference, INC
            background = parchement.gif
        </extra_template_params>
    </location>

    <location /flowershop>
        <extra_template_params>
            title      = ACME Exploding Flowers, INC
            background = paisley.gif
        </extra_template_params>
    </location>


    # in myapp.pm
    sub run_mode {
        my $self = shift;
        my $config = $self->config->context;

        my $extra_params = $config->{'extra_template_params'}

        $self->template->fill($extra_params);
    }


Alternately you could skip the location matching and just have a
separate config file for each application.  Or you can mix and match
approaches.

=head2 Advanced Topic: Customizing the Configuration System

The following methods are provided as hooks for you to override the
configuration system if you need to do that.

=over 4

=item config_context_options

This sub returns the arguments passed to C<< $self->conf->init >>.  By
providing your own arguments, you can change the config backend from
C<Config::General> to a different backend.

=item config_file

This is the full URL to the application config file.  Since this
configuration file includes its parent, it is the entry point into the
configuration system.  You can change this value, but if you do, none of
the higher up configurations will be loaded.

By default, the full URL to the application configuration file is
determined using information from the C<run_app> method.

=item config_name

C<CGI::Application::Plugin::Config::Context> allows multiple named
configuration profiles:

    $self->conf('fred')->init(...);
    $self->conf('barney')->init(...);

This allows you to have multiple simultaneous configurations loaded,
each using its own options and backend.

By returning a value from C<config_name> you tell CAF to use that name
for accessing the configuration.

For instance by doing the following:

    sub config_name {
        'system';
    }

You would be effectively telling the configuration system to access the configuration like so:

    my $config = $self->conf('system')->context;

This would separate out the CAF configuration from your own application configuration.

Note however that if you wanted the default configuration (i.e.
C<< $self->config->context >> to still work, you would need to set it up
yourself by calling C<< $self->conf->init >> in your C<cgiapp_init>
method.

=item db_config_file

This is the name of the database config file.  By default it is the same
as C<< $self->config_file >>, but you could change it if you wanted to keep
the database configuration separate from your general application configuration.

=item db_config_name

This is the name of the database config name.  By default it is undef,
the same as C<< $self->config_name >>.  See L<config_name>, above.

=item template_config_name

The C<AnyTemplate> system also allows for multiple simultaneous configurations.
By default the C<template_config_name> is C<undef> so you can just say:

    $self->template->fill(...)

However you can set up multiple, named template configurations so that you can use:

    $self->template('ht')->fill(...)
    $self->template('tt')->fill(...)

By setting C<template_config_name> you are just telling the system what
name to use when initializing the template system.

=item system_template_config_name

Similar to C<template_config_name> this method allows you to set the
name used for I<system templates> (e.g. login, relogin, invalid
checksum, etc.). By default it is C<caf_system_templates>.

=back

=head1 DATABASE SUPPORT

B<Note:> The database support in CGI::Application::Framework is entirely by
convention.  You don't have to use C<Class::DBI> if you don't want to.
In fact, you don't have to use a database if you don't want to.

This section assumes that you are making an application similar to the
Example application.

CAF uses C<Class::DBI::Loader> to detect automatically your
database schema.

CAF Project database classes typically provide a C<setup_tables> subroutine.

This subroutine is configured to run at the 'database_init' phase by
registering a callback with C<CGI::Application>:

    sub import {
        my $caller = caller;
        $caller->new_hook('database_init');
        $caller->add_callback('database_init', \&setup_tables);
    }

All this code does is instruct CAF to run the C<setup_tables> subroutine
at a specific point at the beginning of the request cycle.  It happens
after the configuration files are loaded, but before the logging system
is initialized.

This means that your C<setup_tables> subroutine code has access to the
application configuration:

    my $config = CGI::Application::Plugin::Config::Context->get_current_context;

You can then pull the database connection info from your config file:

    sub setup_tables {

        my $config = CGI::Application::Plugin::Config::Context->get_current_context;

        my $db_config = $config->{'db_exmple'};

        my $loader = Class::DBI::Loader->new(
            debug         => 0,
            dsn           => $db_config->{'dsn'},
            user          => $db_config->{'username'},
            password      => $db_config->{'password'},
            namespace     => __PACKAGE__,
            relationships => 1,
        );
    }

This assumes that you have the something like the following section in
your C<framework.conf>:

    <db_example>
        dsn           = DBI:mysql:database=example
        username      = rdice
        password      = seekrit
    </db_example>

That's a complete mininimal database configuration.
C<Class::DBI::Loader> will automatically create CDBI classes in the
current namespace: one class per table in your database.

In the case of the Example apps, it means that you can say:

    my $first_user = CDBI::Example::example::Users->retrieve(1);

The example apps have a bit more code than the above.  For instance,
instead of letting Class::DBI::Loader automatically figure out the
relationships, the Example project defines them manually:

    CDBI::Example::example::Users->has_many( albums => 'CDBI::Example::example::UserAlbum');
    CDBI::Example::example::Artist->has_many( albums => 'CDBI::Example::example::Album' );
    CDBI::Example::example::Artist->has_many( songs  => 'CDBI::Example::example::Song'  );

It also provides some compatibility with persistent environments like
C<mod_perl>, by only running the C<setup_tables> sub once per process:

     my $Already_Setup_Tables;

     sub setup_tables {
         return if $Already_Setup_Tables;

         # set up the tables here....

         $Already_Setup_Tables = 1;
     }


=head1 DATABASE CONFIGURATION

C<CGI::Application::Framework>'s configuration system allows you to
change configuration settings based on the runtime context of your
applications.

If you want to have a different database connection for different
applications you have a couple of strategies available to you.

=head3 Database Config - Per Project

After setting up your database in the previous section, your site-wide
framework.conf file should contain a section like the following:

    <db_example>
        dsn           = DBI:mysql:database=example
        username      = rdice
        password      = seekrit
    </db_example>

The C<example> in the section name C<db_example> means that this section
applies only to the Example project.

To add a database connection for another project, e.g. named C<Finance>, add
another section:

    <db_finance>
        dsn           = DBI:Pg:dbname=finance
        username      = rdice
        password      = sooper-seekrit
    </db_finance>

(Note that the names of these database sections is somewhat
conventional; you can override these names in your application's
database modules.)

Since these are project-specific configurations, you are quite free to
put them in their respective project framework.conf files.  That is, you
can put the <db_example> section in:

    projects/Example/framework.conf

And you can put the <db_finance> section in:

    projects/Finance/framework.conf

Or you can keep them both in the site-wide file:

    projects/framework.conf

It's up to you how you choose to organize your configuration.

=head3 Database Config - Per Application

If you have two applications in the same project that each need a
different database handle, then you can do this in one of two ways.
The first option is to move the database configuration into the
application-specific framework.conf:

    projects/Finance/receivable/framework.conf

    <db_finance>
        dsn           = DBI:Pg:dbname=receivables
        username      = abbot
        password      = guessme
    </db_finance>

    projects/Finance/payable/framework.conf

    <db_finance>
        dsn           = DBI:mysql:database=payables
        username      = costello
        password      = letmein
    </db_finance>

The other option is to use the URL matching and Application matching
features of the underlying C<Config::Context> system.  For instance:

    projects/framework.conf

    <LocationMatch receiveables>
        <db_finance>
            dsn           = DBI:Pg:dbname=receivables
            username      = abbot
            password      = guessme
        </db_finance>
    </LocationMatch>

    <LocationMatch payables>
        <db_finance>
            dsn           = DBI:mysql:database=payables
            username      = costello
            password      = letmein
        </db_finance>
    </LocationMatch>

For more information on the <LocationMatch> directive and other run-time
configuration matching features, see the documentation for
CGI::Application::Plugin::Config::Context:

    http://search.cpan.org/dist/CGI-Application-Plugin-Config-Context/lib/CGI/Application/Plugin/Config/Context.pm

=head3 Database Config - Per Site

If you want to have multiple Apache virtual hosts running the same
C<CGI::Application::Framework> applications, then you can use the site
matching features of the configuration system:

    projects/framework.conf

    <Site CREDIT>
        <db_finance>
            dsn           = DBI:Pg:dbname=receivables
            username      = abbot
            password      = guessme
        </db_finance>
    </Site>

    <Site DEBIT>
        <db_finance>
            dsn           = DBI:mysql:database=payables
            username      = costello
            password      = letmein
        </db_finance>
    </Site>

To make this work, you will have to set an environment variable in the
C<< <Virtualhost> >> section in your Apache C<httpd.conf>

    <VirtualHost *>
        ServerName www.wepayu.com
        SetEnv SITE_NAME DEBIT
        # .... other per-host configuration goes here
    </VirtualHost>

    <VirtualHost *>
        ServerName www.youpayus.com
        SetEnv SITE_NAME CREDIT
        # .... other per-host configuration goes here
    </VirtualHost>

If you are mixing and matching databases, and you are running under a
persistent environment such as mod_perl, then you must make sure that
all of the schemas of all the databases you are using are identical as
far as C<Class::DBI> is concerned.  In practice that means that the
following items must be the same across databases:

    * table names
    * column names
    * which columns are primary keys

Other database details (such as how columns are indexed) may safely
differ from database to database.


=head1 DATABASE INSTALLATION

If you already have a database set up and you don't need to load the
example data for the Example applications to work, then you can skip
this section.

The Framework and its example programs support many databases.  In
theory, any database that has a C<DBD::*> driver and a C<Class::DBI::*>
subclass module is supported.  This distribution contains explicit
support for C<MySQL>, C<PostgreSQL> and C<SQLite>.  There are instructions for
setting up each of these databases below.

If you like you can use more than one of these databases at the same
time.  See L<"Using multiple database configurations"> below.

=head2 Database Installation - MySQL

This is how to create a MySQL database that works with the Example
applications.

In the C<framework/sql> directory, you will find a file called
C<caf_example.mysql>.  First, this must be loaded into the MySQL
database. As the root user, type:

    # cd framework/sql
    # mysql < caf_example.mysql

This will create the "example" database and one table with a
few pre-populated rows, "users", and a bunch of other empty tables.

You will want the web application to be able to access the "example"
database as a non-root user, so you need to grant access to the
database.  Do the following

    # mysql
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 28 to server version: 4.0.21-log

    Type 'help;' or '\h' for help. Type '\c' to clear the buffer.

    mysql> GRANT ALL PRIVILEGES ON example.* TO
        -> 'some_username'@'localhost' IDENTIFIED BY 'a_password';

Obviously, pick C<"some_username"> and C<"a_password"> that is appropriate
to your situation.  If you are doing this for test purposes then
perhaps you can just use the username of your regular Unix user
account and set an empty password.  Also, if you want the user to have
more privileges than just these you can modify this statement as
appropriate.  See:

    http://dev.mysql.com/doc/mysql/en/MySQL_Database_Administration.html

Item 5.6, "MySQL User Account Management", has information regarding
how to set up your grant statement.

Whatever you chose for some_username and a_password you must place these
into the configuration in your top-level framework.conf file:

    <db_example>
        dsn           = DBI:mysql:database=example
        username      = rdice
        password      = seekrit
    </db_example>

Note that other databases will require their own
<db_OTHER>...</db_OTHER> configuration blocks. More about this later.

For more information on the format of the 'dsn' parameter, consult the
DBD::mysql documentation:

    http://search.cpan.org/~rudy/DBD-mysql/lib/DBD/mysql.pm

The caf_example.mysql file does not contain all of the data needed in
order to populate the database with seed data for all of the example
programs of the Framework.  To load the rest of the data, do the
following:

    # cd framework/sql/
    # perl ./load_music_data.pl music_info.csv

This data is stored in a separate file and comes with its own loading
program, so that you can see more examples of how the CDBI modules is
used to accomplish real-life tasks.  Inspect the contents of the
C<load_music_data.pl> file to see how it works.

=head2 Database Installation - PostgreSQL

This is how to create a PostgreSQL database that works with the Example
applications.

First you must create the example database.

Connect to the postgres database as the postgres user:

    $ psql -U postgres template1

Turn off history recording for lines beginning with a space:

    template1=# \set HISTCONTROL ignoreboth

Add the example user (begin the line with a space so the password is not
recorded in the history):

    template1=#  CREATE USER some_username WITH password 'a_password' CREATEDB;

Obviously, pick C<"some_username"> and C<"a_password"> that is appropriate
to your situation.  If you are doing this for test purposes then
perhaps you can just use the username of your regular Unix user
account and set an empty password.

Quit the psql shell:

    template1=# \q

Start the psql shell again as the new user:

    $ psql -U some_username template1

Create the 'example' database:

    template1=> CREATE DATABASE example;
    template1=> \q

If you want, you can prevent the user from creating additional
databases:

    $ psql -U postgres template1
    template1=# ALTER USER some_username NOCREATEDB;
    template1=# \q

Postgres is often configured to not require passwords from local users
(including the postgres superuser).

If you are instaling on a public server, it is a good idea to require
passwords.

Do this by editing the ~postgres/data/pg_hba.conf file (as the root
user) and changing the lines from 'trust' to either 'md5' or 'crypt':

    local        all                                           crypt
    host         all         127.0.0.1     255.255.255.255     crypt


Next, import the database schema.

In the framework/sql directory, you will find a file called
C<caf_example.pgsql>.  Load this into the PostgreSQL database. Type:

    psql -U some_user -f caf_example.pgsql example

This will create the C<example> database and one table with a
few pre-populated rows, C<users>, and a bunch of other empty tables.

Whatever you chose for some_username and a_password you must place these
into the configuration in your top-level framework.conf file:

    <db_example>
        dsn           = DBI:Pg:dbname=example
        username      = rdice
        password      = seekrit
    </db_example>

For more information on the format of the 'dsn' parameter, consult the
C<DBD:Pg> documentation:

    http://search.cpan.org/~dbdpg/DBD-Pg-1.40/Pg.pm

The C<caf_example.pgsql> file does not contain all of the data needed in
order to populate the database with seed data for all of the example
programs of the Framework.  To load the rest of the data, do the
following:

    # cd framework/sql/
    # ./load_music_data.pl music_info.csv

This data is stored in a seperate file and comes with its own loading
program, so that you can see more examples of how the CDBI modules is
used to accomplish real-life tasks.  Inspect the contents of the
C<load_music_data.pl> file to see how it works.


=head2 Database Installation - SQLite

This is how to create a SQLite database that works with the Example
applications.

SQLite is a complete SQL database contained in a C<DBD> driver.  This means
you can use it on machines that aren't running a database server.

Each SQLite database is contained in its own file.  Database permissions are
managed at the filesystem level.  Both the file and the directory that
contains it must be writable by any users that want to write any data to
the database.

The SQLite database and directory should have been created by the CAF
installation script.  However these instructions also apply to SQLite
databases you create for other projects.

Create a directory to contain the SQLite databases:

    $ mkdir /home/rdice/Framework/sqlite

Change its permissions so that it is writeable by the group the
webserver runs under:

    # chown .web /home/rdice/Framework/sqlite
    # chmod g+w /home/rdice/Framework/sqlite

Add the group "sticky" bit so that files created in this directory
retain the group permissions:

    # chmod g+s /home/rdice/Framework/sqlite

Now import the example database shema.

SQLite does not come with a command line shell.  Instead, use the
dbish program which is installed as part of the C<DBI::Shell> module.

    dbish --batch dbi:SQLite:dbname=/home/rdice/Framework/sqlite/sqlite_db < caf_example.sqlite

This will create the C<example> database and one table with a
few pre-populated rows, C<users>, and a bunch of other empty tables.

Whatever you chose for some_username and a_password you must place these
into the configuration in your top-level framework.conf file:

    <db_example>
        dsn           = DBI:SQLite:dbname=/home/rdice/Framework/sqlite
        username      = rdice
        password      = seekrit
    </db_example>

For more information on the format of the 'dsn' parameter, consult the
C<DBD::SQLite> documentation:

    http://search.cpan.org/~msergeant/DBD-SQLite-1.08/lib/DBD/SQLite.pm

The caf_example.sqlite file does not contain all of the data needed in
order to populate the database with seed data for all of the example
programs of the Framework.  To load the rest of the data, do the
following:

    # cd framework/sql/
    # perl ./load_music_data.pl music_info.csv

This data is stored in a seperate file and comes with its own loading
program, so that you can see more examples of how the CDBI modules is
used to accomplish real-life tasks.  Inspect the contents of the
C<load_music_data.pl> file to see how it works.


=cut


sub login {

    my $self = shift;

    my $config = $self->conf($self->config_name)->context;

    $self->log->debug("At top of 'login' subroutine / run mode ");
    # ------------------------------------------------------------------
    # Note that the '_errs' param will be populated if there was
    # an error with the processing of a login form submission; this is a
    # CGI::Application::Plugin::ValidateRM ->check_rm method thing,
    # called from within the 'cgiapp_prerun' subroutine.  There are
    # tmpl_var fields within the .tmpl loaded below that correspond to
    # the entries named in $err.  After reading it, unset it so that
    # it isn't polluted with information the next time this sub is
    # accessed.
    # ------------------------------------------------------------------
    my $errs = shift || $self->_param_read_and_unset('_errs');
    $self->log->debug("\$errs is: " . Data::Dumper->Dump([$errs],[qw(*errs)]));

    # ------------------------------------------------------------------

    # ==================================================================
    # Populate the TMPL_VARs in the "login.html" form, as given above.
    # (Note that most of these are actually in the relogin_form.html
    # template file.  Look for these in a tmpls/.common(-*) directory.
    # ==================================================================
    my %tmplvars = ();

    $tmplvars{'FORM_NAME'}   = 'login';
    $tmplvars{'FORM_METHOD'} = 'POST';
    $tmplvars{'FORM_ACTION'} = $self->make_self_url();

    # ---------------------------------------------------
    # Take whatever form params from the $self that are
    # needed per the specific subclass and put these into
    # the template TMPL_VARs via %tmplvars
    # ---------------------------------------------------
    foreach my $hash ( $self->_login_tmpl_params() ) {
        while ( my ($key, $value) = each %$hash ) {
            $tmplvars{$key} = $value;
        }
    }


    $tmplvars{'webapp'} = $self;
    $tmplvars{'run_mode_tags'} = {
        COMEFROMRUNMODE
            => [ COMEFROM => $self->get_current_runmode ],
            CURRENTRUNMODE
            => [ CURRENT  => $self->get_current_runmode ],
            SUBMITTORUNMODE
            => [ SUBMITTO => $config->{'post_login_rm'} ],
    };
    # ======== end population of tmpl_vars =============================

    $self->template($self->system_template_config_name)->fill('login', \%tmplvars);
}

sub invalid_session {

    my $self = shift;
    # ------------------------------------------------------------------
    # Note that the '_errs' param will be populated if there was
    # an error with the processing of a login form submission; this is a
    # CGI::Application::Plugin::ValidateRM ->check_rm method thing,
    # called from within the 'cgiapp_prerun' subroutine.  There are
    # tmpl_var fields within the .tmpl loaded below that correspond to
    # the entries named in $err.  After reading it, unset it so that
    # it isn't polluted with information the next time this sub is
    # accessed.
    # ------------------------------------------------------------------
    my $errs = shift || $self->_param_read_and_unset('_errs');
    # ------------------------------------------------------------------

    my $self_url = $self->query->url;
    $self_url   .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    my $template = $self->template($self->system_template_config_name)->load;

    $template->param( SELF_URL => $self_url );

    $template->param($errs) if $errs;

    return $template->output();
}

sub invalid_checksum {

    my $self = shift;
    # ------------------------------------------------------------------
    # Note that the '_errs' param will be populated if there was
    # an error with the processing of a login form submission; this is a
    # CGI::Application::Plugin::ValidateRM ->check_rm method thing,
    # called from within the 'cgiapp_prerun' subroutine.  There are
    # tmpl_var fields within the .tmpl loaded below that correspond to
    # the entries named in $err.  After reading it, unset it so that
    # it isn't polluted with information the next time this sub is
    # accessed.
    # ------------------------------------------------------------------
    my $errs = shift || $self->_param_read_and_unset('_errs');
    # ------------------------------------------------------------------

    my $self_url = $self->query->url;
    $self_url   .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    my $template = $self->template($self->system_template_config_name)->load;

    $template->param( SELF_URL => $self_url );

    $template->param($errs) if $errs;

    return $template->output();
}

sub relogin {

    my $self = shift;
    # ------------------------------------------------------------------
    # Note that the '_errs' param will be populated if there was
    # an error with the processing of a login form submission; this is a
    # CGI::Application::Plugin::ValidateRM ->check_rm method thing,
    # called from within the 'cgiapp_prerun' subroutine.  There are
    # tmpl_var fields within the .tmpl loaded below that correspond to
    # the entries named in $err.  After reading it, unset it so that
    # it isn't polluted with information the next time this sub is
    # accessed.
    # ------------------------------------------------------------------
    my $errs = shift || $self->_param_read_and_unset('_errs');
    # ------------------------------------------------------------------

    # ==================================================================
    # Populate the TMPL_VARs in the "relogin.html" form, as given above.
    # (Note that most of these are actually in the relogin_form.html
    # template file.  Look for these in a tmpls/.common(-*) directory.
    # ==================================================================
    my %tmplvars = ();

    $tmplvars{'FORM_NAME'}   = 'relogin';
    $tmplvars{'FORM_METHOD'} = 'POST';
    $tmplvars{'FORM_ACTION'} = $self->query->url();
    $tmplvars{'FORM_ACTION'} .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};
    $tmplvars{'FORM_ACTION'} = $self->make_self_url();

    # ---------------------------------------------------
    # Take whatever form params from the $self that are
    # needed per the specific subclass and put these into
    # the template TMPL_VARs via %tmplvars
    # ---------------------------------------------------
    foreach my $hash ( $self->_relogin_tmpl_params() ) {
        while ( my ($key, $value ) = each %$hash ) {
            $tmplvars{$key} = $value;
        }
    }
    # ---------------------------------------------------

    my $template = $self->template($self->system_template_config_name)->load;
    $template->param(\%tmplvars);
    $template->param($errs) if $errs;

    $template->param('webapp' => $self);
    $template->param('run_mode_tags' => {
        COMEFROMRUNMODE => [ COMEFROM => 'relogin' ],
        SUBMITTORUNMODE => [ SUBMITTO => 'relogin' ],
    });
    # ======== end population of tmpl_vars =============================

    return $template->output;
}

sub _make_hidden_session_state_tag {

    my $self = shift;

    # ---------------------------------------------------------------------
    # We don't want (well, at least need) to generate a tag in the event of
    # having a cookie contain the state information.  (If we're working
    # through hidden form fields and URL parameters, then we do.)
    # ---------------------------------------------------------------------
    return '' if     !$self->param('session_state');
    return '' if     $self->param('session_state') eq SESSION_IN_COOKIE;
    return '' unless $self->session;
    # ---------------------------------------------------------------------

    return
        '<input type=hidden name="session_id" value="'
        . $self->query->escapeHTML($self->session->{_session_id})
        . '">';
}

sub _framework_init {
    my $self = shift;
    my %params = @_;

    # ----------------------------------------------------------
    # Initialize the config subsystem
    # ----------------------------------------------------------
    $self->_config_init;

    my $config = $self->conf($self->config_name)->context;

    $self->_log_init;

    # Setup any database classes at this point
    $self->new_hook('database_init');
    $self->call_hook('database_init');


    $self->mode_param('rm');
    $self->param( come_from_rm => 'come_from_' . $self->mode_param);
    $self->param( submit_to_rm => 'submit_to_' . $self->mode_param);
    $self->param( current_rm   => 'current_'   . $self->mode_param);

    $self->start_mode('login');
    $self->run_modes(
                     [ qw (
                           login
                           relogin
                           invalid_session
                           invalid_checksum
                           _echo_page
                           )
                       ]
                     );

    my $require_login = '';

    if (exists $config->{'require_login'}) {
        $require_login = $config->{'require_login'};
    } else {
        $require_login = 1;
    }

    $self->param( REQUIRE_LOGIN => $require_login);

    # build the template options (for system templates)
    my $template_options = $config->{'SystemTemplateOptions'};

    my $include_paths = $self->tmpl_path || [];
    foreach my $key (grep { /^include_path/ } keys %$template_options) {
        push @$include_paths, delete $template_options->{$key};
    }

    $self->template($self->system_template_config_name)->config(
        %$template_options,
        include_paths => $include_paths,
    );

    # build the template options (for normal user templates)
    $template_options = $config->{'TemplateOptions'};

    $include_paths = $self->tmpl_path || [];
    foreach my $key (grep { /^include_path/ } keys %$template_options) {
        push @$include_paths, delete $template_options->{$key};
    }

    $self->template($self->template_config_name)->config(
        %$template_options,
        include_paths => $include_paths,
    );

}

sub _login_failed_errors   { &__interface_death; }

sub _relogin_failed_errors { &__interface_death; }

sub _login_profile         { &__interface_death; }

sub _relogin_profile       { &__interface_death; }

sub _login_authenticate    { &__interface_death; }

sub _relogin_authenticate  { &__interface_death; }

sub _relogin_test          { &__interface_death; }

sub _initialize_session    { &__interface_death; }

sub _relogin_tmpl_params   { &__interface_death; }

sub _login_tmpl_params     { &__interface_death; }

sub __interface_death {

    my $self = shift;

    # -------------------------------------------------------
    # Recall that noone should ever make this package
    # ("Framework") and file ("Framework.pm") their
    # base class.  Framework.pm is meant to be
    # subclassed, where the subclass has specific
    # information regarding how to do an authentication, how
    # to populate the session with initial data, etc.
    #
    # Framework.pm is meant to provide the login/relogin
    # logic and to create the initial session and logging
    # objects which are composed within the $self.  I have
    # created a series of subroutines, with the name of the
    # sub prefixed with a "_", which indicate the subs that
    # the subclasses need to provide.  If the writer of a
    # subclass forgets to provide one of these then the
    # superclass, Framework, will provide it, but only
    # enough to cause the program to die with a meaningful
    # error message.
    #
    # This subroutine, __interface_death, is the common code
    # for all of the need-to-be-subclassed subroutines that
    # displays an error message which is hopefully meaningful
    # to the module author so that they get to work and do
    # the job they need to.
    # -------------------------------------------------------
    return $self->log_confess
        (
         __PACKAGE__
         . " only implements a virtual interface method for ["
         . (caller(1))[3]
         . "] -- implement this yourself in a subclass! "
         );
    # -------------------------------------------------------
}



# -------------------------------------------------------
# Configuration Methods
# -------------------------------------------------------


# -------------------------------------------------------
# config_file
#
#    my $path_to_config_file = $self->config_file;
#
# Can be overridden in your application.
# Search for an acceptable configuration file
#
# By default, following config files are searched for
# and the first one found is used.
#
#
#     $package/app.conf    #  (where $package is the name of the package
#                          #  of the application, e.g. 'example_1')
#     project.conf
#
#     ../framework.conf
#
# -------------------------------------------------------
sub config_file {
    my ($self) = @_;

    my $app_dir = $self->param('framework_app_dir')
        or croak "CAF->config_file: framework_app_dir not in params; need it to find config file\n";

    my $config_file = abs_path(File::Spec->catdir($app_dir, 'framework.conf'));

    $config_file or croak "CAF->config_file: could not find config file framework.conf in $app_dir\n";

    return $config_file;
}

# -------------------------------------------------------
# db_config_file
#
#    my $path_to_db_config_file = $self->db_config_file;
#
# Can be overridden in your application.
# Search for an acceptable database configuration file
#
# By default, db_config_file returns $self->config_file
# meaning that the same file is used for both database and
# application configuration.
# -------------------------------------------------------

sub db_config_file {
    my ($self) = @_;
    $self->config_file;
}

# -------------------------------------------------------
# config_name
#
#    my $config_name = $self->config_name;
#
# Can be overridden in your application.
# Returns the name of the CGI::Application::Plugin::Config::Context
# config to be used by default in the application.
#
# By default, this is left undefined, which means you can use the more
# convenient 'unnamed' form:
#
#    my $config = $self->conf->context;
#
# -------------------------------------------------------
sub config_name {
    undef;
}


# -------------------------------------------------------
# db_config_name
#
#    my $db_config_name = $self->db_config_name;
#
# Can be overridden in your application.
# Returns the name of the CGI::Application::Plugin::Config::Context
# config to be used for database configuration values.  This doesn't
# actually affect how your database classes load their config;
# it's here because the application controls the initialization of
# all configurations, and the database configuration has to be included.
#
# By default, this is left undefined, which means that the database
# config shares the default 'unnamed' config:
#
#    my $db_config = $self->conf->context;
#
# -------------------------------------------------------
sub db_config_name {
    undef;
}


# -------------------------------------------------------
# _config_init
#
#    $self->_config_init;
#
# Can be overridden in your application.
# This method initializes the config subsystem,
#
# By default it calls:
#
#     $self->conf($self->config_name)->init($config_file);
#
# and (if the db_config_name is different), it also calls:
#
#     $self->conf($self->db_config_name)->init($db_config_file);
#
# You can initialize multiple configurations here
# if you like.
#
# Be aware that the framework itself expects that
# $self->conf($self->config_name) remains a valid
# configuration.
# -------------------------------------------------------
sub _config_init {
    my ($self) = @_;
    my $config_name    = $self->config_name;
    my $db_config_name = $self->db_config_name;

    my $config_file = $self->config_file
                    || die "Config file not specified\n";

    $self->conf($config_name)->init(
         file => $config_file,
         %{ $self->config_context_options },
    );

    # one or both of $config_name and $db_config_name may be undefined
    no warnings 'uninitialized';

    if ($config_name ne $db_config_name) {
        my $db_config_file = $self->db_config_file;
        if ($db_config_file) {
            $self->conf($db_config_name)->init(
                file => $db_config_file,
                %{ $self->config_context_options },
            );
        }
        else {
            warn "DB Config file not specified\n";
        }
    }
}

# -------------------------------------------------------
# config_context_options
#
# Can be overridden in your application.
# This method should return any options to be passed
# on to Config::Context.
#
# For instance:
#     sub config_context_options {
#         return {
#             ConfigGeneral => {
#                 -MergeDuplicateBlocks   => 1,
#                 -MergeDuplicateOptions  => 1,
#                 -AutoLaunder            => 1,
#                 -AutoTrue               => 1,
#             }
#         };
#     }
#
# -------------------------------------------------------
sub config_context_options {
    return {
        driver => 'ConfigGeneral',
        driver_options => {
            ConfigGeneral => {
                -IncludeRelative        => 1,
                -MergeDuplicateBlocks   => 1,
                -MergeDuplicateOptions  => 1,
                -AutoLaunder            => 1,
            }
        }
    };
}

# -------------------------------------------------------
# template_config_name
#
#    $self->template($self->template_config_name)->fill('some_page', \%tmplvars);
#
# Can be overridden in your application.
# Returns the name of the CGI::Application::Plugin::AnyTemplate
# config to be used for normal templates within the application
#
# By default, this is left undefined, which means you can use the more
# convenient 'unnamed' form:
#
#    $self->template->fill('page', \%params);
#
# -------------------------------------------------------
sub template_config_name {
    undef;
}

# -------------------------------------------------------
# system_template_config_name
#
#    $self->template($self->system_template_config_name)->fill('some_page', \%tmplvars);
#
# Can be overridden in your application.
# Returns the name of the CGI::Application::Plugin::AnyTemplate
# config to be used for system templates within the application
#
# By default, this is 'caf_system_templates'
#
# -------------------------------------------------------
sub system_template_config_name {
    'caf_system_templates';
}

# ----------------------------------------------------------
# Initialize the logging subsystem
# ----------------------------------------------------------

sub _log_init {
    my $self = shift;

    my $config = $self->conf($self->config_name)->context;

    # ----------------------------------------------------------
    # Set up a logging object and use it everywhere!
    # ----------------------------------------------------------

    my $log_config = $config->{'LogDispatch'};
    my $log_names  = $log_config->{'LogName'} || {};

    my @log_modules;
    foreach my $name (keys %$log_names) {
        $log_names->{$name}{'name'} ||= $name;
        push @log_modules, $log_names->{$name};
    }

    my %log_options = (
        LOG_DISPATCH_MODULES => \@log_modules,
    );

    if ($log_config->{'format'}) {
        my @callbacks = @{ $log_config->{'options'}{'callbacks'} ||= [] };
        push @callbacks, Log::Dispatch::Config->format_to_cb($log_config->{'format'});
        $log_config->{'options'}{'callbacks'} = \@callbacks;
    }
    if ($log_config->{'options'}) {
        $log_options{'LOG_DISPATCH_OPTIONS'} = $log_config->{'options'};
    }
    if ($log_config->{'append_newline'}) {
        $log_options{'APPEND_NEWLINE'} = 1;
    }

    $self->log_config(%log_options);

    $self->log->debug("logging system initialized: (pid: $$)");

}

sub log_croak {
    my $self = shift;
    $Carp::CarpLevel = 1;
    my $message = Carp::shortmess(@_);
    $self->log->emergency($message);
    die $message;
}
sub log_carp {
    my $self = shift;
    $Carp::CarpLevel = 1;
    my $message = Carp::shortmess(@_);
    $self->log->warning($message);
    warn $message;
}

sub log_confess {
    my $self = shift;
    $Carp::CarpLevel = 1;
    my $message = Carp::longmess(@_);
    $self->log->emergency($message);
    die $message;
}

sub log_cluck {
    my $self = shift;
    $Carp::CarpLevel = 1;
    my $message = Carp::longmess(@_);
    $self->log->warning($message);
    warn $message;
}

sub _framework_postrun {

    my $self = shift;

    $self->log->debug(
                      "In 'cgiapp_postrun', the current run mode is : "
                      . $self->get_current_runmode()
                      );

    # ------------------------------------------------------------
    # "touch" the timestamp within the persistent session hash for
    # this session (ultimately derived from / tied together with
    # the 'session_id' cookie.  This is important with regards to
    # the time-out (via _relogin_test) system.
    # ------------------------------------------------------------

    # ------------------------------------------------------------
    # Don't update the timestamp under "special" circumstances;
    # for instance, when the timeout re-login procedure is being
    # run through, or when the program is just being logged in.
    # ------------------------------------------------------------
    return if $self->get_current_runmode() eq $self->start_mode();
    return if $self->get_current_runmode() eq 'invalid_session';
    return if $self->param('_login_loop');
    # ------------------------------------------------------------
    # Not a special circumstance, therefore update the time stamp
    # ------------------------------------------------------------
    $self->session->{_timestamp} = Time::HiRes::time();
    # ------------------------------------------------------------

    return;
}

sub _framework_prerun {

    my $self = shift;
    my $config = $self->conf($self->config_name)->context;

    # =====================================================================
    # I would say that this subroutine forms the core of the Framework
    # framework.  It provides the logic to see if the user is attemping a
    # first-time login, in which case display a login form, authenticate
    # the user's attempts to log in, and upon (eventual) success create
    # a session for the user and allow them to proceed onwards to the
    # application.  It also applies the "relogin" logic, which is
    # essentially a time-out check for the user within the web application.
    # It also enforces various checks on the integrity of the session and
    # the application.  For instance, a checksum on the HMAC with
    # QUERY_STRING parameters.  (I.e. if a user tries to mess with his
    # URL parameters, then they'll be caught and their session killed.)
    # =====================================================================

    $self->log->debug("In 'cgiapp_prerun' just before checking the runmode\n"
                      . " --> current run mode : "
                      . $self->get_current_runmode()
                      . "\n"
                      . " --> start mode : "
                      . $self->start_mode()
                      );

    if ( $self->get_current_runmode() eq $self->start_mode() ) {

        # ---------------------------------------------------------------
        # This is the very very very first loading of the application;
        # the 'rm' query param was not set, so we fell through to the start mode
        # we don't want to do anything in here, so get the hell out.
        # Where we will go to from here is the 'login' run mode, which
        # will display the login screen and that's about it.
        # ---------------------------------------------------------------

        $self->log->debug("Here, ->get_current_runmode eq ->start_mode()\n"
                          . ' --> per get_current_runmode() = '
                          . $self->get_current_runmode()
                          . "\n"
                          . ' --> per start_mode() = '
                          . $self->start_mode());
        return;
    }

    $self->log->debug("I made it past the login run mode check");

    if ( $self->query->param($self->param('come_from_rm'))
        and $self->query->param($self->param('come_from_rm')) eq 'login' ) {

        #
        # This is a "first time" login attempt, so...
        #
        $self->log->debug("About to validate a first time login");

        # ---------------------------------------------------------
        # First, make sure that the form submission is at least
        # barely within specification (i.e. provides a user id and
        # a password, and that the user id is numeric)
        #
        # Note that since we are within cgiapp_prerun, we have to
        # modify our usage of ->check_rm slightly in that we will
        # still use it to check the form and to generate errors
        # but *not* to generate the returning error page.  Rather,
        # we will dispatch that with a prerun_mode handler. (We
        # do generate the "error page", but we ignore it.)
        # ---------------------------------------------------------

        if (!$config->{'use_http_auth'}) {
            my ($errs, $err_page) = $self->check_rm(
                                                    'login',
                                                    $self->_login_profile
                                                    );

            if ( $err_page ) {
                $self->log->debug("I thought err_page was true! ");
                $self->param( _echo => $err_page );
                $self->param( _login_loop => 1 );
                $self->prerun_mode('_echo_page');
                return;
            }
            $self->log->debug("First time login form was well-formed");
        }
        # ---------------------------------------------------------

        # ---------------------------------------------------------
        # A numeric user id and a password were provided... now,
        # make sure that they match...
        # ---------------------------------------------------------
        my ($is_login_authenticated, $user) = $self->_login_authenticate();
        if ( $is_login_authenticated ) {

            # ---------------------------------------------------
            # if the authentication is successful then we've got
            # to create an entirely new session, including the
            # cookie that goes along with the session, _and_ we
            # have to register that cookie with the HTTP header
            # outputting aspect of the CGI::Application framework
            # ---------------------------------------------------

            $self->log->debug("Login authenticate:  current runmode = "
                              . $self->get_current_runmode);

            tie(my %session,
                'Apache::SessionX',
                undef,
                $config->{'SessionParams'});
            $self->param( session => \%session);
            $self->header_props( -cookie =>
                                 $self->query->cookie
                                 (
                                  -name  => 'session_id',
                                  -value => $session{_session_id},
                                  )
                                 );

            # ---------------------------------------------------

            # ---------------------------------------------------
            # This is the first time we've ever seen the session,
            # so right away define the uid for this session
            # based on the information in the login form.
            # Runmodes that do something will probably care
            # quite a bit regarding which user is trying to do
            # something with the application, natch.
            # ---------------------------------------------------
            $self->_initialize_session($user);
            # ---------------------------------------------------

            # ---------------------------------------------------
            # that's all there is to it... now we'll fall-through
            # to the run-mode to which we should go to upon
            # successful login, as defined by the appropriate
            # hidden input "rm" tag in the login form.
            # ---------------------------------------------------
            $self->param( _login_loop => 0 );
            return;
            # ---------------------------------------------------

        } else {


            # -----------------------------------------------------
            # The user apparently didn't give a good username and
            # password, so we're going to send them back to the login
            # page, which will submit as a new login (i.e. won't
            # ever try to make use of a cookie -- will always
            # create its own if successful)
            # -----------------------------------------------------
            my $errs = $self->_login_failed_errors
                (
                 $is_login_authenticated,
                 $user
                 );

            $self->param( _errs => $errs );
            $self->prerun_mode('login');
            return;
            # -----------------------------------------------------
        }

    } else {

        if ($self->query->param('come_from_rm')) {
            $self->log->debug("Come from run mode = "
                              . $self->query->param('come_from_rm'));
        }
        else {
            $self->log->debug("Come from run mode not specified");
        }

        # --------------------------------------------------------------------
        # Try what we can to get a session ID, and set various parameters
        # corresponding to what we came across in the attempt.  If we can't
        # find a sesison ID, croak.
        # --------------------------------------------------------------------
        my $session_id = '';
        unless ( $session_id = $self->get_session_id ) {

            # ----------------------------------------------------------------
            # XXX fixme --
            # give it a prerun_mode instead so that users don't get a 500
            # error... maybe just piggyback on "invalid_session"?
            # ----------------------------------------------------------------

            $self->log_confess(
                 "Session_id couldn't be found:\n"
                 . "   from cookie --> ["
                 . eval { $self->query->cookie('session_id') }. "]\n"
                 . "   from URL    --> ["
                 . eval { $self->query->url_cookie('session_id') }. "]\n"
                 . "   from HFF    --> ["
                 . eval { $self->query->param('_session_id') }. "]\n"
                 . "   state message   --> ["
                 . eval { $self->param('session_state') }
                 . "] "
            );

        }
        # --------------------------------------------------------------------

        # --------------------------------------------------------------------
        # Now, try to reconstitute the session given a session ID.  If we
        # can't find a session with this session ID, kick out to a prerun
        # mode to display an error page to the user.
        # --------------------------------------------------------------------
        my %session = ();

        eval { tie(%session,
                   'Apache::SessionX',
                   $session_id,
                   $config->{'SessionParams'}); };

        if ( $@ ) { # there was an error in the creation of the session

            # --------------------------------------------------------------
            # Couldn't create a session, so give the user an error page
            # and log and error.  Hoever, given a $session_id this really
            # shouldn't fail -- it's not like users can create $session_id's
            # directly, and any session_id created by this system should
            # be internally consistent, or else there is a bug somewhere
            # in this code.  (Or maybe some bright boy cooked up a session
            # reaper that act autonomously on this system?)
            # --------------------------------------------------------------

            $self->log->debug
                (
                 "Couldn't make session with session_id [$session_id] "
                 );

            $self->prerun_mode('invalid_session');

            return;
        }
        # --------------------------------------------------------------------

        # --------------------------------------------------------------------
        # We have a %session, so stick it inside of our $self so that we can
        # carry it around the application.
        # --------------------------------------------------------------------
        $self->param( session => \%session );
        # --------------------------------------------------------------------

        # ------------------------------------------------------------------
        # This seems like a good place to put in a check to make sure that
        # any query-string that is provided to us validates against the
        # _checksum field that is also part of the query-string. (If there
        # is no query- string, then the check automatically comes back
        # 'okay'.)
        # ------------------------------------------------------------------
        unless ( $self->_checksum_okay ) {

            # -------------------------------------------------
            # If a user tries to modify their URL parameters
            # then their session is destroyed
            # -------------------------------------------------
            tied(%{$self->session})->delete;

            $self->prerun_mode('invalid_checksum');
            return;
        }
        # ------------------------------------------------------------------

        if ( $self->query->param('come_from_rm') and $self->query->param('come_from_rm') eq 'relogin' ) {

            $self->log->debug("come_from_rm eq 'relogin'");

            # --------------------------------------------------------
            # (see below 'else' block for info on how we got here...
            # --------------------------------------------------------

            # ---------------------------------------------------------
            # Make sure that the form submission is at least
            # barely within specification (i.e. provides a user id and
            # a password, and that the user id is numeric)
            #
            # Note that since we are within cgiapp_prerun, we have to
            # modify our usage of ->check_rm slightly in that we will
            # still use it to check the form and to generate errors
            # but *not* to generate the returning error page.  Rather,
            # we will dispatch that with a prerun_mode handler. (We
            # do generate the "error page", but we ignore it.)
            # ---------------------------------------------------------
            my ($errs, $err_page) = $self->check_rm(
                                                    'relogin',
                                                    $self->_relogin_profile
                                                    );

            if ( $err_page ) {
                $self->log->debug("err_page was true");
                $self->param( _echo => $err_page );
                $self->param( _login_loop => 1 );
                $self->prerun_mode('_echo_page');
                return;
            }

            my ($is_login_authenticated, $user)
                = $self->_relogin_authenticate();

            if ( $is_login_authenticated ) {

                # ------------------------------------------------------
                # Reauthentication from relogin worked, so continue with
                # the application.  Note that we *don't* need to do all
                # the other set-up crap that we had to do when we
                # successfully authenticated on a first-time login.
                #
                # Note that we "reconstitute" the "original" CGI.pm
                # query object here;  that is, the one that was
                # created from the user's original request/submission
                # before they got trapped in the relogin loop.
                # It would probably be less rude to make the object
                # via classing of ->cgiapp_get_query or ->query than
                # with the direct access to the underlying datum.
                # ------------------------------------------------------

                {
                    no strict 'refs';
                    my $query;

                    $self->{__QUERY_OBJ} = eval $self->session->{_cgi_query};
                }

                delete $self->session->{_cgi_query};

                unless ($self->{__QUERY_OBJ}) {
                    die "could not vivify query object";
                }

                $self->prerun_mode($self->query->param($self->mode_param));

                return;
                # ------------------------------------------------------

            } else {

                # -------------------------------------------------------
                # User didn't successfully re-authenicate, so we have to
                # send them back to the reauthentication page.  Set a few
                # error messages before we do that, though.
                # -------------------------------------------------------
                # XXX fixme -- this should be parcelled off to an area
                # in the subclass that is allowed to know about the
                # specific structure of the login authentication form.
                # -------------------------------------------------------

                my $errs = $self->_relogin_failed_errors
                    (
                     $is_login_authenticated,
                     $user
                     );

                $self->param( _errs => $errs );
                $self->prerun_mode('relogin');

                return;
                # -------------------------------------------------------
            }

        } else {

            $self->log->debug("Looks like we didn't come from 'relogin'");

            if ( $self->_relogin_test() ) {

                # ------------------------------------------------------
                # no problems with time-out check, so continue with
                # web application run...
                # ------------------------------------------------------
                return; # these aren't the droids we're looking for
                # ------------------------------------------------------

            } else {

                # ------------------------------------------------------
                # The session time-out'd, therefore make them cough up a
                # new password, first by redirecting them to a form.
                #
                # Note that the state of the $self-query is saved in
                # the session, so that it may be reconstituted later,
                # for the sake of figuring out where the submit-to
                # run mode was supposed to be, so that form submission
                # data is not lost due to a timeout, etc.
                # ------------------------------------------------------
                my $session_query = '';
                {
                    local $Data::Dumper::Indent = 0;
                    # local $Data::Dumper::Useqq  = 1;  # this creates problems
                    $session_query
                        = Data::Dumper->Dump([$self->query], [ '$query' ]);
                }
                $session_query =~ s/\$query = //;
                $session_query =~ s/;$//;
                $self->session->{_cgi_query} = $session_query;
                $self->prerun_mode('relogin');
                return;
                # ------------------------------------------------------

            } # end of if $self->_relogin_test
        }
    }

    return; # guess that's about it...
}


# ------------------------------------------------------------------
# These methods are new and unique to CGI::Application::Framework
# ------------------------------------------------------------------
sub _make_run_mode_tag {

    my $self   = shift;
    my %params = @_;

    my $whichmode = undef;

    if ( $params{whichmode} eq 'COMEFROM' ) {
        $whichmode = 'come_from_' . $self->mode_param();
    } elsif ( $params{whichmode} eq 'CURRENT' ) {
        $whichmode = 'current_' . $self->mode_param();
    } elsif ( $params{whichmode} eq 'SUBMITTO' ) {
        $whichmode = $self->mode_param();
    } else {
        $self->log_confess("Unsupported run mode [$params{whichmode}] ");
    }

    return
        '<input type=hidden name="'
        . $whichmode
        . '" value="'
        . $self->query->escapeHTML($params{modevalue})
        . '">';
}

sub _param_read_and_set {

    my $self = shift;
    my $param = shift;

    my $value = $self->param($param);
    $self->param($param => ($value || 1));
    return $value;
}

sub _param_read_and_unset {

    my $self = shift;
    my $param = shift;

    my $value = $self->param($param);
    $self->param($param => undef);
    return $value;
}

sub make_self_url {

    my $self = shift;

    # -----------------------------------------------------------------------
    # I had to do all this ugly stuff to create a URL + query string
    # (the latter if necessary) because a simple $self->query->url(-query=>1)
    # was doing weird stuff, like joining key/value pairs with ';' instead
    # of '&', and building the query string out of the full form submission,
    # rather than just with stuff that's just in the query string) even when
    # the form method was POST. (!?!)
    # -----------------------------------------------------------------------
    my $self_url = $self->query->url();
    if ( $ENV{PATH_INFO} ) {
        $self_url .= $ENV{PATH_INFO};
    }
    if ( $ENV{QUERY_STRING} ) {
        $self_url .= '?' . $ENV{QUERY_STRING};
    }
    # -----------------------------------------------------------------------

    return $self_url;
}

sub get_session_id {

    my $self = shift;

    if ( $self->query->cookie('session_id') ) {
        $self->param( session_state => SESSION_IN_COOKIE );
        return $self->query->cookie('session_id');
    }

    if ( $self->query->url_param('_session_id') ) {
        $self->param( session_state => SESSION_IN_URL );
        return $self->query->url_param('_session_id');
    }

    if ( $self->query->param('_session_id') ) {
        $self->param( session_state => SESSION_IN_HIDDEN_FORM_FIELD );
        return $self->query->param('_session_id');
    }

    if ( $self->session and $self->session->{_session_id} ) {
        $self->param( session_state => SESSION_FIRST_TIME );
        return $self->session->{_session_id};
    }

    $self->param( session_state => SESSION_MISSING );
    return undef;
}

sub _echo_page {
    my $self = shift;
    return $self->param('_echo');
}




sub make_link {

    # -------------------------------------------------------------------------
    # This sub is a real cock-up, as I wanted to give it backward compatibility
    # with the version of this sub in CGI::Application::Framework::Utils, which
    # is purely procedural.  This version is "smart" enough to know if it should
    # behave procedurally or as a method.  Note that the procedural version
    # of this mandates the Exporter-oriented stuff in this otherwise-OO module.
    #
    # If it is called with a 'url' parameter, it will generate a link with
    # that URL.  Otherwise, if it is called as a method *and* no 'url' has been
    # specified, then it will use the $self->query->url provided by the
    # composed CGI.pm object.
    #
    # By default links will be created with _session_id turned on.  Application
    # programmers can provide their own _session_id by providing it in the
    # qs_args hashref.  If 'no_session' is set to true then _session_id will
    # not be generated automatically (but any provided through qs_args will
    # still be created).
    #
    # 'with_checksum' is set to 1 as default, i.e. MD5 checksums of query
    # strings are created.  The sessioning system should trigger on this to
    # ensure that query-string are as they are supposed to be.
    # ------------------------------------------------------------------------
    #
    # Examples:
    #
    # 1) This will generate a query-string that includes _session_id and
    #    _checksum name/value pairs.  The URL generated will be
    #    $self->query-url.  Nasty characters in the name/value pairs will be
    #    appropriately URL-escaped.
    #
    # $self->template->param( SOME_LINK => $self->make_link
    #                        (
    #                        qs_args => {
    #                            name => 'Richard Dice',
    #                            job  => 'Programmer (& Biz-knob?!?)'
    #                            }
    #                        )
    #                       );
    # 2) No _checksum will be generated.  _session_id will be taken from the
    #    qs_args.  url will be taken as given here as the 'url' param.
    #    Nasty characters in the name/value pairs will be appropriately
    #    URL-escaped.
    #
    # $self->template->param( SOME_LINK => $self->make_link
    #                       (
    #                        with_checksum => 0,
    #                        no_session    => 1,
    #                        url           => 'http://www.nowhere.com/foo.pl'
    #                        qs_args => {
    #                            _session_id => '12345',
    #                            name => 'Richard Dice',
    #                            job  => 'Programmer (& Biz-knob?!?)'
    #                            }
    #                        )
    #                       );
    #
    # -----------------------------------------------------------------------

    my $self = shift;

    my $config = $self->conf($self->config_name)->context;

    my $self_url = $self->query->url;

    if ( $ENV{PATH_INFO} ) {
        $self_url .= $ENV{PATH_INFO};
    }


    my %defaults = (
                    (
                     ref($self)
                     ? (
                        $self->isa(__PACKAGE__)
                        ? (
                           url         => $self_url,
                           _session_id
                           => $self->session->{_session_id},
                           )
                        : ()
                        )
                     : ()
                     ),
                    with_checksum => 1,
                    );
    my %params   = (%defaults, @_);

    unless ( $params{no_session} ) {
        unless ( exists($params{qs_args}->{_session_id}) ) {
            $params{qs_args}->{_session_id} = $params{_session_id};
        }
    }

    my $buffer = '';

    if ( $params{url} ) {
        $buffer .= $params{url}
    }

    if ( $params{qs_args} ) {

        if ( $params{url} ) {
            $buffer .= '?';
        }

        $buffer .= CGI::Enurl::enurl($params{qs_args});
    }

    if ( $params{with_checksum} ) {

        if ( $params{qs_args} ) {
            $buffer .= '&';
        } else {
            if ( $params{url} ) {
                $buffer .= '?';
            }
        }

        $buffer
            .= '_checksum='
            . Digest::MD5::md5_hex(Digest::MD5::md5($buffer . $config->{'md5_salt'}));
    }
    # print STDERR "made link: $buffer\n";

    return $buffer;

}

sub _checksum_okay {

    my $self = shift;
    my $config = $self->conf($self->config_name)->context;

    # print STDERR "0.here\n";
    # print STDERR "query->param('_checksum'): " . $self->query->param('_checksum') . "\n";

    # -----------------------------------------------------------------
    # If there are no query string parameters then there is no need to
    # worry about a checksum, therefore everything is okay... return 1
    # -----------------------------------------------------------------
    # print STDERR "1.here\n";
    return 1 unless $ENV{QUERY_STRING};
    # -----------------------------------------------------------------
    # If we have a query string then we *must* have a _checksum
    # parameter... return 0
    # -----------------------------------------------------------------
    # print STDERR "QUERY_STRING: $ENV{'QUERY_STRING'}\n";
    # print STDERR "2.here\n";

    my $checksum = $self->query->url_param('_checksum') || $self->query->param('_checksum');
    return 0 unless $checksum;
    # -----------------------------------------------------------------

    # -----------------------------------------------------------------
    # Find the checksum and the public info that was used to create
    # the checksum
    # -----------------------------------------------------------------
    my $complete_url = $self->query->url;

    if ( $ENV{PATH_INFO} ) {
        $complete_url .= $ENV{PATH_INFO};
    }
    # print STDERR "3.here\n";

    $complete_url .= '?' . $ENV{QUERY_STRING};
    $complete_url =~ s/_checksum=(\w+)$//;
    # my $checksum = $1;
    # print STDERR "complete_url: $complete_url; checksum: $checksum\n";
    # -----------------------------------------------------------------

    # -----------------------------------------------------------------
    # Recompute a new checksum with the public info found and the
    # same secret key used to make the original checksum.
    # -----------------------------------------------------------------
    my $recomputed_checksum = Digest::MD5::md5_hex
        (
         Digest::MD5::md5
         ($complete_url . $config->{'md5_salt'})
         );
    # -----------------------------------------------------------------
    # print STDERR "complete_url: $ENV{PATH_INFO}; checksum: $checksum; recomputed: $recomputed_checksum\n";

    # -----------------------------------------------------------------
    # If the recomputed checksum is the same as the retrieved checksum
    # then success!
    # -----------------------------------------------------------------
    return 1 if $recomputed_checksum eq $checksum;
    # -----------------------------------------------------------------
    # print STDERR "4.here\n";
    return 0;
}

# -------------------------------------------------------------------
# The "session" subroutine enables the $self->session->{'foobar'}
# syntax, rather than the bulkier $self->param('session')->{'foobar'}
# -------------------------------------------------------------------
sub session {
    my $self = shift;
    return $self->param('session') || undef;
}


# -------------------------------------------------------------------
# _framework_template_pre_process is called right before a template is
# rendered. It is called with the $template object as its first parameter.
#
# The job of this callback is to modify any of the parameters to the
# template before it gets filled.
#
# The system needs certain parameters set (such as the run mode tags, the
# SESSION_STATE, etc.).
#
# -------------------------------------------------------------------

sub _framework_template_pre_process {
    my ($self, $template) = @_;

    # Change the internal template parameters by reference
    my $params = $template->get_param_hash;

    # Add the public configuration params to all templates
    $template->param(scalar $self->conf->context);

    $params->{'SESSION_STATE'} = $self->_make_hidden_session_state_tag;

    if ( $params->{'run_mode_tags'} ) {
    	foreach my $tag ( keys %{$params->{'run_mode_tags'}} ) {
            $params->{$tag} = $self->_make_run_mode_tag
             (
              whichmode => $params->{'run_mode_tags'}->{$tag}->[0],
              modevalue => $params->{'run_mode_tags'}->{$tag}->[1],
              );
        }
    }
}

# -------------------------------------------------------------------
# _framework_template_pre_process is called right after a template is
# rendered. It is called with the $template object as its first parameter,
# and a reference to the output text as its second parameter.
#
# The job of this callback is to modify the text generated by the template
# engine.
#
# By default the system adds comments to the beginning and ending of every
# template indicating the filename of the template.  This is useful for
# debugging purposes.
#
# -------------------------------------------------------------------

sub _framework_template_post_process {
    my ($self, $template, $output_ref) = @_;

    if ( $self->conf->context->{'output_file_name_comment'} ) {
        my $fullfilepath = $template->filename;

        $$output_ref = "<!-- begin template file [[$fullfilepath]] -->"
                     . $$output_ref
                     . "<!-- end template file [[$fullfilepath]] -->";
    }
}

sub redirect {

    my $self = shift;
    my $location = shift;

    $self->header_add(-location => $location);
    $self->header_type('redirect');

    return "";
}


=head1 AUTHOR

The primary author of CGI::Application::Framework is Richard Dice,
C<< <rdice@pobox.com> >>, though Michael Graham is right up there,
too.  (Most of Michael's CAP::* modules created over the past few months
have been the result of refactoring code out of CAF and putting it online
in chunks small and modular enough to be used by other CGI::App programmers
and their applications.)

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-framework@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Code contributions and suggestions have some from the following people:

    * Michael Graham

        - above all, for looking after CAF circa Feb - Sept 2005 while
          Richard had his head deep deep up and into YAPC's assembly
          ('til June) and recovery (July - Sept) and the myriad
          technical improvements done throughout that time, such as...

        - support for multiple databases (e.g. PostgreSQL, SQLite)
        - support for multiple Template backends (e.g. Template::Toolkit,
          Petal)
        - the component embedding system
        - the config system via CGI::Application::Plugin::Config::Context
        - the run_app system
        - the test suite
        - documentation support
        - Log::Dispatch support
        - per-request database configuration under mod_perl
        - the Module::Build-based installer
        - extensive discussions of the system

    * Alex Spenser reorganized the example applications, made them xhtml
      compliant and added stylesheets and graphics.  He also helped
      develop the logo.

    * Many thanks to Jesse Erlbaum (CGI::Application creator and past
      maintainer) and Mark Stosberg (current CGI::Application maintainer
      and overseer, as well as CGI::Application::Plugin::ValidateRM
      author and Data::FormValidator maintainer)

    * Thanks to Cees Hek for CAP::Log::Dispatch, for ideas, and for
      discussions of the architecture.

    * Thanks also to Sam Tregar for HTML::Template

    * Thanks to the many users on the CGI::Application mailing list for
      feedback and support.

    * cgi-application-framework-support@dice-con.com

    * Rick Delaney (for making numerous suggestions regarding
      simplifications to the creation of templates within run-modes)
      and G. Matthew Rice (for this and lots more) at LPI...

    * Thanks to the LPI, the Linux Professional Institute (http://www.lpi.org/),
      for helping support the development of this project.  (But do not
      approach LPI for technical support, as they won't know how to
      help.  They are mentioned here because they are the fine sponsors
      of this project and users of this technology.)


=head1 COPYRIGHT & LICENSE

Copyright 2005 Richard Dice, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;  # bet you thought it'd never come...








