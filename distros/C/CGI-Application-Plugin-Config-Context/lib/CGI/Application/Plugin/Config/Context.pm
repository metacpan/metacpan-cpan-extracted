package CGI::Application::Plugin::Config::Context;

use warnings;
use strict;
require 5.006;

use base 'Exporter';
use CGI::Application;
use Config::Context;

use Carp;
use File::Spec;
use Scalar::Util qw(weaken isweak);
use Cwd;

use vars '@EXPORT';
@EXPORT = qw(conf);

our $CGIAPP_Namespace = '__CONFIG_CONTEXT';

=head1 NAME

CGI::Application::Plugin::Config::Context - Hierarchical, context-based configuration support for CGI::Application

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

=head2 Simple Access to Configuration

In your L<CGI::Application>-based module:

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;

    sub cgiapp_init {
        my $self = shift;

        # Set config file and other options
        $self->conf->init(
            file   => 'app.conf',
            driver => 'ConfigGeneral',
        );
    }

    sub my_run_mode {
        my $self = shift;

        # get entire configuration
        my %conf = $self->conf->context;

        # get entire configuration (as a reference)
        my $conf = $self->conf->context;

        # get single config parameter
        my $value = $self->conf->param('some_value');

        # get raw configuraion (pre-context-matching)
        my $raw_config = $self->conf->raw;
        my %raw_config = $self->conf->raw;
    }

=head2 Configuration Based on URL or Module

You can match a configuration section to the request URL, or to the
module name.  For instance, given the following configuration file:

    admin_area    = 0

    <AppMatch ^MyApp::Admin>
        admin_area = 1
        title      = Admin Area
    </AppMatch>

    <Location /cgi-bin/feedback.cgi>
        title      = Feedback Form
    </Location>

The configuration will depend on how the script is called:

    # URL:      /cgi-bin/feedback.cgi?rm=add
    # Module:   MyApp::Feedback

    print $self->conf->param('admin_area');  # 0
    print $self->conf->param('title');       # 'Feedback Form'

    # URL:      /cgi-bin/admin/users.cgi
    # Module:   MyApp::Admin::Users

    print $self->conf->param('admin_area');  # 1
    print $self->conf->param('title');       # 'Admin Area'


=head2 Matching Configuration based on a Virtual Host

This module can also pick a configuration section based on the current
virtual-host:

    # httpd.conf
    <VirtualHost _default_:8080>
        SetEnv SITE_NAME REDSITE
    </VirtualHost>

    # in app.conf
    <Site BLUESITE>
        background = blue
        foreground = white
    </Site>

    <Site REDSITE>
        background = red
        foreground = pink
    </Site>

    <Site GREENSITE>
        background = darkgreen
        foreground = lightgreen
    </Site>

=head2 Multiple configuration formats

Supports any configuration format supported by L<Config::Context>.  As
of this writing, that includes the following formats:

Apache-style syntax, via L<Config::General>:

    <AppMatch ^MyApp::Admin>
        admin_area = 1
        title      = Admin Area
    </AppMatch>

    <Location /cgi-bin/feedback.cgi>
        title      = Feedback Form
    </Location>

XML, via L<XML::Simple>:

    <AppMatch name="^MyApp::Admin">
        <admin_area>1</admin_area>
        <title>Admin Area</title>
    </AppMatch>

    <Location name="/cgi-bin/feedback.cgi">
        <title>Feedback Form</title>
    </Location>

L<Config::Scoped> syntax:

    AppMatch '^MyApp::Admin' {
        admin_area = 1
        title      = Admin Area
    }

    Location '/cgi-bin/feedback.cgi' {
        title      = Feedback Form
    }

Most of the examples in this document are in L<Config::General> syntax,
but can be translated into the other formats fairly easily.  For more
information, see the L<Config::Context> docs.

=head1 DESCRIPTION

This module allows you to easily access configuration data stored in
any of the formats supported by L<Config::Context>:  L<Config::General>
(Apache style), L<XML::Simple> and L<Config::Scoped>.

