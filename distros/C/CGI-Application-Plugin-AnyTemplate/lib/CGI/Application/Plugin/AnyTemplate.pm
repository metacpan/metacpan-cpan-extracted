
package CGI::Application::Plugin::AnyTemplate;

=head1 NAME

CGI::Application::Plugin::AnyTemplate - Use any templating system from within CGI::Application using a unified interface

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

In your CGI::Application-based webapp:

    use base 'CGI::Application';
    use CGI::Application::Plugin::AnyTemplate;

    sub cgiapp_init {
        my $self = shift;

        # Set template options
        $self->template->config(
            default_type => 'TemplateToolkit',
        );
    }


Later on, in a runmode:

    sub my_runmode {
        my $self = shift;

        my %template_params = (
            name     => 'Winston Churchill',
            age      => 7,
        );

        $self->template->fill('some_template', \%template_params);
    }

=head1 DESCRIPTION

=head2 Template-Independence

C<CGI::Application::Plugin::AnyTemplate> allows you to use any
supported Perl templating system using a single consistent interface.

Currently supported templating systems include L<HTML::Template>,
L<HTML::Template::Expr>, L<HTML::Template::Pluggable>,
L<Template::Toolkit|Template> and L<Petal>.

You can access any of these templating systems using the same interface.
In this way, you can use the same code and switch templating systems on
the fly.

This approach has many uses.  For instance, it can be useful in
migrating your application from one templating system to another.

=head2 Embedded Components

In addition to template abstraction, C<AnyTemplate> also provides a
I<embedded component mechanism>.  For instance, you might include a
I<header> component at the top of every page and a I<footer> component
at the bottom of every page.

These components are actually full L<CGI::Application> run modes, and
can do anything normal run mode can do, including processing form
parameters and filling in their own templates.  See
below under L<"EMBEDDED COMPONENTS"> for details.

=head2 Multiple Named Template Configurations

You can set up multiple named template configurations and select between
them at run time.

    sub cgiapp_init {
        my $self = shift;

        # Can't use Template::Toolkit any more -
        # The boss wants everything has to be XML,
        # so we switch to Petal

        # Set old-style template options (legacy scripts)
        $self->template('oldstyle')->config(
            default_type => 'TemplateToolkit',
            TemplateToolkit => {
                POST_CHOMP => 1,
            }
        );
        # Set new-style template options as default
        $self->template->config(
            default_type => 'Petal',
            auto_add_template_extension => 0,
        );
    }

    sub old_style_runmode {
        my $self = shift;

        # ...

        # use TemplateToolkit to fill template edit_user.tmpl
        $self->template('oldstyle')->fill('edit_user', \%params);

    }

    sub new_style_runmode {
        my $self = shift;

        # ...

        # use Petal to fill template edit_user.xhml
        $self->template->fill('edit_user.xhtml', \%params);

    }

=head2 Flexible Syntax

The syntax is pretty flexible.  Pick a style that's most comfortable for
you.

=head3 CGI::Application::Plugin::TT style syntax

    $self->template->process('edit_user', \%params);

or (with slightly less typing):

    $self->template->fill('edit_user', \%params);

=head3 CGI::Application load_tmpl style syntax

    my $template = $self->template->load('edit_user');
    $template->param('foo' => 'bar');
    $template->output;

=head3 Verbose syntax (for complete control)

    my $template = $self->template('named_config')->load(
        file              => 'edit_user'
        type              => 'TemplateToolkit'
        add_include_paths => '.',
    );

    $template->param('foo' => 'bar');
    $template->output;

See also below under L<"CHANGING THE NAME OF THE 'template' METHOD">.

=cut

use strict;
use CGI::Application;
use Carp;
use Scalar::Util qw(weaken);

if ( ! eval { require Clone } ) {
    if ( eval { require Clone::PP } ) {
        no strict 'refs';
        *Clone::clone = *Clone::PP::clone;
    }
    else {
        die "Neiter Clone nor Clone::PP found - $@\n";
    }
}

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $CAPAT_Namespace);

@ISA = ('Exporter');

@ISA         = 'Exporter';
@EXPORT      = qw(template);
@EXPORT_OK   = qw(load_tmpl);
%EXPORT_TAGS = (load_tmpl => ['load_tmpl', @EXPORT]);

$CAPAT_Namespace = '__ANY_TEMPLATE';

if (CGI::Application->can('new_hook')) {
    CGI::Application->new_hook('template_pre_process');
    CGI::Application->new_hook('template_post_process');
    CGI::Application->new_hook('load_tmpl');
}

sub _new {
    my $proto     = shift;
    my $class     = ref $proto || $proto;
    my $webapp    = shift;
    my $conf_name = shift;

    my $self = {
        'conf_name'      => $conf_name,
        'base_config'    => {},
        'current_config' => {},
        'webapp'         => $webapp,
    };

    bless $self, $class;

    weaken $self->{'webapp'};

    return $self;
}

sub _default_type      { 'HTMLTemplate' }
sub _default_extension { '.html'        }

=head1 METHODS

=head2 config

Initialize the C<AnyTemplate> system and provide the default
configuration.

    $self->template->config(
        default_type => 'HTMLTemplate',
    );

You can keep multiple configurations handy at the same time by passing a
value to C<template>:

    $self->template('oldstyle')->config(
        default_type => 'HTML::Template',
    );
    $self->template('newstyle')->config(
        default_type => 'HTML::Template::Expr',
    );

