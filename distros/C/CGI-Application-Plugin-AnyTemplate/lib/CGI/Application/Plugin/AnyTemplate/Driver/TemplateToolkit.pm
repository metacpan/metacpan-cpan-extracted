
package CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit;

=head1 NAME

CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit - Template::Toolkit plugin to AnyTemplate

=head1 DESCRIPTION

This is a driver for L<CGI::Application::Plugin::AnyTemplate>, which
provides the implementation details specific to rendering templates via
the L<Template::Toolkit|Template> templating system.

All C<AnyTemplate> drivers are designed to be used the same way.  For
general usage instructions, see the documentation of
L<CGI::Application::Plugin::AnyTemplate>.

=head1 EMBEDDED COMPONENT SYNTAX (Template::Toolkit)

The L<Template::Toolkit|Template> syntax for embedding components is:

    [% CGIAPP.embed("some_run_mode", param1, param2, 'literal string3') %]

This can be overridden by the following configuration variables:

    embed_tag_name       # default 'CGIAPP'

For instance by setting the following values in your configuration file:

    embed_tag_name       'MYAPP'

Then the embedded component tag will look like:

    [% MYAPP.embed("some_run_mode") %]


=head1 TT OBJECT CACHING (singleton support)

=head2 Introduction

In a persistent environment, rather than creating a L<Template::Toolkit|Template>
object each time you fill a template, it is much more efficient to load
a single L<Template::Toolkit|Template> object and use this object to render all
of your templates.

However, in a persistent environment, you may have several different
applications running, and they all might need to set different
L<Template::Toolkit|Template> options (such as C<POST_CHOMP>, etc.).

By default, when the C<TemplateToolkit> driver creates a
L<Template::Toolkit|Template> object, it caches it.  From that point on, whenever
the same application needs a L<Template::Toolkit|Template> object, the driver
uses the cached object rather than creating a new one.

=head2 Multiple Applications in a Shared Persistent Environment

An attempt is made to prevent different applications from
sharing the same TT object.

Internally, the TT objects are stored in a private hash keyed by the web
application's class name.

You can explicitly specify the class name when you call C<config>:

        $self->template->config(
            type          => 'TemplateToolkit',
            TemplateToolkit => {
                storage_class => 'My::Project',
            },
        );

If you don't specify the class name, then the package containing the subroutine
that called C<config> is used.  For instance:

    package My::Project;
    sub setup {
        my $self = shift;
        $self->template->config(                 # My::Project is used to store
            type          => 'TemplateToolkit',  # cached TT object
        );
    }

A typical C<CGI::Application> module hierarchy looks like this:

    CGI::Application
        My::Project
            My::Webapp

In this hierarchy, it makes sense to store the cached TT object in
C<My::Project>.  To make this happen, either call C<< $self->template->config >>
from within C<My::Project>, or explicitly name the C<storage_class> when you call
C<< $self->template->config >>.

=head2 Disabling TT Object Caching

You can disable L<Template::Toolkit|Template> object caching entirely by
providing a false value to the C<object_caching> driver config
parameter:

        $self->template->config(
            type          => 'TemplateToolkit',
            TemplateToolkit => {
                object_caching => 0,
            },
        );

=head2 TT Object Caching and Include Paths

The C<include_paths> driver config parameter is not cached; it is set
every time you call C<< $self->template->load >>. So you can safely used
cached TT objects even if the applications sharing the TT object need
different C<include_paths>.

=cut

use strict;
use Carp;

use CGI::Application::Plugin::AnyTemplate::ComponentHandler;

use CGI::Application::Plugin::AnyTemplate::Base;
use vars qw(@ISA);
@ISA = ('CGI::Application::Plugin::AnyTemplate::Base');

=head1 CONFIGURATION

The L<CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit> driver
accepts the following config parameters:

=over 4

=item embed_tag_name

The name of the tag used for embedding components.  Defaults to
C<CGIAPP>.

=item template_extension

If C<auto_add_template_extension> is true, then
L<CGI::Application::Plugin::AnyTemplate> will append the value of
C<template_extension> to C<filename>.  By default
the C<template_extension> is C<.xhtml>.

=item emulate_associate_query

B<This feature is now deprecated and will be removed in a future release.>

If this config parameter is true, then L<CGI::Application::Plugin::AnyTemplate::Driver::TemplateToolkit>
will copy all of the webapp's query params into the template.

This is similar to what would happen if you used L<HTML::Template>'s
C<associate> feature with the webapp's query object:

    my $driver = HTML::Template->new(
        associate => $self->query,
    );

By default C<emulate_associate_query> is false.

=item object_caching

Whether or not to cache the L<Template::Toolkit|Template> object in a persistent environment

By default, C<object_caching> is enabled.

See L<"TT OBJECT CACHING (singleton support)">, above.

=item storage_class

What class to use as the storage key when object caching is enabled.

By default, C<storage_class> defaults to the package containing the
subroutine that called C<< $self->template->config >>.

See L<"TT OBJECT CACHING (singleton support)">, above.


=back

All other configuration parameters are passed on unchanged to L<Template::Toolkit|Template>.

=head1 CONFIGURING UTF-8 TEMPLATES

C<AnyTemplate> does NOT support L<Template::Toolkit|Template>'s C<binmode> option at runtime:

    # not possible with AnyTemplate
    $tt->process($infile, $vars, $outfile, { binmode => 1 })
        || die $tt->error(), "\n";
    
    # not possible with AnyTemplate
    $tt->process($infile, $vars, $outfile, binmode => 1)
        || die $tt->error(), "\n";
    
    # not possible with AnyTemplate
    $tt->process($infile, $vars, $outfile, binmode => ':utf8')
        || die $tt->error(), "\n";

