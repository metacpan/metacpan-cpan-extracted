# NAME

Dancer2::Plugin::MobileDevice - Make a Dancer2 app mobile-aware

# SYNOPSIS

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

# DESCRIPTION

A plugin for [Dancer2](https://metacpan.org/pod/Dancer2)-powered webapps to easily detect mobile clients and offer
a simplified layout, and/or act in different ways.

The plugin offers a `is_mobile_device` keyword, which returns true if the
device is recognised as a mobile device.

It can also automatically change the layout used to render views for mobile
clients.

# Custom layout for mobile devices

This plugin can use a custom layout for recognised mobile devices, allowing you
to present a simplified page template for mobile devices.  To enable this, use
the `mobile_layout` setting for this plugin - for instance, add the following
to your config file:

    plugins:
      MobileDevice:
        mobile_layout: 'mobile'

This means that, when `template` is called to render a view, if the client is
recognised as a mobile device, the layout named `mobile` will be used, rather
than whatever the current `layout` setting is.

You can of course still override this layout by supplying a layout option to the
`template` call in the usual way (see the [Dancer2](https://metacpan.org/pod/Dancer2) documentation for how to do
this).

**Caution**: Do not change `mobile_layout` during the processing of
a request.  That is unsupported and the behaviour of the plugin is not
guaranteed in that situation.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::MobileDevice

You can also look for information at:

- [MetaCPAN](https://metacpan.org/pod/Dancer2::Plugin::MobileDevice).
- [GitHub](https://github.com/cxw42/Dancer2-Plugin-MobileDevice)

# BUGS

Please report any bugs or feature requests to
[http://github.com/cxw42/Dancer2-Plugin-MobileDevice/issues](http://github.com/cxw42/Dancer2-Plugin-MobileDevice/issues)

# FUNCTIONS

This section exists to satisfy [Pod::Coverage](https://metacpan.org/pod/Pod::Coverage) :D .

## is\_mobile\_device

Return truthy if the current request is from a mobile device.

## BUILD

Adds the hooks described above.

# ACKNOWLEDGEMENTS

This plugin is a Dancer2 port of [Dancer::Plugin::MobileDevice](https://metacpan.org/pod/Dancer::Plugin::MobileDevice),
initially written for an article of the Dancer advent calendar 2010.

Thanks to the Dancer core developers for contributions.  Please see the
package metadata for additional contributors.

# LICENSE

Copyright (C) 2019 Christopher White <cxw@cpan.org>

Portions copyright (c) 2017 Yanick Champoux

Portions copyright (c) 2010 Alexis Sukriah

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Christopher White <cxw@cpan.org>
