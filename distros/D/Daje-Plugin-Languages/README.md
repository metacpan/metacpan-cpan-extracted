[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Languages/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Languages/actions?workflow=test)
# NAME

Daje::Plugin::Languages - Mojolicious Plugin

# SYNOPSIS

# DESCRIPTION

Daje::Plugin::Languages is a Mojolicious plugin.

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Plugin::Languages::Languages](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ALanguages%3A%3ALanguages) 

[Daje::Plugin::Languages::Authorities](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ALanguages%3A%3AAuthorities) 

[Daje::Plugin::Languages::Helpers](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ALanguages%3A%3AHelpers) 

[Daje::Plugin::Languages::Routes](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3ALanguages%3A%3ARoutes) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Daje::Plugin::Languages inherits all methods from
Mojolicious::Plugin and implements the following new ones.

# Mojolicious::Lite

     plugin 'Languages';

# Mojolicious

     $self->plugin('Languages');

# register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

Mojolicious, Mojolicious::Guides, https://mojolicious.org.

# AUTHOR

janeskil1525 &lt;janeskil1525@gmail.com

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
