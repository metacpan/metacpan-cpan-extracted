[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Mail/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Mail/actions?workflow=test)
# NAME

Daje::Plugin::Mail - Mojolicious Plugin

# SYNOPSIS

# DESCRIPTION

Daje::Plugin::Mail is a Mojolicious plugin.

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Plugin::Mail::Helpers](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AMail%3A%3AHelpers) 

[Daje::Plugin::Mail::Routes](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AMail%3A%3ARoutes) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Daje::Plugin::Mail inherits all methods from
Mojolicious::Plugin and implements the following new ones.

# register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# Mojolicious

     $self->plugin('Mail');

# Mojolicious::Lite

     plugin 'Mail';

# SEE ALSO

Mojolicious, Mojolicious::Guides, https://mojolicious.org.

# AUTHOR

janeskil1525 &lt;janeskil1525@gmail.com

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
