
package CGI::Application::Plugin::AnyTemplate::Driver::Petal;

=head1 NAME

CGI::Application::Plugin::AnyTemplate::Driver::Petal - Petal plugin to AnyTemplate

=head1 DESCRIPTION

This is a driver for L<CGI::Application::Plugin::AnyTemplate>, which
provides the implementation details specific to rendering templates via
the L<Petal> templating system.

All C<AnyTemplate> drivers are designed to be used the same way.  For
general usage instructions, see the documentation of
L<CGI::Application::Plugin::AnyTemplate>.

=head1 EMBEDDED COMPONENT SYNTAX (Petal)

B<Note that for embedding component to work properly in Petal, you need to enclose>
B<the contents of the included file in tags, such as C<< <span> >> tags.>

    <span>
    var: <span petal:replace="var"></span>
    </span>

The C<Petal> syntax for embedding components is:

    <span tal:replace="structure CGIAPP/embed 'some_run_mode' some_param1 some_param2 'some literal string 3'">
        this text gets replaced by the output of some_run_mode
    </span>

This can be overridden by the following configuration variables:

    embed_tag_name       # default 'CGIAPP'

For instance by setting the following values in your configuration file:

    embed_tag_name       'MYAPP'

Then the embedded component tag will look like:

    <span tal:replace="structure MYAPP/embed 'some_run_mode'">
        this text gets replaced by the output of some_run_mode
    </span>

Note that when creating documents to be included as components, they
must be complete XML documents.


=cut

use strict;
use Carp;

use CGI::Application::Plugin::AnyTemplate::ComponentHandler;

use CGI::Application::Plugin::AnyTemplate::Base;
use vars qw(@ISA);
@ISA = ('CGI::Application::Plugin::AnyTemplate::Base');

=head1 CONFIGURATION

The L<CGI::Application::Plugin::AnyTemplate::Driver::Petal> driver
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

If this config parameter is true, then L<CGI::Application::Plugin::AnyTemplate::Driver::Petal>
will copy all of the webapp's query params into the template.

This is similar to what would happen if you used L<HTML::Template>'s
C<associate> feature with the webapp's query object:

    my $driver = HTML::Template->new(
        associate => $self->query,
    );

By default C<emulate_associate_query> is false.

=back

All other configuration parameters are passed on unchanged to L<Petal>.

=cut

sub driver_config_keys {
    qw/
       embed_tag_name
       template_extension
       emulate_associate_query
    /;
}

sub default_driver_config {
    (
        template_extension      => '.xhtml',
        embed_tag_name          => 'CGIAPP',
        emulate_associate_query => 0,
    );
}

=head2 required_modules

The C<required_modules> function returns the modules required for this driver
to operate.  In this case: C<Petal>.

=cut

sub required_modules {
    return qw(
        Petal
    );
}

=head1 DRIVER METHODS

=over 4

=item initialize

Initializes the L<Petal> driver.  See the docs for
L<CGI::Application::Plugin::AnyTemplate::Base> for details.

=cut

# create the Petal object,
# using:
#   $self->{'driver_config'}  # config info
#   $self->{'include_paths'}  # the paths to search for the template file
#   $self->filename           # the template file
sub initialize {
    my $self = shift;

    $self->_require_prerequisite_modules;

    # TODO: check out how Petal caching works

    my %config = %{ $self->{'native_config'}};
    $config{'base_dir'} = $self->{'include_paths'};

    my $filename   = $self->filename;
    my $string_ref = $self->string_ref;


    my $driver;
    if ($filename) {
        $config{'file'} = $filename;
        $driver         = Petal->new(%config);
    }
    elsif ($string_ref) {
        croak "Petal: creating templates from strings is not supported in Petal";
    }
    else {
        croak "Petal: either file or string must be specified";
    }



    $self->{'driver'} = $driver;
}

=item render_template

Fills the L<Petal> object with C<< $self->param >>

If the param C<emulate_associate_query> is true, then set params for each of
$self->{'webapp'}->query, mimicking L<HTML::Template>'s associate
mechanism.

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

    my $output = $template->process($params);
    return \$output;
}

=head1 SEE ALSO

    CGI::Application::Plugin::AnyTemplate
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



=head1 AUTHOR

Michael Graham, C<< <mgraham@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