Then in a runmode you can mix and match configurations:

    $self->template('oldstyle')->load  # loads an HTML::Template driver object
    $self->template('newstyle')->load  # loads an HTML::Template::Expr driver object


The configuration passed to C<config> is divided into three areas:
I<plugin configuration>, I<driver configuration>, and I<native
configuration>:

    Config Type       What it Configures
    -----------       ------------------
    Plugin Config     AnyTemplate itself
    Driver Config     AnyTemplate Driver (e.g. HTMLTemplate)
    Native Config     Actual template module (e.g. HTML::Template)

These are described in more detail below.

=head3 Plugin Configuration

These configuration params are specific to the C<CGI::Application::Plugin::AnyTemplate> itself.
They are included at the top level of the configuration hash passed to C<config>.  For instance:

    $self->template->config(
        default_type                => 'HTMLTemplate',
        auto_add_template_extension => 0,
    );

The I<plugin configuration> parameters and their defaults are as follows:

=over 4

=item default_type

=item type

The default type of template for this named configuration.  Should be the name of a driver
in the C<CGI::Application::Plugin::AnyTemplate::Driver> namespace:

    Type                Driver
    ----                ------
    HTMLTemplate        CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate
    HTMLTemplateExpr    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr
    TemplateToolkit     CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit
    Petal               CGI::Application::Plugin::AnyTemplate::Driver::Petal

=item include_paths

Include Paths (sometimes called search paths) are used by the various
template backends to find filenames that aren't fully qualified by an
absolute path.  Each directory is searched in turn until the template
file is found.

Can be a single string or a reference to a list.

=item auto_add_template_extension

Add a template-system specific extension to template filenames.

So, if this feature is enabled and you provide the filename C<myfile>,
then the actual filename will depend on the current template driver:

    Driver                 Template
    ------                 --------
    HTMLTemplate           myfile.html
    HTMLTemplateExpr       myfile.html
    TemplateToolkit        myfile.tmpl
    Petal                  myfile.xhtml

The per-type extension is controlled by the driver config for each
C<AnyTemplate> driver (see below under L<"Driver and Native Configuration"> for how
to set this).

The C<auto_add_template_extension> feature is on by default.  To disable
it, pass a value of zero:

    $self->template->config(
        auto_add_template_extension => 0,
    );

The automatic extension feature is not just there to save typing - it's
actually there so you can have templates of different types sitting in
the same directory.

    sub my_runmode {
        my $self = shift;
        $self->template->fill;
    }

Then in your template path you can have three files:

    my_runmode.html
    my_runmode.tmpl
    my_runmode.xhtml

Then you can change which templates is used by changing the value of
C<type> that you pass to C<< $self->template->config >>.

For applications that want to dynamically choose their template system
without changing app code, it's a cleaner solution to use the extensions
than trying to swap template paths at runtime.  Even if you keep each
type of template in its own directory, it's simpler to include all
the directories all the time and use different extensions for different
template types.

=item template_filename_generator

If you don't pass a filename to C<load>, one will be generated for you
based on the current run mode.  If you want to customize this process,
you can pass a reference to a subroutine to do the translation.  This
subroutine will be passed a reference to the CGI::Application C<$self>
object.

Here is a subroutine that emulates the built-in behaviour of
C<AnyTemplate>:

    $self->template->config(
        template_filename_generator => sub {
            my ($self, $calling_method_name) = @_;
                return $self->get_current_runmode;
            }
        }
    );


Here is an example of using a template filename generator to make full
templates with full paths based on the module name as well as the
current run mode (this is similar to how L<CGI::Application::Plugin::TT>
generates its template filenames):

    package My::WebApp;
    use File::Spec;

    sub cgiapp_init {
        my $self = shift;

        $self->template->config(
            template_filename_generator => sub {
                my $self     = shift;
                my $run_mode = $self->get_current_runmode;
                my $module   = ref $self;

                my @segments = split /::/, $module;

                return File::Spec->catfile(@segments, $run_mode);
            }
        );
    }

    sub run_mode {
        my $self = shift;
        $self->template->load;  # loads My/WebApp/run_mode.html
    }

    sub other_run_mode {
        my $self = shift;
        $self->template->load;  # loads My/WebApp/other_run_mode.html
    }

Note that if the C<auto_add_template_extension> option is on (which it
is by default), then the extension will be added to your generated
filename after you return it.  If you do not want this to happen, then
set C<auto_add_template_extension> to a false value.

=item component_handler_class

Normally, component embedding is handled by
L<CGI::Application::Plugin::AnyTemplate::ComponentHandler>.  If you want to
use a different class for this purpose, specify the class name as the
value of this paramter.

It still has to provide the same interface as
L<CGI::Application::Plugin::AnyTemplate::ComponentHandler>.  See the source
code of that module for details.

=item return_references

When true (the default), C<output> will return a reference to a string
rather than a copy.  Normally this won't matter.  For instance,
C<CGI::Application> doesn't care whether you return a string or a
reference to a string from your run modes.

However, if you want to manipulate the output of the C<$html> returned
from the template, you may find it convenient to make C<output> return a
string instead of a reference.  Especially if you are converting old
code based on HTML::Template which expects C<output> to return a string.

=back

=head3 Driver and Native Configuration

