# NAME

Amon2::Plugin::Web::CSRFDefender - Anti CSRF filter

# SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::CSRFDefender');

# DESCRIPTION

This plugin denies CSRF request.

Do not use this with [HTTP::Session2](https://metacpan.org/pod/HTTP::Session2). Because [HTTP::Session2](https://metacpan.org/pod/HTTP::Session2) has XSRF token management function by itself.

# METHODS

- $c->get\_csrf\_defender\_token()

    Get a CSRF defender token. This method is useful to add token for AJAX request.

- $c->validate\_csrf()

    You can validate CSRF token manually.

# PARAMETERS

- no\_validate\_hook

    Do not run validation automatically.

- no\_html\_filter

    Disable HTML rewriting filter. By default, CSRFDefender inserts XSRF token for each form element.

    It's very useful but it hits performance issue if your site is very high traffic.

- csrf\_token\_generator

    You can change the csrf token generation algorithm.

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# THANKS TO

Kazuho Oku and mala for security advice.

# SEE ALSO

[Amon2](https://metacpan.org/pod/Amon2)
