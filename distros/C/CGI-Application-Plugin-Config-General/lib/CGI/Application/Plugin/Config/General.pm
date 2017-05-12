
package CGI::Application::Plugin::Config::General;

use warnings;
use strict;
require 5.006;

use base 'Exporter';
use CGI::Application;
use Config::General::Match;

use Carp;
use File::Spec;
use Scalar::Util qw(weaken isweak);
use Cwd;

use vars '@EXPORT';
@EXPORT = qw(conf);

our $CGIAPP_Namespace = '__CONFIG_GENERAL';

=head1 NAME

CGI::Application::Plugin::Config::General - Add Config::General Support to CGI::Application

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 NOTE

This module is obsolete and has now been superceded by
L<CGI::Application::Plugin::Config::Context>.

=head1 SYNOPSIS

=head2 Simple Access to Configuration

In your L<CGI::Application>-based module:

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::General;

    sub cgiapp_init {
        my $self = shift;

        # Set config file and other options
        $self->conf->init(
            -ConfigFile => 'app.conf',
        );
    }

    sub my_run_mode {
        my $self = shift;

        # get entire configuration
        my %conf = $self->conf->getall;

        # get entire configuration (as a reference)
        my $conf = $self->conf->getall;

        # get single config parameter
        my $value = $self->conf->param('some_value');

        # get underlying Config::General::Match object
        my $obj = $self->conf->obj;
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

=head1 DESCRIPTION

This module allows you to easily access configuration data stored in
L<Config::General> (i.e. Apache-style) config files.

You can also automatically match configuration sections to the request
URL, or to the module name.  This is similar to how Apache dynamically
selects a configuration by matching the request URL to e.g.
C<< <Location> >> and C<< <LocationMatch> >> sections.

You can also select configuration sections based on Virtual Host or by a
variable you set in an C<.htaccess> file.  This allows you to share a
single application between many virtual hosts, each with its own
unique configuration.  This could be useful, for instance, in providing
multiple themes for a single application.

=head2 Simple access to Configuration

This module provides a C<conf> method to your L<CGI::Application>
object.  First, you initialize the configuration system (typically in
your C<cgiapp_init> method):

    $self->conf->init(
        -ConfigFile => 'app.conf',
    );

The configuration file is parsed at this point and is available from
this point on.

Then, within your run-modes you can retrieve configuration data:

    # get entire configuration
    my %conf = $self->conf->getall;
    my $value = $conf{'some_value'};

    # get entire configuration (as a reference)
    my $conf = $self->conf->getall;
    my $value = $conf->{'some_value'};

    # get single config parameter
    my $value = $self->conf->param('some_value');

=head2 Multiple named Configurations

You can use more than one configuration by providing a name to the
C<conf> method:

    $self->conf('database')->init(
        -ConfigFile => 'app.conf',
    );
    $self->conf('application')->init(
        -ConfigFile => 'app.conf',
    );

    ...

    my %db_config  = $self->conf('database')->getall;
    my %app_config = $self->conf('application')->getall;

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

You can use name your sections something other than C<< <Site> >>, and
you can use a different environment variable than C<SITE_NAME>.  See
L<Notes on Site Matching>, below.

=item <App>

Matches the Package name of your application module, for instance:

    <App ABC_Books::Admin>
        ...
    </App>

The match is performed hierachically, like a filesystem path, except
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


By default, the sections can be nested up to two levels deep.  You can
change this by setting the L<-NestingDepth> parameter to L<init>.

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

        my $config = $self->conf->getall
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
            if ($self->can('add_callback')) {
                $self->add_callback('teardown', \&_clear_all_current_configs, 'LAST');
            }

        }
        return $self->{$CGIAPP_Namespace}->{'__NAMED_CONFIGS'}->{$conf_name};
    }
    else {
        # Default config
        if (not exists $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'}) {
            $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'} = __PACKAGE__->_new($self);
            if ($self->can('add_callback')) {
                $self->add_callback('teardown', \&_clear_all_current_configs, 'LAST');
            }
        }
        return $self->{$CGIAPP_Namespace}->{'__DEFAULT_CONFIG'};
    }
}

sub _new {
    my ($proto, $webapp, $conf_name) = @_;

    my $class = ref $proto || $proto;

    my ($package) = ref $webapp;

    my $self = {
        '__CONFIG_NAME'        => $conf_name,
        '__CALLERS_PACKAGE'    => $package,
        '__CGIAPP_OBJ'         => $webapp,
        '__CONFIG'             => undef,
        '__CONFIG_OBJ'         => undef,
        '__CONFIG_OBJ_CREATED' => undef,
        '__CONFIG'             => undef,
    };

    # Force reference to CGI::Applcation object to be weak to avoid
    # circular references
    weaken($self->{'__CGIAPP_OBJ'});

    return bless $self, $class;
}