You can also automatically match configuration sections to the request
URL, or to the module name.  This is similar to how Apache dynamically
selects a configuration by matching the request URL to (for instance)
C<< <Location> >> and C<< <LocationMatch> >> sections.

You can also select configuration sections based on Virtual Host or by an
environment variable you set in an C<.htaccess> file.  This allows you
to share a configuration file and an application between many virtual
hosts, each with its own unique configuration.  This could be useful,
for instance, in providing multiple themes for a single application.

=head2 Simple access to Configuration

This module provides a C<conf> method to your L<CGI::Application>
object.  First, you initialize the configuration system (typically in
your C<cgiapp_init> method):

    $self->conf->init(
        file   => 'app.conf',
        driver => 'ConfigGeneral',
    );

The configuration file is parsed at this point and the configuration is
available from this moment on.

Then, within your run-modes you can retrieve configuration data:

    # get entire configuration
    my %conf = $self->conf->context;
    my $value = $conf{'some_value'};

    # get entire configuration (as a reference)
    my $conf = $self->conf->context;
    my $value = $conf->{'some_value'};

    # get single config parameter
    my $value = $self->conf->param('some_value');

The C<context> method provides the configuration based on the C<context>
of your application, i.e. after matching configuration sections based
on runtime data such as the current URL or package name.

But you can also access the raw configuration data from before the
matching took place:

    # get raw configuration
    my %conf = $self->conf->raw;

    # get raw configuration (as a reference)
    my $conf = $self->conf->raw;


=head2 Multiple named Configurations

You can use more than one configuration by providing a name to the
C<conf> method:

    $self->conf('database')->init(
        file   => 'db.conf',
        driver => 'ConfigGeneral',
    );
    $self->conf('application')->init(
        file   => 'app.conf',
        driver => 'ConfigScoped',
    );

    ...

    my %db_config  = $self->conf('database')->context;
    my %app_config = $self->conf('application')->context;

=head2 Configuration based on URL or Module

Within your configuration file, you can provide different configurations
depending on the current URL, or on the package name of your
application.

=over 4

=item <Site>

Matches against the C<SITE_NAME> environment variable, using an I<exact>
match.

    # httpd.conf
    <VirtualHost _default_:8080>
        SetEnv SITE_NAME REDSITE
    </VirtualHost>

    # in app.conf
    <Site BLUESITE>
        background = blue
        foreground = white
    </Site>

    <Site REDSITE>
        background = red
        foreground = pink
    </Site>

    <Site GREENSITE>
        background = darkgreen
        foreground = lightgreen
    </Site>

You can name your sections something other than C<< <Site> >>, and
you can use a different environment variable than C<SITE_NAME>.  See
L<Notes on Site Matching>, below.

=item <App>

Matches the Package name of your application module, for instance:

    <App ABC_Books::Admin>
        ...
    </App>

The match is performed hierarchically, like a filesystem path, except
using C<::> as a delimiter, instead of C</>.  The match is tied to the
beginning of the package name, just like absolute paths.  For instance,
given the section:

    <App Site::Admin>
        ...
    </App>

the packages C<Site::Admin> and C<Site::Admin::Users> would match, but
the packages C<My::Site::Admin> and C<Site::Administrative> would not.

=item <AppMatch>

Matches the package name of your application module, using a regular
expression.  The expression is not tied to the start of the string.  For
instance, given the section:

    <AppMatch Site::Admin>
        ...
    </AppMatch>

The following packages would all match: C<Site::Admin>, C<Site::Admin::Users>,
C<My::Site::Admin>, C<MySite::Admin>, C<Site::Administrative>.

=item <Location>

Matches hierarchically against the request URI, including the path and
the C<PATH_INFO> components, but I<excluding> the scheme, host, port and
query string.

So, for instance with the following URL:

    http://bookstore.example.com/cgi-bin/category.cgi/fiction/?rm=list

The Location would be:

    /cgi-bin/category.cgi/fiction/

Internally, the location is obtained by calling the C<url> method of the
query object (which is usually either a L<CGI> or L<CGI::Simple>
object):

    $path = $webapp->query->url('-absolute' => 1, '-path_info' => 1);

