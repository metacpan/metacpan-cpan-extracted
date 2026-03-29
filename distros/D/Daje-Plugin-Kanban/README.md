[![Actions Status](https://github.com/janeskil1525/Daje-Plugin-Kanban/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Plugin-Kanban/actions?workflow=test)
# NAME

Daje::Plugin::Kanban - Mojolicious Plugin

# SYNOPSIS

# DESCRIPTION

Daje::Plugin::Kanban is a Mojolicious plugin.

# REQUIRES

[Daje::Database::Migrator](https://metacpan.org/pod/Daje%3A%3ADatabase%3A%3AMigrator) 

[Daje::Plugin::Kanban::Languages](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AKanban%3A%3ALanguages) 

[Daje::Plugin::Kanban::Authorities](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AKanban%3A%3AAuthorities) 

[Daje::Plugin::Kanban::Helpers](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AKanban%3A%3AHelpers) 

[Daje::Plugin::Kanban::Routes](https://metacpan.org/pod/Daje%3A%3APlugin%3A%3AKanban%3A%3ARoutes) 

[v5.42](https://metacpan.org/pod/v5.42) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Daje::Plugin::Kanban inherits all methods from
Mojolicious::Plugin and implements the following new ones.

# Mojolicious::Lite

     plugin 'Kanban';

# Mojolicious

     $self->plugin('Kanban');

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