=head2 init

Initializes the plugin.  The only required parameter is a config file:

    $self->conf->init(
        -ConfigFile => 'app.conf',
    );

The other paramters are described below:

=over 4

=item -ConfigFile

The path to the configuration file to be parsed.

=item -Options

Any additional L<Config::General::Match> options.  See the documentation
to L<Config::General> and L<Config::General::Match> for more details.

=item -CacheConfigFiles

Whether or not to cache configuration files.  Enabled, by default.
This option is only really useful in a persistent environment such as
C<mod_perl>.  See L<Config File Caching> under L<ADVANCED USAGE>,
below.

=item -StatConfig

If config file caching is enabled, this option controls how often the
config files are checked to see if they have changed.  The default is 60
seconds.  This option is only really useful in a persistent environment
such as C<mod_perl>.  See L<Config File Caching> under
C<ADVANCED USAGE>, below.

=item -SiteSectionName

Change the name of the C<< <Site> >> section to something else.  For
instance, to use sections named C<< <VirtualHost> >>, use:

    -SiteSectionName => 'VirtualHost'

=item -SiteVar

Change the name of the C<SITE_NAME> environment variable used to match
against C<< <Site> >> sections.  For instance To change this name to
C<HTTP_HOST>, use:

    -SiteVar => 'HTTP_HOST',

=item -NestingDepth

The number of levels deep that sections can be nested.  The default is
two levels deep.

See L<Section Nesting>, above.

=back

You can initialize the plugin from within your instance CGI script:

    my $app = WebApp->new();
    $app->conf->init(-ConfigFile => '../../config/app.conf');
    $app->run();

Or you can do so from within your C<cgiapp_init> method within the
application:

    sub cgiapp_init {
        my $self = shift;
        $self->conf->init(
            -ConfigFile => "$ENV{DOCUMENT_ROOT}/../config/app.conf"
        );
    }


=cut

sub init {
    my $self = shift;

    my %args = @_;
    my $config_file = delete $args{'-ConfigFile'} or croak "CAP::CG->init: -ConfigFile is a required parameter\n";

    my $cache_config_files = exists $args{'-CacheConfigFiles'} ? delete $args{'-CacheConfigFiles'} : 1;
    my $stat_config        = exists $args{'-StatConfig'}       ? delete $args{'-StatConfig'}       : 60;
    my $options            = exists $args{'-Options'}          ? delete $args{'-Options'}          : {};
    my $site_var           = exists $args{'-SiteVar'}          ? delete $args{'-SiteVar'}          : 'SITE_NAME';
    my $site_section_name  = exists $args{'-SiteSectionName'}  ? delete $args{'-SiteSectionName'}  : 'Site';
    my $nesting_depth      = exists $args{'-NestingDepth'}     ? delete $args{'-NestingDepth'}     : 2;

    if (keys %args) {
        croak "CAP::CG: unrecognized args to init: " .(join ', ', keys %args). "\n";
    }

    my $cg_obj;

    # If file caching is enabled then attempt to retrieve the
    # Config::General object from the cache

    if ($cache_config_files) {
        if ($self->_cgm_cache_check_valid($config_file, $stat_config)) {

            # we don't need to reread the files
            $cg_obj = $self->_cgm_cache_retrieve($config_file);

        }
    }

    # Build the C::G::M object if we haven't retrieved it from the cache
    if (!$cg_obj) {
        # print STDERR "$self->{'__CALLERS_PACKAGE'} did not retrieve from cache\n";

        # Add -MatchSections if not provided
        unless ($options->{'-MatchSections'}) {

            # Override 'Site' with -SiteSectionName if desired
            $options->{'-MatchSections'} = $self->_default_matchsections(
                $site_section_name
            );
        }

        $options->{'-ConfigFile'} = $config_file;

        $cg_obj = Config::General::Match->new(%$options);

        $self->{'__CONFIG_OBJ_CREATED'} = time;

        # If file caching is enabled then store the object in the cache
        if ($cache_config_files) {

            my @config_files = ($config_file);

            $self->_cgm_cache_store($config_file, $cg_obj, $self->{'__CONFIG_OBJ_CREATED'});
        }
    }

    $self->{'__CONFIG_OBJ'} = $cg_obj;

    my $cgiapp  = $self->{'__CGIAPP_OBJ'};

    my $config = $cg_obj->getall_matching_nested(
        $nesting_depth,
        'env'     => $self->_get_server_var($site_var),
        'module'  => $self->{'__CALLERS_PACKAGE'},
        'path'    => $cgiapp->query->url('-absolute' => 1, '-path_info' => 1),
    );

    $self->{'__CONFIG'} = $config;

    $self->_set_current_config($self->{'__CONFIG_NAME'}, $config);

}

