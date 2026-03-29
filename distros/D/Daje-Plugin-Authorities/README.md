[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Authorities/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Authorities/actions?workflow=test)
# NAME

Daje::Plugin::Authorities - Mojolicious Plugin

# SYNOPSIS

# DESCRIPTION

Daje::Plugin::Authorities is a Mojolicious plugin.

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Plugin::Authorities::Authorities](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AAuthorities%3A%3AAuthorities) 

[Daje::Plugin::Authorities::Helpers](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AAuthorities%3A%3AHelpers) 

[Daje::Plugin::Authorities::Routes](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AAuthorities%3A%3ARoutes) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Daje::Plugin::Authorities inherits all methods from
Mojolicious::Plugin and implements the following new ones.

# Mojolicious

     $self->plugin('Authorities');

# register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# Mojolicious::Lite

     plugin 'Authorities';

# SEE ALSO

Mojolicious, Mojolicious::Guides, https://mojolicious.org.

# AUTHOR

janeskil1525 &lt;janeskil1525@gmail.com

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