You can configure all the drivers at once with a single call to
C<config>, by including subsections for each driver type:

    $self->template->config(
        default_type => 'HTMLTemplate',
        HTMLTemplate => {
            cache              => 1,
            global_vars        => 1,
            die_on_bad_params  => 0,
            template_extension => '.html',
        },
        HTMLTemplateExpr => {
            cache              => 1,
            global_vars        => 1,
            die_on_bad_params  => 0,
            template_extension => '.html',
        },
        HTMLTemplatePluggable => {
            cache              => 1,
            global_vars        => 1,
            die_on_bad_params  => 0,
            template_extension => '.html',
        },
        TemplateToolkit => {
            POST_CHOMP         => 1,
            template_extension => '.tmpl',
        },
        Petal => {
            error_on_undef     => 0,
            template_extension => '.xhtml',
        },
    );


Each driver knows how to separate its own configuration from the
configuration belonging to the underlying template system.

For instance in the example above, the C<HTMLTemplate> driver knows that
C<template_extension> is a driver config parameter, but
C<cache_global_vars> and C<die_on_bad_params> are all HTML::Template
configuration parameters.

Similarly, The C<TemplateToolkit> driver knows that template_extension
is a driver config parameter, but C<POST_CHOMP> is a
C<Template::Toolkit> configuration parameter.

For details on driver configuration, see the docs for the individual
drivers:

=over 4

=item L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate>

=item L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr>

=item L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplatePluggable>

=item L<CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit>

=item L<CGI::Application::Plugin::AnyTemplate::Driver::Petal>

=back

=head3 Copying Query data into Templates

B<This feature is now deprecated and will be removed in a future release.>

When you enable this feature all data in C<< $self->query >> are copied
into the template object before the template is processed.

For the C<HTMLTemplate>, C<HTMLTemplateExpr> and
C<HTMLTemplatePluggable> drivers this is done with the C<associate>
feature of L<HTML::Template> and L<HTML::Template::Expr>, respectively:

    my $template = HTML::Template->new(
        associate => $self->query,
    );

For the other systems, this feature is emulated, by copying the query
params into the template params before the template is processed.

To enable this feature, pass a true value to C<associate_query> or
C<emulate_associate_query> (depending on the template system):
    $self->template->config(
        default_type => 'HTMLTemplate',
        HTMLTemplate => {
            associate_query => 1,
        },
        HTMLTemplateExpr => {
            associate_query => 1,
        },
        HTMLTemplatePluggable => {
            associate_query => 1,
        },
        TemplateToolkit => {
            emulate_associate_query => 1,
        },
        Petal => {
            emulate_associate_query => 1,
        },
    );

The reason this feature is now disabled by default is that it
poses a potential XSS (Cross Site Scripting) security risk.

The reason this feature is now deprecated is that in an ideal world
developers shouldn't have to flatten objects and hashes in order to make
them available to their templates. They should be able to pass the query
object (or another object such as a config object) directly into the
template:

    $template->param(
        'query' => $self->query,
        'cfg'   => $self->cfg,
        'ENV'   => $ENV,
    );

And in the template retrieve parameters directly:

    your username: [% query.param('username') %]
    administrator: [% cfg.admin %]
    hostname:      [% ENV.SERVER_NAME %]

This approach works with L<Template::Toolkit|Template>, L<Petal>, and
L<HTML::Template::Pluggable> (via the L<HTML::Template::Plugin::Dot> plugin).

Note that C<associate> and C<associate_query> are not compatible.  So if
you want to associate the query and an additional object, pass a list to
C<associate>:

    $template->config(
        HTMLTemplate => {
            associate => [$self->query, $self->conf]
        }
    );


=cut

sub config {
    my $self = shift;

    my $config = ref $_[0] eq 'HASH' ? { %{ $_[0] } } : { @_ };

    $config->{'callers_package'} = scalar caller;

    # reset storage and add configuration
    $self->_clear_configuration($self->{'base_config'});
    $self->_add_configuration($self->{'base_config'}, $config);
}


# The template method returns or creates an CAP::AnyTemplate object
# either the default one (if no name provided, or the named one)
sub template {
    my ($self, $config_name) = @_;

    # TODO: make CAPAT subclassable somehow?

    if (defined $config_name) {
        # Named config
        if (not exists $self->{$CAPAT_Namespace}->{'__NAMED_CONFIGS'}->{$config_name}) {
            $self->{$CAPAT_Namespace}->{'__NAMED_CONFIGS'}->{$config_name} = __PACKAGE__->_new($self, $config_name);
        }
        return $self->{$CAPAT_Namespace}->{'__NAMED_CONFIGS'}->{$config_name};
    }
    else {
        # Default config
        if (not exists $self->{$CAPAT_Namespace}->{'__DEFAULT_CONFIG'}) {
            $self->{$CAPAT_Namespace}->{'__DEFAULT_CONFIG'} = __PACKAGE__->_new($self);
        }
        return $self->{$CAPAT_Namespace}->{'__DEFAULT_CONFIG'};
    }
}

=head2 load

Create a new template object and configure it.

This can be as simple (and magical) as:

    my $template = $self->template->load;

When you call C<load> with no parameters, it uses the default template
type, the default template configuration, and it determines the name of
the template based on the name of the current run mode.  It determines
the current run mode by calling C<< $self->get_current_runmode >>.

If you want to have the current runmode updated when you pass control to
another runmode, use the L<CGI::Application::Plugin::Forward> module:

    use CGI::Application::Plugin::Forward;

    sub first_runmode {
        my $self = shift;
        return $self->forward('second_runmode');
    }
    sub second_runmode {
        my $self = shift;
        my $template = $self->template->load;  # loads 'second_runmode.html'
    }