=item <LocationMatch>

Matches against the request URI, using a regular expression.

=back

=head2 Section Merge Order

The sections are matched in the following order:

    Site:         <Site>
    Package Name: <App>      and <AppMatch>
    URL:          <Location> and <LocationMatch>

When there is more than one matching section at the same level of
priority (e.g. two C<< <Location> >> sections, or both an C<< <App> >>
and an C<< <AppMatch> >> section), then the sections are merged in the
order of shortest match first.

Values in sections matched later override the values in sections matched
earlier.

The idea is that the longer matches are more specific and should have
priority, and that URIs are more specific than Module names.

=head2 Section Nesting

The sections can be nested inside each other.  For instance:

    <Site BOOKSHOP>
        <Location /admin>
            admin_books = 1
        </Location>
    </Site>

    <Location /admin>
        <Site RECORDSHOP>
            admin_records = 1
        </Site>
    </Location>

    <App Bookshop::>
        <App Admin::>
        </App>
    </App>


By default, the sections can be nested up to two levels deep.  This
alows for C<Location> sections within C<Site> sections and I<vice versa>.
You can change this by setting the L<nesting_depth> parameter to
L<init>.

B<Note:> there is limited support for this kind of nesting when using
L<Config::Scoped> format files.  See the documentation in
L<Config::Context::ConfigScoped> for details.

=head2 Merging Configuration Values into your Template

You can easily pass values from your configuration files directly to
your templates.  This allows you to associate HTML titles with URLs,
or keep text like copyright notices in your config file instead of your
templates:

    copyright_notice    =  Copyright (C) 1492 Christopher Columbus

    <Location /about>
        title = "Manifest Destiny, Inc. -  About Us"
    </Location>

    <Location /contact>
        title = "Manifest Destiny, Inc. - Contact Us"
    </Location>

If you use L<HTML::Template>, you use the associate method when you load
the template:

    $self->load_template(
        'template.tmpl',
        'associate' => $self->conf,
    );

If you use L<Template::Toolkit> (via the L<CGI::Application::Plugin::TT>
module), you can accomplish the same thing by providing a custom
tt_pre_process method:

    sub tt_pre_process {
        my $self            = shift;
        my $template        = shift;
        my $template_params = shift;

        my $config = $self->conf->context
        foreach (keys %$config) {
            unless (exists $template_params->{$_}) {
                $template_params->{$_} = $config->{$_};
            }
        }
    }


I<NOTE: If you plan to merge data directly from your config files to your>
I<templates, you should consider keeping your database passwords and other>
I<sensitive data in a separate configuration file, in order to avoid>
I<accidentally leaking these data into your web pages.>


=head1 METHODS

=cut

# The 'conf' method is the only sub exported into the cgiapp namespace all
# other methods are called through the object returned by this method.
#
# 'conf' checks to see if an object of the requested name (or the default,
# unnamed object) already exists in the webapp object.
#
# If it exists it returns a reference to it
#
# If it doesn't exist, it creates it and returns a reference to it
#
#
# Note that at the moment, subclasses of this plugin are probably not
# possible because of the call to __PACKAGE__->new.


sub conf {
    my ($self, $conf_name) = @_;

    if (defined $conf_name) {
        # Named config
        if (not exists $self->{$CGIAPP_Namespace}->{'__NAMED_CONFIGS'}->{$conf_name}) {
            $self->{$CGIAPP_Namespace}->{'__NAMED_CONFIGS'}->{$conf_name} = __PACKAGE__->_new($self, $conf_name);

        }
        return $self->{$CGIAPP_Namespace}->{'__NAMED_CONFIGS'}->{$conf_name};
    }
    else {
        # Default config
        if (not exists $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'}) {
            $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'} = __PACKAGE__->_new($self);
        }
        return $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'};
    }
}

