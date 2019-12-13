package Dancer2::Plugin::MobileDevice;

use strict;
use warnings;

our $VERSION = "0.000002";

=head1 NAME

Dancer2::Plugin::MobileDevice - Make a Dancer2 app mobile-aware

=cut

use Dancer2::Plugin;

plugin_keywords qw(is_mobile_device);

sub is_mobile_device {
    my $self = shift;
    return (($self->app->request->user_agent || '')
        =~ /(?:iP(?:ad|od|hone)|Android|BlackBerry|Mobile|Palm)/) || 0 ;
} #is_mobile_device

sub BUILD {
    my $plugin = shift;

    # Change the layout setting.  Save the old to reset the setting later.
    # We check config->{mobile_layout} within the hook rather than outside
    # so that the plugin will respond correctly if mobile_layout is
    # changed between requests.
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                return unless $plugin->config->{mobile_layout};
                return unless $plugin->is_mobile_device;
                my $mobile_layout = $plugin->config->{mobile_layout};
                $plugin->app->log(debug => "Using mobile layout $mobile_layout");

                $plugin->app->request->var(orig_layout => $plugin->app->setting('layout'));
                $plugin->app->setting(layout => $mobile_layout);
            }
        )
    );

    # After a request, reset the layout for the benefit of future requests.
    # Don't check the state of the request just in case the mobile_layout
    # has changed between the beginning and the end of the request (although
    # I'm not sure how that could happen!).
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                my $vars = $plugin->app->request->vars;
                return unless exists $vars->{orig_layout};
                    # Can't check truthiness, since undef is a valid
                    # orig_layout value.

                $plugin->app->log(debug => "resetting layout to " .
                    ($vars->{orig_layout} || '<falsy>'));
                $plugin->app->setting(layout => $vars->{orig_layout});
            }
        )
    );

    # Make variable 'is_mobile_device' available in templates
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my $tokens = shift;
                $plugin->app->request->var(is_mobile_device => $plugin->is_mobile_device);
                $tokens->{'is_mobile_device'} = $plugin->is_mobile_device;

                $plugin->app->log(debug => 'Requester ' .
                    ($plugin->is_mobile_device ? 'is' : 'is not') .
                    ' mobile device');
            }
        )
    );

} #BUILD

1;
__END__

=head1 SYNOPSIS

    package MyWebApp;
    use Dancer2;
    use Dancer2::Plugin::MobileDevice;

    get '/' => sub {
        if (is_mobile_device) {
            # do something for mobile
        }
        else {
            # do something for regular agents
        }
    };

=head1 DESCRIPTION

A plugin for L<Dancer2>-powered webapps to easily detect mobile clients and offer
a simplified layout, and/or act in different ways.

The plugin offers a C<is_mobile_device> keyword, which returns true if the
device is recognised as a mobile device.

It can also automatically change the layout used to render views for mobile
clients.

=head1 Custom layout for mobile devices

This plugin can use a custom layout for recognised mobile devices, allowing you
to present a simplified page template for mobile devices.  To enable this, use
the C<mobile_layout> setting for this plugin - for instance, add the following
to your config file:

  plugins:
    MobileDevice:
      mobile_layout: 'mobile'

This means that, when C<template> is called to render a view, if the client is
recognised as a mobile device, the layout named C<mobile> will be used, rather
than whatever the current C<layout> setting is.

You can of course still override this layout by supplying a layout option to the
C<template> call in the usual way (see the L<Dancer2> documentation for how to do
this).

B<Caution>: Do not change C<mobile_layout> during the processing of
a request.  That is unsupported and the behaviour of the plugin is not
guaranteed in that situation.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::MobileDevice

You can also look for information at:

=over

=item *

L<MetaCPAN|https://metacpan.org/pod/Dancer2::Plugin::MobileDevice>.

=item *

L<GitHub|https://github.com/cxw42/Dancer2-Plugin-MobileDevice>

=back

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/cxw42/Dancer2-Plugin-MobileDevice/issues>

=head1 FUNCTIONS

This section exists to satisfy L<Pod::Coverage> :D .

=head2 is_mobile_device

Return truthy if the current request is from a mobile device.

=head2 BUILD

Adds the hooks described above.

=head1 ACKNOWLEDGEMENTS

This plugin is a Dancer2 port of L<Dancer::Plugin::MobileDevice>,
initially written for an article of the Dancer advent calendar 2010.

Thanks to the Dancer core developers for contributions.  Please see the
package metadata for additional contributors.

=head1 LICENSE

Copyright (C) 2019 Christopher White E<lt>cxw@cpan.orgE<gt>

Portions copyright (c) 2017 Yanick Champoux

Portions copyright (c) 2010 Alexis Sukriah

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Christopher White E<lt>cxw@cpan.orgE<gt>

=cut
