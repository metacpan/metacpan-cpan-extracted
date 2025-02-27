[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Database/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Database/actions)
# NAME

Daje::Workflow::Database - It's the database migrate plugin for Daje::Workflow

# SYNOPSIS

    use Daje::Workflow::Database;

    push @{$migrations}, {class => 'Daje::Workflow::Database', name => 'workflow', migration => 2};

    push @{$migrations}, {file => '/home/user/schema/users.sql', name => 'users'};

    Daje::Workflow::Database->new(
         pg            => $pg,
         migrations    => $migrations,
     )->migrate();

# DESCRIPTION

Daje::Workflow::Database is the Database migrate plugin for Daje::Workflow

# REQUIRES

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## migrate($self)

    migrate($self)();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