sub _new {
    my ($proto, $webapp, $conf_name) = @_;

    my $class = ref $proto || $proto;

    my $package = ref $webapp;

    my $self = {
        '__CONFIG_NAME'     => $conf_name,
        '__CALLERS_PACKAGE' => $package,
        '__CGIAPP_OBJ'      => $webapp,
        '__CONFIG'          => undef,
        '__RAW_CONFIG'      => undef,
        '__CONFIG_OBJ'      => undef,
    };

    # Force reference to CGI::Application object to be weak to avoid
    # circular references
    weaken($self->{'__CGIAPP_OBJ'});

    return bless $self, $class;
}

=head2 init

Initializes the plugin.  The only required parameter is the source of
the configuration, either C<file>, C<string> or C<hash>.

    $self->conf->init(
        file => 'app.conf',
    );

The other paramters are described below:

=over 4

=item file

The path to the configuration file to be parsed.

=item string

A string containing configuration data to be parsed.

=item hash

A Perl data structure containing containing the pre-parsed config data.

=item driver

Which L<Config::Context> driver should parse the config.  Currently
supported drivers are:

    driver            module name
    ------            -----------
    ConfigGeneral     Config::Context::ConfigGeneral
    ConfigScoped      Config::Context::ConfigScoped
    XMLSimple         Config::Context::XMLSimple

The default driver is C<ConfigGeneral>.

=item driver_options

Options to pass directly on to the driver.  This is a multi-level hash,
where the top level keys are the driver names:

    my $conf = Config::Context->new(
        driver => 'ConfigScoped',
        driver_options => {
           ConfigGeneral => {
               -AutoLaunder => 1,
           },
           ConfigScoped = > {
               warnings => {
                   permissions  => 'off',
               }
           },
        },
    );

In this example the options under C<ConfigScoped> will be passed to the
C<ConfigScoped> driver.  (The options under C<ConfigGeneral> will be
ignored because C<driver> is not set to C<'ConfigGeneral'>.)

=item cache_config_files

Whether or not to cache configuration files.  Enabled, by default.
This option is useful in a persistent environment such as C<mod_perl>.
See L<Config File Caching> under L<ADVANCED USAGE>, below.

=item stat_config

If config file caching is enabled, this option controls how often the
config files are checked to see if they have changed.  The default is 60
seconds.  This option is useful in a persistent environment such as
C<mod_perl>.  See L<Config File Caching> under C<ADVANCED USAGE>, below.

=item site_section_name

Change the name of the C<< <Site> >> section to something else.  For
instance, to use sections named C<< <VirtualHost> >>, use:

    site_section_name => 'VirtualHost'

=item site_var

Change the name of the C<SITE_NAME> environment variable used to match
against C<< <Site> >> sections.  For instance To change this name to
C<HTTP_HOST>, use:

    site_var => 'HTTP_HOST',

=item nesting_depth

The number of levels deep that sections can be nested.  The default is
two levels deep.

See L<Section Nesting>, above.

=back

You can initialize the plugin from within your instance CGI script:

    my $app = WebApp->new();
    $app->conf->init(file        => '../../config/app.conf');
    $app->run();

Or you can do so from within your C<cgiapp_init> method within the
application:

    sub cgiapp_init {
        my $self = shift;
        $self->conf->init(
            file => "$ENV{DOCUMENT_ROOT}/../config/app.conf"
        );
    }


=cut

