[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Templates/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Templates/actions)
# NAME

Daje::Workflow::Templates - It's a template loader

# SYNOPSIS

    use Daje::Workflow::Templates;

    my $templates = Daje::Workflow::Templates->new(
        data_sections => $data_sections,
        source        => $source,
        error         => $error,
    )->load_templates();

# DESCRIPTION

Daje::Workflow::Templates ...

# REQUIRES

[Daje::Tools::Datasections](https://metacpan.org/pod/Daje%3A%3ATools%3A%3ADatasections) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## load\_templates($self)

    load_templates($self)();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