If instead you call C<< $self->other_method >> directly, the value
of C<< $self->get_current_runmode >> will not be updated:

    sub first_runmode {
        my $self = shift;
        return $self->other_method;
    }
    sub other_method {
        my $self = shift;
        my $template = $self->template->load;  # loads 'first_runmode.html'
    }

If you want to override the way the default template filename is
generated, you can do so with the C<template_filename_generator>
configuration parameter.

If you call C<load> with one paramter, it is taken to be either the
filename or a reference to a string containing the template text:

    my $template = $self->template->load('somefile');
    my $template = $self->template->load(\$some_text);

If the parameter C<auto_add_template_exension> is true, then the
appropriate extension will be added for this template type.

If you call C<load> with more than one parameter, then
you can specify filename and configuration paramters directly:

    my $template = $self->template->load(
        file                        => 'some_file.tmpl',
        type                        => 'HTMLTemplate',
        auto_add_template_extension => 0,
        add_include_paths           => '..',
        HTMLTemplate => {
            die_on_bad_params => 1,
        },
    );

To initialize the template from a string rather than a file, use:

    my $template = $self->template->load(
        string =>  \$some_text,
    );

The configuration parameters you pass to C<load> are merged with the
configuration that was passed to L<"config">.

You can include any of the configuration parameters that you can pass to
config, plus the following extra parameters:

=over 4

=item file

If you are loading the template from a file, then the C<file> parameter
contains the template's filename.

=item string

If you are loading the template from a string, then the C<string> parameter
contains the text of the template.  It can be either a scalar or a
reference to a scalar.  Both of the following will work:

    # passing a string
    my $template = $self->template->load(
        string => $some_text,
    );

    # passing a reference to a string
    my $template = $self->template->load(
        string => \$some_text,
    );

=item add_include_paths

Additional include paths.  These will be merged with C<include_paths>
before being passed to the template driver.

=back

The C<load> method returns a template driver object.  See below under
C<DRIVER METHODS>, for how to use this object.

=cut

sub load {
    my $self = shift;

    my $config;
    if (@_) {
        if (@_ == 1) {
            if (ref $_[0] eq 'HASH') {
                # args: single hashref
                $config = $_[0];
            }
            else {
                # args: single value (=filename or string_ref)
                if (ref $_[0] eq 'SCALAR') {
                    $config = {
                        'string' => $_[0],
                    };
                }
                else {
                    $config = {
                        'file' => $_[0],
                    };
                }
            }
        }
        else {
            # args: hash
            $config = { @_ };
        }
    }

    # set current configuration from base

    if (keys %$config) {
        $self->{'current_config'} = Clone::clone($self->{'base_config'});
        $self->_add_configuration($self->{'current_config'}, $config);
    }
    else {
        $self->{'current_config'} = $self->{'base_config'};
    }

    my $plugin_config = $self->{'current_config'}{'plugin_config'};

    my $return_references = 1;
    if (exists $plugin_config->{'return_references'}) {
        $return_references = $plugin_config->{'return_references'};
    }

    # determine template type

    my $type = $plugin_config->{'type'}
            || $plugin_config->{'default_type'}
            || $self->_default_type;


    # require driver
    my $driver_class = $self->_require_driver($type);

    # Generate driver config and native config
    my %driver_config = $driver_class->default_driver_config;

    # Copy all params with keys listed in the driver_config_keys
    foreach my $param ($driver_class->driver_config_keys) {
        if (exists $self->{'current_config'}{'driver_config'}{$type}{$param}) {
            $driver_config{$param} = $self->{'current_config'}{'driver_config'}{$type}{$param};
        }
    }

    # Copy whatever is left over into native config
    my $native_config = $self->{'current_config'}{'native_config'}{$type};

    foreach my $param (keys %{ $self->{'current_config'}{'driver_config'}{$type} }) {
        # skip values copied into %driver_config
        if (not exists $driver_config{$param}) {
            $native_config->{$param} = $self->{'current_config'}{'driver_config'}{$type}{$param};
        }
    }

    # Get the string, if supplied
    my $string_ref;
    if (exists $plugin_config->{'string'}) {
        $string_ref = $plugin_config->{'string'} || '';
        $string_ref = \$string_ref unless ref $string_ref;
    }

    # if no string, then guess template filename
    my $filename;
    unless ($string_ref) {
        $filename = $self->_guess_template_filename($plugin_config, \%driver_config, $type, $self->{'webapp'}->get_current_runmode);
    }


    # call load_tmpl hook
    my %tmpl_params;
    if ($self->{'webapp'}->can('call_hook')) {
        my %ht_params = (
           'path' => $plugin_config->{'add_include_paths'},
        );
        $self->{'webapp'}->new_hook('load_tmpl');
        $self->{'webapp'}->call_hook(
            'load_tmpl',
            \%ht_params,
            \%tmpl_params,
            $filename,
        );
        $plugin_config->{'add_include_paths'} = $ht_params{'path'};
    }


    # manage include paths

    my $include_paths = $self->_merged_include_paths($plugin_config);

    # create and initialize driver

    my $driver = $driver_class->_new(
         'driver_config'           => \%driver_config,
         'native_config'           => $native_config,
         'include_paths'           => $include_paths,
         'filename'                => $filename,
         'string_ref'              => $string_ref,
         'return_references'       => $return_references,
         'callers_package'         => $plugin_config->{'callers_package'},
         'webapp'                  => $self->{'webapp'},
         'conf_name'               => $self->{'conf_name'},
         'component_handler_class' => $plugin_config->{'component_handler_class'},
    );

    # Store the tmpl params we picked up from the load_tmpl hook
    if (keys %tmpl_params) {
        $driver->param(%tmpl_params);
    }

    return $driver;

}