Instead, use the C<ENCODING> option in the initial config:
     
    $self->template->config(
        default_type => 'TemplateToolkit',
        TemplateToolkit => { 
            ENCODING => 'UTF-8' 
        }
    );

If you have a mix of encodings in your templates, use a separate 
C<AnyTemplate> configuration for each encoding:

    $self->template('ascii')->config(
        default_type => 'TemplateToolkit',
    );
    $self->template('utf-8')->config(
        default_type => 'TemplateToolkit',
        TemplateToolkit => { 
            ENCODING => 'UTF-8' 
        }
    );

=cut

sub driver_config_keys {
    qw/
       storage_class
       object_caching
       cache_storage_keys
       embed_tag_name
       template_extension
       emulate_associate_query
    /;
}

sub default_driver_config {
    (
        object_caching          => 1,
        template_extension      => '.tmpl',
        embed_tag_name          => 'CGIAPP',
        emulate_associate_query => 0,
    );
}

=head2 required_modules

The C<required_modules> function returns the modules required for this driver
to operate.  In this case: C<Template>.

=cut

sub required_modules {
    return qw(
        Template
    );
}

=head1 DRIVER METHODS

=over 4

=item initialize

Initializes the C<TemplateToolkit> driver.  See the docs for
L<CGI::Application::Plugin::AnyTemplate::Base> for details.

=cut

# create the Template::Toolkit object,
# using:
#   $self->{'driver_config'}  # config info
#   $self->{'include_paths'}  # the paths to search for the template file
#   $self->filename           # the template file

my %TT_Object_Store;

sub initialize {
    my $self = shift;

    $self->_require_prerequisite_modules;

    my %config = %{ $self->{'native_config'} };
    $config{'INCLUDE_PATH'} = $self->{'include_paths'};

    my $driver;
    my $storage_class = $self->{'driver_config'}{'storage_class'};
    $storage_class ||= $self->{'callers_package'};

    my $config_name = $self->{'conf_name'};

    if ($self->{'driver_config'}{'object_caching'} and exists $TT_Object_Store{$storage_class}) {
        if (defined $config_name) {
            $driver = $TT_Object_Store{$storage_class}{'named'}{$config_name};
        }
        else {
            $driver = $TT_Object_Store{$storage_class}{'default'};
        }
    }
    if (!$driver) {
        $driver = Template->new(\%config);
    }
    if ($self->{'driver_config'}{'object_caching'}) {
        if (defined $config_name) {
            $TT_Object_Store{$storage_class}{'named'}{$config_name} = $driver;
        }
        else {
            $TT_Object_Store{$storage_class}{'default'} = $driver;
        }
    }

    # Stolen from Cees's CAP::TT
    $driver->context->load_templates->[0]->include_path($self->{'include_paths'});

    $self->{'driver'} = $driver;
}

=item render_template

Fills the L<Template::Toolkit|Template> object with C<< $self->param >>

If the param C<emulate_associate_query> is true, then set params for
each of $self->{'webapp'}->query, mimicking L<HTML::Template>'s
associate mechanism.

Also set up a L<CGI::Application::Plugin::AnyTemplate::ComponentHandler>
object so that the C<CGIAPP.embed> callback will work.

Returns the output of the filled template as a string reference.

See the docs for L<CGI::Application::Plugin::AnyTemplate::Base> for details.

=back

=cut

sub render_template {
    my $self = shift;

    my $driver_config = $self->{'driver_config'};

    my $template = $self->{'driver'};

    my $output = '';

    # emulate HTML::Template's 'associate' behaviour

    if ($driver_config->{'emulate_associate_query'}) {
        my $params = $self->get_param_hash;
        if ($self->{'webapp'}) {
            foreach ($self->{'webapp'}->query->param) {
                $params->{$_} ||= $self->{'webapp'}->query->param($_);
            }
        }
    }

    my $component_handler = $self->{'component_handler_class'}->new(
        'webapp'              => $self->{'webapp'},
        'containing_template' => $self,
    );

    my $params = $self->get_param_hash;
    $params->{$driver_config->{'embed_tag_name'}} = $component_handler;

    my $filename   = $self->filename;
    my $string_ref = $self->string_ref;

    $string_ref or $filename or croak "TemplateToolkit: file or string must be specified";

    $template->process(($string_ref || $filename), $params, \$output) || croak $template->error;
    return \$output;

}

=head1 SEE ALSO

    CGI::Application::Plugin::AnyTemplate
    CGI::Application::Plugin::AnyTemplate::Base
    CGI::Application::Plugin::AnyTemplate::ComponentHandler
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplatePluggable
    CGI::Application::Plugin::AnyTemplate::Driver::Petal

    CGI::Application

    Template::Toolkit
    HTML::Template

    HTML::Template::Pluggable
    HTML::Template::Plugin::Dot

    Petal

    Exporter::Renaming

    CGI::Application::Plugin::TT


=head1 ACKNOWLEDGEMENTS

Thanks to Cees Hek for discussing the issues of caching in a persistent
environment.  And also for his excellent L<CGI::Application::Plugin::TT>
module, from which I stole ideas and some code:  especially the bit
about how to change the include path in a TT object after you've
initialized it.

=head1 AUTHOR

Michael Graham, C<< <mgraham@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


