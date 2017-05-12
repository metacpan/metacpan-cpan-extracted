
package CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr;

=head1 NAME

CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr - HTML::Template::Expr driver to AnyTemplate

=head1 DESCRIPTION

This is a driver for L<CGI::Application::Plugin::AnyTemplate>, which
provides the implementation details specific to rendering templates via
the L<HTML::Template::Expr> templating system.

All C<AnyTemplate> drivers are designed to be used the same way.  For
general usage instructions, see the documentation of
L<CGI::Application::Plugin::AnyTemplate>.

=head1 EMBEDDED COMPONENT SYNTAX (HTML::Template::Expr)

=head2 Syntax

The L<HTML::Template::Expr> syntax for embedding components is:

    <TMPL_VAR EXPR="CGIAPP_embed('some_run_mode', param1, param2, 'literal string3')">

This can be overridden by the following configuration variables:

    embed_tag_name       # default 'CGIAPP_embed'

For instance by setting the following value in your configuration file:

    embed_tag_name       '__ACME_render'

Then the embedded component tag will look like:

    <TMPL_VAR EXPR="__ACME_render('some_run_mode')">

The value of C<embed_tag_name> must consist of numbers, letters and
underscores (C<_>), and must not begin with a number.

=cut

use strict;
use Carp;

use CGI::Application::Plugin::AnyTemplate::ComponentHandler;

use CGI::Application::Plugin::AnyTemplate::Base;
use vars qw(@ISA);
@ISA = ('CGI::Application::Plugin::AnyTemplate::Base');

=head1 CONFIGURATION

The L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr> driver
accepts the following config parameters:

=over 4

=item embed_tag_name

The name of the tag used for embedding components.  Defaults to
C<CGIAPP_embed>.

=item template_extension

If C<auto_add_template_extension> is true, then
L<CGI::Application::Plugin::AnyTemplate> will append the value of
C<template_extension> to C<filename>.  By default
the C<template_extension> is C<.html>.

=item associate_query

B<This feature is now deprecated and will be removed in a future release.>

If this config parameter is true, then
L<CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplateExpr> will
copy all of the webapp's query params into the template using
L<HTML::Template::Expr>'s C<associate> mechanism:

    my $driver = HTML::Template::Expr->new(
        associate => $self->query,
    );

By default C<associate_query> is false.

If you provide an C<associate> config parameter of your own, that will
disable the C<associate_query> functionality.

=back

All other configuration parameters are passed on unchanged to L<HTML::Template::Expr>.

=cut

sub driver_config_keys {
    qw/
       embed_tag_name
       template_extension
       associate_query
    /;
}

sub default_driver_config {
    (
        template_extension => '.html',
        embed_tag_name     => 'CGIAPP_embed',
        associate_query    => 0,
    );
}

=head2 required_modules

The C<required_modules> function returns the modules required for this driver
to operate.  In this case: C<HTML::Template::Expr>.

=cut

sub required_modules {
    return qw(
        HTML::Template::Expr
    );
}


=head1 DRIVER METHODS

=over 4

=item initialize

Initializes the C<HTMLTemplateExpr> driver.  See the docs for
L<CGI::Application::Plugin::AnyTemplate::Base> for details.

=cut

# create the HTML::Template::Expr object,
# using:
#   $self->{'driver_config'}  # config info
#   $self->{'include_paths'}  # the paths to search for the template file
#   $self->filename           # the template file
#   $self->{'webapp'}->query  # for HTML::Template::Expr's 'associate' method,
#                             # so that the query params are included
#                             # in the template output
sub initialize {
    my $self = shift;

    $self->_require_prerequisite_modules;

    my $string_ref = $self->string_ref;
    my $filename   = $self->filename;

    $string_ref or $filename or croak "HTML::Template file or string must be specified";

    my $query    = $self->{'webapp'}->query or croak "HTML::Template::Expr webapp query not found";

    my $component_handler = $self->{'component_handler_class'}->new(
        'webapp'              => $self->{'webapp'},
        'containing_template' => $self,
    );

    my %params = (
        %{ $self->{'native_config'} },
        path      => $self->{'include_paths'},
        functions => {
            $self->{'driver_config'}{'embed_tag_name'} => sub { $component_handler->embed(@_) },
        }
    );

    if ($filename) {
        $params{'filename'} = $filename;
    }
    if ($string_ref) {
        $params{'scalarref'} = $string_ref;
    }

    if ($self->{'driver_config'}{'associate_query'}) {
        $params{'associate'} ||= $query;  # allow user to override associate with their own
    }
    my $driver = HTML::Template::Expr->new(%params);

    $self->{'driver'} = $driver;

}

# If we have already called output, then any stored params have already
# been stored in the driver.  So when the user calls clear_params on the
# AT object, we have to call clear_params on the driver as well.

sub clear_params {
    my $self = shift;

    if ($self->{'driver'}) {
        $self->{'driver'}->clear_params;
    }
    $self->SUPER::clear_params;
}

=item render_template

Fills the L<HTML::Template::Expr> object with C<< $self->param >>, and
returns the output (as a string reference).

See the docs for L<CGI::Application::Plugin::AnyTemplate::Base> for details.

=back

=cut

sub render_template {
    my $self = shift;

    my $driver_config             = $self->{'driver_config'};

    # fill the template
    my $template = $self->{'driver'};

    $template->param(scalar $self->get_param_hash);
    my $output = $template->output;
    return \$output;
}

=head1 SEE ALSO

    CGI::Application::Plugin::AnyTemplate
    CGI::Application::Plugin::AnyTemplate::Base
    CGI::Application::Plugin::AnyTemplate::ComponentHandler
    CGI::Application::Plugin::AnyTemplate::Driver::HTMLTemplate
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

