[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Companies/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Companies/actions?workflow=test)
# NAME

Daje::Plugin::Companies - Mojolicious Plugin

# SYNOPSIS

# DESCRIPTION

Daje::Plugin::Companies is a Mojolicious plugin.

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Plugin::Companies::Helpers](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ACompanies%3A%3AHelpers) 

[Daje::Plugin::Companies::Routes](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ACompanies%3A%3ARoutes) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Daje::Plugin::Companies inherits all methods from
Mojolicious::Plugin and implements the following new ones.

# register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# Mojolicious

     $self->plugin('Companies');

# Mojolicious::Lite

     plugin 'Companies';

# SEE ALSO

Mojolicious, Mojolicious::Guides, https://mojolicious.org.

# AUTHOR

janeskil1525 &lt;janeskil1525@gmail.com

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