sub init {
    my $self = shift;

    my %args = @_;

    my $config             = delete $args{'config'};
    my $file               = delete $args{'file'};
    my $string             = delete $args{'string'};

    if (!$config && !$file && !$string) {
        croak "CAP::CC->init: one of 'file', 'string' or 'config' is required";
    }

    my $match_sections     = exists $args{'match_sections'}     ? delete $args{'match_sections'}      : [];
    my $driver_options     = exists $args{'driver_options'}     ? delete $args{'driver_options'}      : {};
    my $cache_config_files = exists $args{'cache_config_files'} ? delete $args{'cache_config_files'}  : 1;
    my $stat_config        = exists $args{'stat_config'}        ? delete $args{'stat_config'}         : 60;
    my $nesting_depth      = exists $args{'nesting_depth'}      ? delete $args{'nesting_depth'}       : 2;
    my $lower_case_names   = exists $args{'lower_case_names'}   ? delete $args{'lower_case_names'}    : 0;

    my $site_var           = exists $args{'site_var'}           ? delete $args{'site_var'}            : 'SITE_NAME';
    my $site_section_name  = exists $args{'site_section_name'}  ? delete $args{'site_section_name'}   : 'Site';


    my $driver             = delete $args{'driver'} || 'ConfigGeneral';


    if (keys %args) {
        croak "CAP::CC: unrecognized args to init: " .(join ', ', keys %args). "\n";
    }

    unless (@$match_sections) {
        $match_sections = $self->_default_matchsections(
            $site_section_name
        );
    }

    my $cgiapp = $self->{'__CGIAPP_OBJ'};

    my $cc_obj = Config::Context->new(
        'config'             => $config,
        'file'               => $file,
        'string'             => $string,

        'driver'             => $driver,

        'lower_case_names'   => $lower_case_names,

        'match_sections'     => $match_sections,
        'driver_options'     => $driver_options,
        'cache_config_files' => $cache_config_files,

        'stat_config'        => $stat_config,
        'nesting_depth'      => $nesting_depth,

    );

    $self->{'__CONFIG_OBJ'} = $cc_obj;
    $self->{'__RAW_CONFIG'} = $cc_obj->raw;

    $self->{'__CONFIG'}     = $cc_obj->context(
        'env'    => $ENV{$site_var},
        'module' => $self->{'__CALLERS_PACKAGE'},
        'path'   => $cgiapp->query->url('-absolute' => 1,'-path_info' => 1),
    );

    $self->_set_current_config( $self->{'__CONFIG_NAME'}, $self->{'__CONFIG'}, $self->{'__RAW_CONFIG'} );
    return $self;
}

=head2 context

Gets the entire configuration as a hash or hashref:

    my %config = $self->conf->context;  # as hash
    my $config = $self->conf->context;  # as hashref


=cut

sub context {
    my $self = shift;
    return %{ $self->{'__CONFIG'} } if wantarray;
    return $self->{'__CONFIG'};
}


=head2 raw

Gets the raw configuration as a hash or hashref:

    my %raw_config = $self->conf->raw;  # as hash
    my $raw_config = $self->conf->raw;  # as hashref

The raw configuration is the configuration before matching
has taken place.  It includes all the raw config with all of the
C<< <Location> >>, C<< <App> >>, etc. sections intact.

=cut

sub raw{
    my $self = shift;
    return %{ $self->{'__RAW_CONFIG'} } if wantarray;
    return $self->{'__RAW_CONFIG'};
}

=head2 param

Allows you to retrieve individual values from the configuration.

It behvaves like the C<param> method in other classes, such as L<CGI>,
L<CGI::Application> and L<HTML::Template>:

    $value      = $self->conf->param('some_key');
    @all_keys   = $self->conf->param();

=cut

sub param {
    my $self   = shift;
    my $config = $self->{'__CONFIG'};

    if (@_) {
        return $config->{$_[0]};
    }
    else {
        return keys %$config;
    }
}

=head2 get_current_context ($name)

This is a class method which returns the current configuration object.

    my $conf = CGI::Application::Plugin::Config::Context->get_current_context;
    print $conf->{'title'};

    my %db_conf = CGI::Application::Plugin::Config::Context->get_current_context('db');
    print $db_conf{'username'};

This method is most useful in situations where you don't have access to
the L<CGI::Application> object, such within a L<Class::DBI> class.  See
L<Access to Configuration information from another Class> for an example.

=head2 get_current_raw_config ($name)

Same as get_current_context, but returns the raw configuration.

=cut

# Sets the "current config" for a given name
# _set_current_config($name, \%config);

our $Default_Current_Context_Config;
our $Default_Current_Raw_Config;
our %Current_Context_Config;
our %Current_Raw_Config;

