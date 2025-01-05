[![Actions Status](https://github.com/janeskil1525/Daje-Config/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Config/actions)
# NAME

Daje::Workflow::Loader::Load - Loads the JSON based workflows and put them in a hash

# SYNOPSIS

    use Daje::Config;

    # Single file
    my $config = Daje::Config->new(
       path => "path",
    )->load($filename);

    # All files in path
    my $config = Daje::Config->new(
       path => "path",
    )->load();

# DESCRIPTION

Daje::Config is loading workflows from JSON files in a set folder

# REQUIRES

[Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) 

[Mojo::JSON](https://metacpan.org/pod/Mojo%3A%3AJSON) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## load($self,

    load($self,();

Load all workflows in the given path

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