# These are the param keys of the plugin_config (see below)
sub _plugin_config_keys {
    qw/
        callers_package
        auto_add_template_extension
        default_type
        type
        include_paths
        add_include_paths
        file
        string
        component_handler_class
        return_references
        template_filename_generator
    /;
}

# This is the default plugin_config (see below)
sub _default_plugin_config {
    (
        auto_add_template_extension => 1
    );
}

# Internally, the configuration is split into three separate sections:
#
#     General
#     -------
#     'plugin'  - configuration for CAP::AnyTemplate itself
#               - This includes keys specified in _plugin_config_keys()
#
#     Per-driver
#     ----------
#     'driver'  - configuration for the driver module
#     'native'  - configuration for the underlying template system module
#
# For instance:
#
#    $self->template->config(
#        default_type   => 'TemplateToolkit',    # plugin config
#        auto_extension => 1,                    # plugin config
#        'TemplateToolkit' => {
#            template_extension => '.html',      # driver config
#            POST_CHOMP         => 1,            # native config
#        }
#    );
#

sub _clear_configuration {
    my ($self, $storage) = @_;

    $storage->{'plugin_config'} = { $self->_default_plugin_config };
    $storage->{'driver_config'} = {};
    $storage->{'native_config'} = {};
}

sub _add_configuration {
    my ($self, $storage, $config) = @_;

    $storage->{'plugin_config'} ||= { $self->_default_plugin_config };
    $storage->{'driver_config'} ||= {};
    $storage->{'native_config'} ||= {};

    foreach my $key ($self->_plugin_config_keys) {
        $storage->{'plugin_config'}{$key} = delete $config->{$key} if exists $config->{$key};
    }

    # After we've removed the config keys for the 'plugin'
    # configuration, the only keys that should remain
    # are the names of drivers

    foreach my $driver (keys %$config) {

        my $module = $self->_require_driver($driver);

        # Start with a blank config
        $storage->{'driver_config'}{$driver} ||= {};

        # add the module's default config
        my %default_config = $module->default_driver_config;

        foreach my $key (keys %default_config) {
            $storage->{'driver_config'}{$key} ||= $default_config{$key};
        }

        # add the config provided by the user
        # values of known driver config keys get put into driver_config
        foreach my $key ($module->driver_config_keys) {
            if (exists $config->{$driver}{$key}) {
                $storage->{'driver_config'}{$driver}{$key} = delete $config->{$driver}{$key};
            }
        }

        # ... and the remaining keys get put into native_config
        foreach my $key (keys %{ $config->{$driver} }) {
            $storage->{'native_config'}{$driver}{$key} = $config->{$driver}{$key};
        }
    }
}

sub _merged_include_paths {
    my ($self, $config) = @_;

    my @include_paths;

    if (my $tmpl_path = $self->{'webapp'}->tmpl_path) {
        if (ref $tmpl_path ne 'ARRAY') {
            $tmpl_path = [ $tmpl_path ];
        }
        push @include_paths, @$tmpl_path;
    }

    if ($config->{'include_paths'} and ref $config->{'include_paths'} ne 'ARRAY') {
        $config->{'include_paths'} = [ $config->{'include_paths'} ];
    }
    push @include_paths, @{ $config->{'include_paths'} || [] };



    $config->{'add_include_paths'} ||= [];
    $config->{'add_include_paths'} = [$config->{'add_include_paths'}] unless ref $config->{'add_include_paths'} eq 'ARRAY';

    unshift @include_paths, @{$config->{'add_include_paths'}};

    # remove duplicates
    my %seen_include_path;
    my @unique_include_paths;
    foreach my $path (@include_paths) {
        next if $seen_include_path{$path};
        $seen_include_path{$path} = 1;
        push @unique_include_paths, $path;
    }

    return @unique_include_paths if wantarray;
    return \@unique_include_paths;
}

# Finds a template driver beneath the namespace of the current package
# followed by '::Driver::'.  Requires this module and returns its package
# name
#
#
# For instance:
#     $module = _require_driver('HTMLTemplate');
#     print $module;  # 'CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate'

sub _require_driver {
    my ($self, $driver) = @_;

    # only allow word characters and colons
    if ($driver =~ /[^\w:]/) {
        croak "CAP::AnyTemplate: Illegal template driver name: $driver\n";
    }

    my $module = (ref $self) . '::Driver::' . $driver;

    eval "require $module";

    if ($@) {
        croak "CAP::AnyTemplate: template driver $module could not be found: $@";
    }
    return $module;
}

sub _guess_template_filename {
    my ($self, $plugin_config, $driver_config, $type, $crm) = @_;


    my $filename;
    if (exists $plugin_config->{'file'}) {
        $filename = $plugin_config->{'file'};
    }
    else {
        # filename set to current run mode
        $filename = $crm;

        if (ref $plugin_config->{'template_filename_generator'} eq 'CODE') {
            $filename = $plugin_config->{'template_filename_generator'}->($self->{'webapp'});
        }
    }

    if ($plugin_config->{'auto_add_template_extension'}) {

        # add extension
        my $extension = $driver_config->{'template_extension'}
                     || $self->_default_extension;

        $filename = $filename . $extension;
    }

    return $filename;
}