sub _set_current_config {
    my ($class, $name, $context_config, $raw_config) = @_;

    if (defined $name) {
        $Current_Context_Config{$name} = $context_config;
        $Current_Raw_Config{$name}     = $raw_config;
    }
    else {
        $Default_Current_Context_Config = $context_config;
        $Default_Current_Raw_Config     = $raw_config;
    }
}

sub get_current_context {
    my ($class, $name) = @_;

    my $config = {};

    if (defined $name) {
        if (exists $Current_Context_Config{$name}) {
            $config = $Current_Context_Config{$name};
        }
        else {
            croak "CAP::CC: requested config named '$name' does not exist\n";
        }
    }
    else {
        $config = $Default_Current_Context_Config;
    }

    return %$config if wantarray;
    return $config;
}

sub get_current_raw_config {
    my ($class, $name) = @_;

    my $config = {};

    if (defined $name) {
        if (exists $Current_Raw_Config{$name}) {
            $config = $Current_Raw_Config{$name};
        }
        else {
            croak "CAP::CC: requested config named '$name' does not exist\n";
        }
    }
    else {
        $config = $Default_Current_Raw_Config;
    }

    return %$config if wantarray;
    return $config;
}

=head1 ADVANCED USAGE

=head2 Usage in a Persistent Environment such as mod_perl

The following sections describe some notes about running this module
under mod_perl:

=head3 Config File Caching

L<Config::Context> caches configuration files by default.

Each config file is read only once when the conf object is first
initialized.  Thereafter, on each init, the cached config is used.

This means that in a persistent environment like mod_perl, the config
file is parsed on the first request, but not on subsequent requests.

If enough time has passed (sixty seconds by default) the config file is
checked to see if it has changed.  If it has changed, then the file is
reread.

See the docs for L<Config::Context> for details.

=head2 Notes on Site Matching

=head3 Renaming C<< <Site> >> or C<SITE_NAME>

Normally, the environment variable C<SITE_NAME> is matched to
C<< <Site> >> section.

You can change these with the L<site_section_name> and L<site_var>
parameters to L<init>:

    $self->conf->init(
        file              => 'app.conf',
        site_section_name => 'Host',
        site_var          => 'MY_HOST',
    );

This will match the environment variable C<MY_HOST> to the C<< <Host> >>
section.

=head3 Setting C<SITE_NAME> from an C<.htaccess> file or the CGI script

Since C<SITE_NAME> is just an environment variable, you can set it
anywhere you can set environment variables.  For instance in an C<.htaccess> file:

    # .htaccess
    SetEnv SITE_NAME bookshop

Or even the calling CGI script:

    #!/usr/bin/perl

    use MySite::WebApp;

    $ENV{'SITE_NAME'} = 'recordshop';
    my $app = MySite::WebApp->new();
    $app->run();


=head2 Access to Configuration information from another Class

You can also get at the current configuration settings from a completely
unrelated Perl module.  This can be useful for instance if you need to
configure a set of L<Class::DBI> classes, and you want them to be able
to pick up their configuration on their own.  For instance:

    # app.conf

    <database>
        connect_string = dbi:Pg:dbname=example
        username       = test
        password       = test

        <options>
            RaiseError = 1
            AutoCommit = 1
        </options>
    </database>


    # In your Class::DBI subclass
    package My::Class::DBI::Base;
    use base 'Class::DBI';

    sub db_Main {

        my $conf = CGI::Application::Plugin::Config::Context->get_current_context;

        my $dsn  = $conf->{'database'}{'connect_string'};
        my $user = $conf->{'database'}{'username'};
        my $pass = $conf->{'database'}{'password'};
        my $opts = $conf->{'database'}{'options'};

        return DBI->connect_cached($dsn, $user, $pass, $opts);
    }

For this example to work, you need to make sure you call
C<< $self->conf->init >> before you access the database through any of your
L<Class::DBI> objects.

You can also call L<get_current_raw_config> to get access to the raw
configuration.

=head2 Changing Parsing Behaviour Using Custom L<match_sections>

