[![Actions Status](https://github.com/janeskil1525/Daje-Document-Builder/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/janeskil1525/Daje-Document-Builder/actions?workflow=test)
# NAME

     Daje::Document::Builder - It's the document builder

# DESCRIPTION

Daje::Document::Builder Builds documents based on Template Toolkit

# REQUIRES

use Mojo::Base;
use Template;

# METHODS

## process($self)

    process($self)();

# Synopsis

    my $error = Daje::Workflow::Errors::Error->new()

    my $builder = Daje::Document::Builder->new(
        source        => 'Template class',
        data_sections => 'sections',
        data          => $data,
        error         => $error
    );

    $builder->process();

    if($builder->error->has_error()) {
        say $builder->error->error()
    } else {
        my $documents = $builder->output();
    }

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
