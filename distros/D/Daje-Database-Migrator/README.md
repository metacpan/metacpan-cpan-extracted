[![Actions Status](https://github.com/janeskil1525/Daje-Database-Migrator/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Database-Migrator/actions?workflow=test)
# NAME

Daje::Database::Migrator - It's the database migrate plugin for Daje::Workflow

# SYNOPSIS

    use Daje::Database::Migrator;

    push @{$migrations}, {class => 'Daje::Workflow::Database', name => 'workflow', migration => 2};

    push @{$migrations}, {file => '/home/user/schema/users.sql', name => 'users'};

    Daje::Database::Migrator->new(
         pg            => $pg,
         migrations    => $migrations,
     )->migrate();

# DESCRIPTION

Daje::Database::Migrator is the Database migrate plugin for Daje

# REQUIRES

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[v5.40](https://metacpan.org/pod/v5.40) 

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