our %CGM_Cache;

# Cache format:
# %CGM_Cache = (
#     $absolute_filename1 => {
#         __OBJ           => $cg_obj,
#         __CREATION_TIME => $creation_time,   # time object was constructed
#
#         __FILES         => [                 # array of fileinfo hashrefs,
#                                              # one per config file included
#                                              # by the primary config file
#             {
#                 __FILENAME  => $filename1,   # name of file
#                 __MTIME     => $mtime1,      # last modified time, in epoch seconds
#                 __SIZE      => $size1,       # size, in bytes
#                 __LASTCHECK => $time1,       # last time we checked this file, in epoch seconds
#             },
#             {
#                 __FILENAME  => $filename2,
#                 __MTIME     => $mtime2,
#                 __SIZE      => $size2,
#                 __LASTCHECK => $time2,
#             },
#         ]
#     }


# _cgm_cache_retrieve($filename)       # returns object
sub _cgm_cache_retrieve {
    my ($self, $config_file) = @_;

    my $abs_path = Cwd::abs_path($config_file);

    return $CGM_Cache{$abs_path}->{'__OBJ'};
}


# _cgm_cache_store($filename, $cg_obj, $creation_time) # stores object
sub _cgm_cache_store {
    my ($self, $config_file, $cg_obj, $creation_time) = @_;

    my @config_files = ($config_file);
    my $abs_path = Cwd::abs_path($config_file);

    # Config::General 2.28 and higher can give a list of files it has read,
    # including included files
    if ($cg_obj->can('files')) {
        @config_files = $cg_obj->files;
    }

    my @filedata;

    foreach my $config_file (@config_files) {
        my $time = time;
        my ($size, $mtime) = (stat $config_file)[7,9];
        my %fileinfo = (
            '__FILENAME'  => $config_file,
            '__LASTCHECK' => $time,
            '__MTIME'     => $mtime,
            '__SIZE'      => $size,
        );
        push @filedata, \%fileinfo;
    }

    $CGM_Cache{$abs_path} = {
        '__OBJ'           => $cg_obj,
        '__CREATION_TIME' => $creation_time,
        '__FILES'         => \@filedata,
    };
}

# _cgm_cache_check_valid($config_file, $cg_obj, $stat_config)
#  - returns true if all config files associated with this file
#    are still valid.
#  - returns false if any of the configuration files have changed
#
# if a file was checked less than stat_seconds ago, then it is not even
# checked, but assumed to be valid.
# Otherwise it is checked again.  If its mtime or size have changed
# then it is assumed to be invalid.
#
# if any file has changed then the configuration is determined to
# be invalid

sub _cgm_cache_check_valid {
    my ($self, $config_file, $stat_config) = @_;

    my @config_files = ($config_file);
    my $abs_path = Cwd::abs_path($config_file);

    return unless exists $CGM_Cache{$abs_path};
    return unless ref    $CGM_Cache{$abs_path}{'__FILES'} eq 'ARRAY';

    foreach my $fileinfo (@{ $CGM_Cache{$abs_path}{'__FILES'} }) {
        my $time = time;

        # Don't stat the file unless our last check was more recent than
        # $stat_config seconds ago

        next if ($fileinfo->{'__MTIME'} + $stat_config >= $time);

        my ($size, $mtime) = (stat $config_file)[7,9];

        # return false if any differences
        return if $size  != $fileinfo->{'__SIZE'};
        return if $mtime != $fileinfo->{'__MTIME'};

        # no change, so save the new stat info in the cache
        $fileinfo->{'__SIZE'}      = $size;
        $fileinfo->{'__MTIME'}     = $mtime;
        $fileinfo->{'__LASTCHECK'} = $time;

    }
    return 1;
}

# _get_apache_var($varname)
#  - retrieve the variable $varname from dirconfig or from %ENV

sub _get_server_var {
    my ($self, $varname) = @_;

    my $value;
    if ($ENV{'MOD_PERL'}) {
        require Apache;
        $value = Apache->request->dir_config($varname);
    }
    if (!$value) {
        $value = $ENV{$varname};
    }
    return $value;
}

=head2 getall

