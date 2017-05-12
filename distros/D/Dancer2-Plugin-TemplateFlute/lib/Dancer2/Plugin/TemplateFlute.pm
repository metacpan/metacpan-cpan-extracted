package Dancer2::Plugin::TemplateFlute;

use warnings;
use strict;

use Dancer2::Plugin;
use Dancer2::Plugin::TemplateFlute::Form;

=head1 NAME

Dancer2::Plugin::TemplateFlute - Dancer2 form handler for Template::Flute template engine

=head1 VERSION

Version 0.202

=cut

our $VERSION = '0.202';

plugin_keywords 'form';

sub form {
    my $plugin = shift;

    my $name;
    if ( @_ % 2 ) {
        $name = shift;
    }

    my %params = @_;
    $params{name} = $name if $name;

    $plugin->app->log("debug", "form called with name: $params{name}");

    my $source = delete $params{source};

    # for POST default to body_parameters
    $source = 'body' if ( !$source && $plugin->app->request->is_post );

    if ( $source ) {
        if ( $source eq 'body' ) {
            $params{values} = $plugin->app->request->body_parameters;
        }
        elsif ( $source eq 'query' ) {
            $params{values} = $plugin->app->request->query_parameters;
        }
        elsif ( $source eq 'parameters' ) {
            $params{values} = $plugin->app->request->parameters;
        }
    }

    my $form = Dancer2::Plugin::TemplateFlute::Form->new(
        log_cb  => sub { $plugin->app->logger_engine->log(@_) },
        session => $plugin->app->session,
        %params,
    );

    $form->from_session if ( $source && $source eq 'session' );

    return $form;
}

=head1 SYNOPSIS

Display template with checkout form:
    
    get '/checkout' => sub {
        my $form;

        $form = form( name => 'checkout', source => 'session' );
	
        template 'checkout', { form => $form };
    };

Retrieve form input from checkout form body:

    post '/checkout' => sub {
        my ($form, $values);

        $form = form( name => 'checkout', source => 'body' );
        $values = $form->values;
    };

Reset form after completion to prevent old data from
showing up on new form:

    form('checkout')->reset;

If you have multiple forms then just pass the form token as an array reference:

    get '/cart' => sub {
        my ( $cart_form, $inquiry_form );

        # 'source' defaults to 'session' if not provided
        $cart_form    = form( name => 'cart' );

        # equivalent to form( name => 'inquiry' )
        $inquiry_form = form( 'inquiry' );
	
        template 'checkout', { form => [ $cart_form, $inquiry_form ] };
    };

=head1 KEYWORDS

=head2 form <$name|%params>

The following C<%params> are recognised:

=head3 name

The name of the form. Defaults to 'main'.

=head3 values

    my $form = form( 'main', values => $params );

The form parameters as a L<Hash::MultiValue> object or something that can
be coerced into one.

Instead of L</values> you can also use L</source> to set initial values.

=head3 source

    my $form = form( name => 'main', source => 'body' );

The following values are valid:

=over

=item body

This sets the form values to the request body parameters
L<Dancer2::Core::Request::body_parameters>.

=item query

This sets the form values to the request query parameters
L<Dancer2::Core::Request::query_parameters>.

=item parameters

This sets the form values to the combined body and request query parameters
L<Dancer2::Core::Request::parameters>.

=item session

Reads in values from the session. This is the default if no L</source> or
L</parameters> are specified.

=back

B<NOTE:> if both L</source> and L</values> are supplied then L<values> is
ignored.

See L<Dancer2::Plugin::TemplateFlute::Form> for details of other parameters
that can be used.

=head1 DESCRIPTION
    
C<Dancer2::Plugin::TemplateFlute> is used for forms with the
L<Dancer2::Template::TemplateFlute> templating engine.    

Form fields, values and errors are stored into and loaded from the session key
C<form>.

=head1 AUTHORS

Original Dancer plugin by:

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

Initial port to Dancer2 by:

Evan Brown (evanernest), C<< evan at bottlenose-wine.com >>

Rehacking to Dancer2's plugin2 and general rework:

Peter Mottram (SysPete), C<< peter at sysnix.com >>

=head1 BUGS

Please report any bugs or feature requests via GitHub issues:
L<https://github.com/interchange/Dancer2-Plugin-TemplateFlute/issues>.

We will be notified, and then you'll automatically be notified of progress
on your bug as we make changes.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke).

Copyright 2015-1016 Evan Brown.

Copyright 2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