=head2 fill

Fill is a convenience method which in a single step creates the
template, fills it with the template paramters and returns its output.

You can call it with or without a filename (or string ref).

The code:

    $self->template->fill('filename', \%params);

is equivalent to:

    my $template = $self->template->load('filename');
    $template->output(\%params);


And the code:

    $self->template->fill(\$some_text, \%params);

is equivalent to:

    my $template = $self->template->load(\$some_text);
    $template->output(\%params);

And the code:

    $self->template->fill(\%params);

is equivalent to:

    my $template = $self->template->load;
    $template->output(\%params);

And the code:

    $self->template->fill('filename');

is equivalent to:

    my $template = $self->template->load('filename');
    $template->output;

And the code:

    $self->template->fill(\$some_text);

is equivalent to:

    my $template = $self->template->load(\$some_text);
    $template->output;

And the code:

    $self->template->fill;

is equivalent to:

    my $template = $self->template->load;
    $template->output;


=cut

sub fill {
    my $self = shift;

    my ($file_or_string, $params, $template);

    if (@_ == 2) {  # two params, first is filename
        ($file_or_string, $params) = @_;
        $template = $self->load($file_or_string);
    }
    elsif (@_ == 1) {  # one param, first is param, filename or scallarref
        if (ref $_[0] and ref $_[0] eq 'HASH') {  # single param is param ref
            ($params) = @_;
            $template = $self->load;
        }
        else { # single string param is filename or scalarref
            ($file_or_string) = @_;
            $template = $self->load($file_or_string);
        }
    }
    else {
        $template = $self->load;
    }

    $params ||= {};

    $template->output($params);
}

=head2 process

C<"process"> is an alias for L<"fill">.

=cut

sub process {
    goto &fill;
}

=head1 APPLICATION METHODS

These methods are called directly on your application's C<$self> object.

=head2 load_tmpl

This is an emulation of L<CGI::Application>'s built-in C<load_tmpl>
method.  For instance:

    $self->load_tmpl('some_template.html');

It is not exported by default.  To enable it, use:

    use CGI::Application::Plugin::AnyTemplate qw/:load_tmpl/;

You can call it the same way as documented in C<CGI::Application> and it
will have the same effect.  However, it will respect the current
template C<type>, so you can still use it to fill templates of different
backends.

The idea is that you can take an existing L<CGI::Application>-based
webapp which uses C<HTML::Template> templates, and add the following
code to it:

    use CGI::Application::Plugin::AnyTemplate qw/:load_tmpl/;

    sub setup {
        my $self = shift;
        $self->template->config(type => TemplateToolkit);
    }

This will change all existing calls to load_tmpl within your application
to use L<Template::Toolkit|Template> based templates.

Calling:

    my $template = $self->load_tmpl('some_template.html');

It is the equivalent of calling:

    my $template = $self->template->load(
        file => 'some_template.html',
        auto_add_template_extension => 0,
    );

If you add extra options to C<load_tmpl>, these will be assumed to be
L<HTML::Template> specific options, with the exception of the C<path>
option, which will be extracted and used as 'add_include_paths':

    my $template = $self->load_tmpl('some_template.html',
        cache => 0,
        path  => '/path/to/templates',
    );

This will get translated into:

    my $template = $self->template->load(
        file => 'some_template.html',
        auto_add_template_extension => 0,
        add_include_paths => '/path/to/templates',
        HTMLTemplate => {
            cache => 0,
        }
    );

Note that if you specify any L<HTML::Template>-specific options here,
they will completely overwrite any options that you passed to config.

Some notes and caveats about using the C<load_tmpl> method:

=over 4

=item *

This method only works for the default template configuration (i.e. C<< $self->template() >>).
If you set up a named configuration (e.g. C<< $self->template('myconfig') >>)
there is no way to access it with C<load_tmpl>.  Since plugins should be
using named configurations, this means that the C<load_tmpl> method
should not be used by plugins.  See L<"NOTES FOR AUTHORS OF PLUGINS AND REUSABLE APPLICATIONS">,
below.

=item *

The C<load_tmpl> method does not automatically add an extension to the
filename you pass to it, even if you have C<auto_add_template_extension>
set to a true value in your call to C<< $self->template->config >>.

=item *

The C<load_tmpl> method ignores always returns a string, not a reference to a
string.  It ignores the setting of the C<returns_references> option.

=back

=cut

sub load_tmpl {
    my ($self, $filename, %ht_options) = @_;

    my %params = (
        file         => $filename,
        auto_add_template_extension => 0,
        HTMLTemplate => \%ht_options,
    );

    my $path = delete $ht_options{'path'};

    if ($path) {
        $params{'add_include_paths'} = $path;
    }
    $params{'return_references'} = undef;

    return $self->template->load(%params);
}

=head2 tmpl_path

You can set the template C<include_paths> by calling
C<< $self->tmpl_path('/path/to/templates') >>.

You can also do so by passing a value to the C<TMPL_PATH> parameter to
your application's C<new> method:

    my $webapp = App->new(
        TMPL_PATH => '/path/to/templates',
    );

Paths that you set via C<tmpl_path>/C<TMPL_PATH> will be put B<last> in
the list of include paths, after C<add_include_paths> and
C<include_paths>.

=head1 DRIVER METHODS

These are the most commonly used methods of the C<AnyTemplate> driver
object.  The driver is what you get back from calling C<< $self->template->load >>.