Gets the entire configuration as a hash or hashref:

    my %config = $self->conf->getall;  # as hash
    my $config = $self->conf->getall;  # as hashref

Note that the following two method calls will return different results:

    my %config = $self->conf->getall;       # parsed config
    my %config = $self->conf->obj->getall;  # raw config

In the first case, the matching based on URI, Module, etc. has already
been performed.  In the second case, you get the raw config with all of
the C<< <Location> >>, C<< <App> >>, etc. sections intact.

=cut

sub getall {
    my $self = shift;
    return %{ $self->{'__CONFIG'} } if wantarray;
    return $self->{'__CONFIG'};
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

=head2 obj

Provides access to the underlying L<Config::General::Match> object.

You can access the raw unparsed configuration data by calling

    my $config = $self->conf->obj->getall;  # raw config

See the note under L<getall>, above.

In future versions of this module, certain caching strategies may
prevent you from accessing the underlying L<Config::General::Match>
object in certain situations.

=cut

sub obj {
    my $self = shift;
    return $self->{'__CONFIG_OBJ'};
}

=head2 get_current_config ($name)

This is a class method which returns the current configuration object.

    my $conf = CGI::Application::Plugin::Config::General->get_current_config;
    print $conf->{'title'};

    my %db_conf = CGI::Application::Plugin::Config::General->get_current_config('db');
    print $db_conf{'username'};

This method is most useful in situations where you don't have access to
the L<CGI::Application> object, such within a L<Class::DBI> class.  See
L<Access to Configuration information from another Class> for an example.

Note that L<get_current_config> returns the configuration hash (or
hashref) directly, and does not give you access to the object itself.
It is the equivalent of calling C<< $self->conf->getall >>.

=cut

# Sets the "current config" for a given name
# _set_current_config($name, \%config);

our $Default_Current_Config;
our %Current_Config;

sub _set_current_config {
    my ($class, $name, $config) = @_;

    if (defined $name) {
        $Current_Config{$name} = $config;
    }
    else {
        $Default_Current_Config = $config;
    }
}

# Clears all "current configs"
# _clear_all_current_configs();
sub _clear_all_current_configs {
    %Current_Config = ();
    $Default_Current_Config = {};
}

sub get_current_config {
    my ($class, $name) = @_;

    my $config = {};

    if (defined $name) {
        if (exists $Current_Config{$name}) {
            $config = $Current_Config{$name};
        }
        else {
            croak "CAP::CG: requested config named '$name' does not exist\n";
        }
    }
    else {
        $config = $Default_Current_Config;
    }

    return %$config if wantarray;
    return $config;
}

=head1 ADVANCED USAGE

=head2 Usage in a Persistent Environment such as mod_perl

The following sections describe some notes about running this module
under mod_perl:

=head3 Config File Caching

By default each config file is read only once when the conf object is
first initialized.  Thereafter, on each init, the cached config is used.

This means that in a persistent environment like mod_perl, the config
file is parsed on the first request, but not on subsequent requests.

If enough time has passed (sixty seconds by default) the config file is
checked to see if it has changed.  If it has changed, then the file is
reread.

If you are using L<Config::General> version 2.28 or greater, then you
can safely use the C<include> feature of L<Config::General> and all
included files will be checked for changes along with the main file.

To disable caching of config files pass a false value to the
L<-CacheConfigFiles> parameter to L<init>, e.g:

    $self->conf->init(
        -ConfigFile           => 'app.conf',
        -CacheConfigFiles     => 0,
    );

To change how often config files are checked for changes, change the
value of the L<-StatConfig> paramter to L<init>, e.g.:

    $self->conf->init(
        -ConfigFile => 'app.conf',
        -StatConfig => 1, # check the config file every second
    );


Internally the configuration cache is implemented by a hash, keyed by
the absolute path of the configuration file.  This means that if you have
two web applications that use the same configuration file, they will use
the same cache.

This would only matter if you wanted to use different C<Config::General>
or C<Config::General::Match> options for different applications running
in the same process that use the same config file.


=head3 PerlSetVar instead of SetEnv

For a (slight) performance improvement, you can use C<PerlSetVar>
instead of C<SetEnv> within a C<< <VirtualHost> >>:

    # httpd.conf
    <VirtualHost _default_:8080>
        PerlSetVar SITE_NAME REDSITE
    </VirtualHost>

=head2 Notes on Site Matching

=head3 Renaming C<< <Site> >> or C<SITE_NAME>

Normally, the environment variable C<SITE_NAME> is matched to
C<< <Site> >> section.

You can change these with the L<-SiteSectionName> and L<-SiteVar>
parameters to L<init>:

    $self->conf->init(
        -ConfigFile           => 'app.conf',
        -SiteSectionName      => 'Host',
        -SiteVar              => 'MY_HOST',
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

        my $conf = CGI::Application::Plugin::Config::General->get_current_config;

        my $dsn  = $conf->{'database'}{'connect_string'};
        my $user = $conf->{'database'}{'username'};
        my $pass = $conf->{'database'}{'password'};
        my $opts = $conf->{'database'}{'options'};

        return DBI->connect_cached($dsn, $user, $pass, $opts);
    }

For this example to work, you need to make sure you call
C<< $self->conf->init >> before you access the database through any of your
L<Class::DBI> objects.

Note that L<get_current_config> returns the configuration hash (or
hashref) directly, and does not give you access to the object itself.
It is the equivalent of calling C<< $self->conf->getall >>.

=head2 Changing Parsing Behaviour Using Custom L<-MatchSections>

Internally, this module uses L<Config::General> and
L<Config::General::Match> to parse its config files.  If you want to
change the parsing behaviour, you can pass your own L<-MatchSections>
list to L<init>.  For instance, if you want to allow only sections named
C<< <URL> >>, with no nesting, and have these matched exactly to the
complete request path, you could do the following:

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
        -ConfigFile        => 'app.conf',
        -NestingDepth      => 1,
        -Options           => {
            -MatchSections => [
                {
                    -Name          => 'URL',
                    -MatchType     => 'exact',
                    -MergePriority => 0,
                    -SectionType   => 'path',
                },
            ]
        }
    );