Internally, this module uses L<Config::Context> to parse its config
files.  If you want to change the parsing behaviour, you can pass your
own L<match_sections> list to L<init>.  For instance, if you want to
allow only sections named C<< <URL> >>, with no nesting, and have these
matched exactly to the complete request path, you could do the
following:

    # app.conf

    admin_area = 0
    user_area  = 0

    <URL /cgi-bin/admin.cgi>
        admin_area = 1
    </URL>

    <URL /cgi-bin/user.cgi>
        user_area = 1
    </URL>


    # in your cgiapp_init:
    $self->conf->init(
        file           => 'app.conf',
        nesting_depth  => 1,
        match_sections => [
            {
                name           => 'URL',
                match_type     => 'exact',
                merge_priority => 0,
                section_type   => 'path',
            },
        ]
    );


For reference, here is the default L<match_sections>:

    [
        {
            name                => 'Site', # overridden by 'site_section_name'
            match_type          => 'exact',
            merge_priority      => 0,
            section_type        => 'env',
        },
        {
            name                => 'AppMatch',
            match_type          => 'regex',
            section_type        => 'module',
            merge_priority      => 1,
        },
        {
            name                => 'App',
            match_type          => 'path',
            path_separator      => '::',
            section_type        => 'module',
            merge_priority      => 1,
        },
        {
            name                => 'LocationMatch',
            match_type          => 'regex',
            section_type        => 'path',
            merge_priority      => 3,
        },
        {
            name                => 'Location',
            match_type          => 'path',
            section_type        => 'path',
            merge_priority      => 3,
        },
    ],

=cut

sub _default_matchsections {
    my $self          = shift;
    my $site_var_name = shift;

    return [
        {
            name                => $site_var_name,
            match_type          => 'exact',
            merge_priority      => 0,
            section_type        => 'env',
        },
        {
            name                => 'AppMatch',
            match_type          => 'regex',
            section_type        => 'module',
            merge_priority      => 1,
        },
        {
            name                => 'App',
            match_type          => 'path',
            path_separator      => '::',
            section_type        => 'module',
            merge_priority      => 1,
        },
        {
            name                => 'LocationMatch',
            match_type          => 'regex',
            section_type        => 'path',
            merge_priority      => 3,
        },
        {
            name                => 'Location',
            match_type          => 'path',
            section_type        => 'path',
            merge_priority      => 3,
        },
    ],

}



=pod

For each section, the L<section_type> param indicates what runtime
variable the section will be matched against.  Here are the allowed values

    env:     matched to the environment variable SITE_NAME (overridden by site_name_var)
    module:  name of the Perl Module handling this request (e.g. MyApp::Users)
    path:    path of the request, including path_info (e.g. /cgi-bin/myapp/users.cgi/some/path)

You can use the above L<section_type> values in your own custom
L<match_sections>.

For more information on the syntax of L<match_sections>, see the docs
for L<Config::Context>.

=head2 Importing the 'conf' method, but using a different name.

If you want to access the features of this module using a method other
than C<conf>, you can do so via Anno Siegel's L<Exporter::Renaming>
module (available on CPAN).

    use Exporter::Renaming;
    use CGI::Application::Plugin::Config::Context Renaming => [ conf => custom_config_method];

    sub cgiapp_init {
        my $self = shift;

        # Set config file and other options
        $self->custom_config_method->init(
            file   => 'app.conf',
            driver => 'ConfigGeneral',
        );

        my $config = $self->custom_config_method->context;

        # ....

    }

=head1 AUTHOR

Michael Graham, C<< <mag-perl@occamstoothbrush.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-config-general@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to the excellent examples provided by the other
L<CGI::Application> plugin authors:  Mark Stosberg, Michael Peters, Cees
Hek and others.

=head1 SEE ALSO

    CGI::Application
    Config::Context
    Config::Context::ConfigGeneral
    Config::Context::ConfigScoped
    Config::Context::XMLSimple
    CGI::Application::Plugin::Config::Simple
    CGI::Application::Plugin::ConfigAuto

    Exporter::Renaming

    CGI::Application::Plugin::TT
    Template::Toolkit
    HTML::Template

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;