=head2 param

The C<param> method gets and sets values within the template.

    my $template = $self->template->load;

    my @param_names = $template->param();

    my $value = $template->param('name');

    $template->param('name' => 'value');
    $template->param(
        'name1' => 'value1',
        'name2' => 'value2'
    );

It is designed to behave similarly to the C<param> method in other modules like
L<CGI> and L<HTML::Template>.

=head2 get_param_hash

Returns the template variables as a hash of names and values.

    my %params     = $self->template->get_param_hash;

In a scalar context, returns a reference to the hash used
internally to contain the values:

    my $params_ref = $self->template->get_param_hash;

    $params_ref->{'foo'} = 'bar';  # directly change parameter 'foo'

=head2 output

Returns the template with all the values filled in.

    return $template->output;

You can also supply names and values to the template at this stage:

    return $template->output('name' => 'value', 'name2' => 'value2');

If C<return_references> option is set to true, then the return value
of C<output> will be a reference to a string.  If the
C<return_references> option is false, then a copy of the string will be
returned.  By default C<return_references> is true.

When you call the C<output> method, any components embedded in the
template are run.  See L<"EMBEDDED COMPONENTS">, below.

=head1 PRE- AND POST- PROCESS

There are several ways to customize the template process.  You can
modify the template parameters before the template is filled, and you
can modify the output of the template after it has been filled.

Multiple applications and plugins can hook into the template process
pipeline, each making changes to the template input and output.

For instance, it will be possible to make a general-purpose
C<CGI::Application> plugin that adds arbitrary data to each new
template (such as query parameters or configuration data).

Note that the API has changed for version 0.10 in a
non-backwards-compatible way in order to use the new hook system
provided by recent versions of C<CGI::Application>.

=head2 The load_tmpl hook

The C<load_tmpl> hook is designed to be compatible with the C<load_tmpl>
hook defined by C<CGI::Application> itself.

The C<load_tmpl> hook is called before the template object is created.
Any callbacks that you register to this hook will be called before each
template is loaded.  Register a C<load_tmpl> callback with:

   $self->add_callback('load_tmpl',\&my_load_tmpl);

When the C<load_tmpl> callback is executed it will be passed three
arguments (I<adapted from the> L<CGI::Application> I<docs>):

 1. A hash reference of the extra params passed into C<load_tmpl>
    (ignored by AnyTemplate with the exception of 'path')

 2. Followed by a hash reference to template parameters.
    You can modify this hash by reference to affect values that are
    actually passed to the param() method of the template object.

 3. The name of the template file.

Here's an example stub for a load_tmpl() callback:

    sub my_load_tmpl_callback {
        my ($self, $ht_params, $tmpl_params, $tmpl_file) = @_;
        # modify $tmpl_params by reference...
    }

Currently, of all the params in C<$ht_params>, all but 'path' are
ignored, because these are specific to C<HTML::Template>.  If you want to
write a generic callback that needs to be able to access or modify
C<HTML::Template> parameters then let me know, or add a feature request
on L<http://rt.cpan.org>.

The C<path> param of C<$ht_params> is initially set to the value of
C<add_include_paths> (if set).  Your callback can modify the C<path>
param, and C<add_include_param> will be set to the result.

Plugin authors who want to provide template processing features are
encouraged to use the 'load_tmpl' hook when possible, since it will work
both with AnyTemplate and with L<CGI::Application>'s built-in
C<load_tmpl>.

=head2 The template_pre_process and template_post_process hooks

Before the template output is generated, the C<< template_pre_process >>
hook is called.  Any callbacks that you register to this hook will be
called before each template is processed.  Register a
C<template_pre_process> callback as follows:

    $self->add_callback('template_pre_process', \&my_tmpl_pre_process);

Pre-process callbacks will be passed a reference to the C<$template>
object, and can can modify the parameters passed into the template by
using the C<param> method:

    sub my_tmpl_pre_process {
        my ($self, $template) = @_;

        # Change the internal template parameters by reference
        my $params = $template->get_param_hash;

        foreach my $key (keys %$params) {
            $params{$key} = to_piglatin($params{$key});
        }

        # Can also set values using the param method
        $template->param('foo', 'bar');

    }


After the template output is generated, the C<template_post_process> hook is called.
You can register a C<template_post_process> callback as follows:

    $self->add_callback('template_post_process', \&my_tmpl_post_process);

Any callbacks that you register to this hook will be called after each
template is processed, and will be passed both a reference to the
template object and a reference to the output generated by the template.
This allows you to modify the output of the template:

    sub my_tmpl_post_process {
        my ($self, $template, $output_ref) = @_;

        $$output_ref =~ s/foo/bar/;
    }



=head1 EMBEDDED COMPONENTS

=head2 Introduction

C<CGI::Application::Plugin::AnyTemplate> allows you to include application
components within your templates.

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

L<HTML::Template::Pluggable> syntax:

    <TMPL_VAR EXPR="cgiapp.embed('some_run_mode')">

L<Template::Toolkit|Template> syntax:

    [% CGIAPP.embed("some_run_mode") %]

L<Petal> syntax:

    <span tal:replace="structure CGIAPP/embed 'some_run_mode'">
        this text gets replaced by the output of some_run_mode
    </span>

=head2 Getting Template Variables from the Containing Template

The component run mode is passed a reference to the template object that
contained the component.  The component run mode can use this object
to access the params that were passed to the containing template.

