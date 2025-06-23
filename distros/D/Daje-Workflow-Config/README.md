[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Config/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Config/actions)
# NAME

Daje::Workflow::Config - Loads the JSON based configs and put them in a hash

# SYNOPSIS

    use Daje::Workflow::Config;

    # Single file
    my $config = Daje::Workflow::Config->new(
       path => "path",
    )->load($filename);

    my $parameter = "key";

    my $value = $config->param($parameter);

    my $parameter = "key1.key2";

    my $value = $config->param($parameter);

# DESCRIPTION

Daje::Config is loading workflows from JSON files in a set folder

# REQUIRES

[Daje::Config](https://metacpan.org/pod/Daje%3A%3AConfig) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

[v5.40](https://metacpan.org/pod/v5.40) 

# METHODS

## load($self,

    load($self,();

## param($self,

    param($self,();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
