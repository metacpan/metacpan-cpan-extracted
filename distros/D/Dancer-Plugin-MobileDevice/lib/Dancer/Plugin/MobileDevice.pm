package Dancer::Plugin::MobileDevice;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: make a Dancer app mobile-aware
$Dancer::Plugin::MobileDevice::VERSION = '0.06';
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

register 'is_mobile_device' => sub {
    no warnings 'uninitialized';
    return request->user_agent 
        =~ /(?:iP(?:ad|od|hone)|Android|BlackBerry|Mobile|Palm)/ || 0 ;
};

hook before => sub {
    # If we don't have a mobile layout declared, do nothing.
    my $mobile_layout = plugin_setting->{mobile_layout}
        and is_mobile_device()
        or return;

    var orig_layout => setting('layout');
    setting layout => $mobile_layout;
};

hook after => sub {
    setting layout => delete vars->{orig_layout}
        if plugin_setting->{mobile_layout}
        and is_mobile_device();
};

hook before_template => sub {
    my $tokens = shift;
    $tokens->{'is_mobile_device'} = is_mobile_device();
};

register_plugin;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::MobileDevice - make a Dancer app mobile-aware

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package MyWebApp;
    use Dancer;
    use Dancer::Plugin::MobileDevice;

    get '/' => sub {
        if (is_mobile_device) {
            # do something for mobile
        }
        else {
            # do something for regular agents
        }
    };

=head1 DESCRIPTION

A plugin for L<Dancer>-powered webapps to easily detect mobile clients and offer
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
C<template> call in the usual way (see the L<Dancer> documentation for how to do
this).

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/PerlDancer/Dancer-Plugin-MobileDevice/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::MobileDevice

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-MobileDevice>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-MobileDevice>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-MobileDevice/>

=back

=head1 ACKNOWLEDGEMENTS

This plugin was initially written for an article of the Dancer advent
calendar 2010.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2012, 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