For instance:

    sub header {
        my ($self, $containing_template, @other_params) = @_;

        my %tmplvars = (
            'title' => 'My glorious home page',
        );

        my $template = $self->template->load;

        $template->param(%tmplvars, $containing_template->get_param_hash);
        return $template->output;
    }

In this example, the template values of the enclosing template would
override any values set by the embedded component.

=head2 Passing Parameters

The template can pass parameters to the target run mode.  These are
passed in after the reference to the containing template object.

Parameters can either be literal strings, specified within the template
text, or they can be keys that will be looked up in the template's
params.

Literal strings are enclosed in double or single quotes.  Param keys are
barewords.

L<HTML::Template> syntax:

    <TMPL_VAR NAME="CGIAPP_embed('some_run_mode', param1, 'literal string2')">

I<Note that HTML::Template doesn't support this type of callback natively>
I<and that this behaviour is emulated by the HTMLTemplate driver>
I<see the docs to> L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate>
I<for limitations to the emulation>.

L<HTML::Template::Expr> syntax:

    <TMPL_VAR EXPR="CGIAPP_embed('some_run_mode', param1, 'literal string2')">

L<HTML::Template::Pluggable> syntax:

    <TMPL_VAR EXPR="cgiapp.embed('some_run_mode', param1, 'literal string2')">

L<Template::Toolkit|Template> syntax:

    [% CGIAPP.embed("some_run_mode", param1, 'literal string2' ) %]

L<Petal> syntax:

    <span tal:replace="structure CGIAPP/embed 'some_run_mode' param1 'literal string2' ">
        this text gets replaced by the output of some_run_mode
    </span>


=cut


=head1 NOTES FOR AUTHORS OF PLUGINS AND REUSABLE APPLICATIONS

If you are writing a L<CGI::Application> plugin module, or you are
writing a C<CGI::Application> program that will be distributed to other
people (e.g. on CPAN), then it's important to take steps to prevent your
application's use of L<CGI::Application::Plugin::AnyTemplate> from
conflicting with other plugins or with your end users.

When a plugin that uses L<CGI::Application::Plugin::AnyTemplate> calls:

   $self->template->config(...)

It overwrites any existing template configuration with the new settings.
So if two plugins do that, they probably clobber each other.

However, L<CGI::Application::Plugin::AnyTemplate> has the feature of
named independent configs:

   $self->template('your_module')->config(...)
   $self->template('my_plugin')->config(...)

These configs remain separate from each other.  However, you have to
keep using these names throughout your module, even when you load and
fill the template.  For instance:

   sub my_runmode {
       my $self = shift;
       my $template = $self->template('my_plugin')->load;
       $template->output;
   }

   sub your_runmode {
       my $self = shift;
       my %params;
       $self->template('your_module')->fill(\%params);
   }

It's uglier and more verbose, but it also prevents plugins from
stepping on each other's toes.

L<CGI::Application> plugins that use
L<CGI::Application::Plugin::AnyTemplate> should default to
using their own package name for the AnyTemplate config name:

   $self->template(__PACKAGE__)->config(...);
   $self->template(__PACKAGE__)->fill(...);

=head1 CHANGING THE NAME OF THE 'template' METHOD

If you want to access the features of this module using a method other
than C<template>, you can do so via Anno Siegel's L<Exporter::Renaming>
module (available on CPAN).

For instance, to use syntax similar to L<CGI::Application::Plugin::TT>:

    use Exporter::Renaming;
    use CGI::Application::Plugin::AnyTemplate Renaming => [ template => tt];

    sub cgiapp_init {
        my $self = shift;

        my %params = ( ... );

        # Set config file and other options
        $self->tt->config(
            default_type => 'TemplateToolkit',
        );

    }

    sub my_runmode {
        my $self = shift;
        $self->tt->process('file', \%params);
    }

And to use syntax similar to L<CGI::Application>'s C<load_tmpl> mechanism:

    use Exporter::Renaming;
    use CGI::Application::Plugin::AnyTemplate Renaming => [ template => tmpl];

    sub cgiapp_init {
        my $self = shift;

        # Set config file and other options
        $self->tmpl->config(
            default_type => 'HTMLTemplate',
        );

    }

    sub my_runmode {
        my $self = shift;

        my %params = ( ... );

        my $template = $self->tmpl->load('file');
        $template->param(\%params);
        $template->output;
    }

=head1 AUTHOR

Michael Graham, C<< <mgraham@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

I originally wrote this to be a subsystem in Richard Dice's
L<CGI::Application>-based framework, before I moved it into its own module.

Various ideas taken from L<CGI::Application> (Jesse Erlbaum),
L<CGI::Application::Plugin::TT> (Cees Hek) and C<Text::Boilerplate>
(Stephen Nelson).

C<Template::Toolkit> singleton support code stolen from L<CGI::Application::Plugin::TT>.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-anytemplate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SOURCE

The source code repository for this module can be found at http://github.com/mgraham/CAP-AnyTemplate/

=head1 SEE ALSO

    CGI::Application::Plugin::AnyTemplate::Base
    CGI::Application::Plugin::AnyTemplate::ComponentHandler
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplatePluggable
    CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit
    CGI::Application::Plugin::AnyTemplate::Driver::Petal

    CGI::Application

    Template::Toolkit
    HTML::Template

    HTML::Template::Pluggable
    HTML::Template::Plugin::Dot

    Petal

    Exporter::Renaming

    CGI::Application::Plugin::TT


=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