For reference, here is the default L<-MatchSections>:

    -MatchSections => [
        {
            -Name          => 'Site', # overridden by -SiteSectionName
            -MatchType     => 'exact',
            -MergePriority => 0,
            -SectionType   => 'env',
        },
        {
            -Name          => 'AppMatch',
            -MatchType     => 'regex',
            -SectionType   => 'module',
            -MergePriority => 1,
        },
        {
            -Name              => 'App',
            -MatchType         => 'path',
            -PathPathSeparator => '::',
            -SectionType       => 'module',
            -MergePriority     => 1,
        },
        {
            -Name          => 'LocationMatch',
            -MatchType     => 'regex',
            -SectionType   => 'path',
            -MergePriority => 3,
        },
        {
            -Name          => 'Location',
            -MatchType     => 'path',
            -SectionType   => 'path',
            -MergePriority => 3,
        },
    ],

=cut

sub _default_matchsections {
    my $self          = shift;
    my $site_var_name = shift;

    return
    [
        {
            -Name          => $site_var_name,
            -MatchType     => 'exact',
            -MergePriority => 0,
            -SectionType   => 'env',
        },
        {
            -Name          => 'AppMatch',
            -MatchType     => 'regex',
            -SectionType   => 'module',
            -MergePriority => 1,
        },
        {
            -Name          => 'App',
            -MatchType     => 'path',
            -PathSeparator     => '::',
            -SectionType   => 'module',
            -MergePriority => 1,
        },
        {
            -Name          => 'LocationMatch',
            -MatchType     => 'regex',
            -SectionType   => 'path',
            -MergePriority => 3,
        },
        {
            -Name          => 'Location',
            -MatchType     => 'path',
            -SectionType   => 'path',
            -MergePriority => 3,
        },
    ];
}




=pod

For each section, the L<-SectionType> param indicates what runtime
variable the section will be matched against.  Here are the allowed values

    env:     matched to the environment variable SITE_NAME (overridden by -SiteNameVar)
    module:  name of the Perl Module handling this request (e.g. MyApp::Users)
    path:    path of the request, including path_info (e.g. /cgi-bin/myapp/users.cgi/some/path)

You can use the above L<-SectionType> values in your own custom
L<-MatchSections>.

For more information on the syntax of L<-MatchSections>, see the docs
for L<Config::General::Match>.

=head1 AUTHOR

Michael Graham, C<< <mgraham@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-config-general@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This module would not be possible without Thomas Linden's excellent
L<Config::General> module.

Thanks to the excellent examples provided by the other
L<CGI::Application> plugin authors:  Mark Stosberg, Michael Peters, Cees
Hek and others.

=head1 SOURCE

The source code repository for this module can be found at http://github.com/mgraham/CAP-Config-General

=head1 SEE ALSO

    CGI::Application
    Config::General
    Config::General::Match
    CGI::Application::Plugin::Config::Simple
    CGI::Application::Plugin::ConfigAuto

    CGI::Application::Plugin::TT
    Template::Toolkit
    HTML::Template

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
