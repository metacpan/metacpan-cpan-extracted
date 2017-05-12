[![Build Status](https://travis-ci.org/hitode909/APISchema.svg?branch=master)](https://travis-ci.org/hitode909/APISchema)
# NAME

APISchema - Schema for API

# SYNOPSIS

    # bmi.def

    resource figure => {
        type => 'object',
        description => 'Figure, which includes weight and height',
        properties => {
            weight  => {
                type => 'number',
                description => 'Weight(kg)',
                example => 50,
            },
            height  => {
                type => 'number',
                description => 'Height(m)',
                example => 1.6,
            },
        },
        required => ['weight', 'height'],
    };

    resource bmi => {
        type => 'object',
        description => 'Body mass index',
        properties => {
            value  => {
                type => 'number',
                description => 'bmi value',
                example => 19.5,
            },
        },
        required => ['value'],
    };

    POST '/bmi/' => {
        title           => 'BMI API',
        description     => 'This API calculates your BMI.',
        destination     => {
            controller  => 'BMI',
            action      => 'calculate',
        },
        request         => 'figure',
        response        => 'bmi',
    };

    # main.pl

    use APISchema::DSL;
    my $schema = APISchema::DSL::process {
        include 'bmi.def';
    };

    # Routing
    use APISchema::Generator::Router::Simple;
    my $router = do {
        my $generator = APISchema::Generator::Router::Simple->new;
        $generator->generate_router($schema);
    };

    # Inject routes to an existing router object
    my $router = Router::Simple->new;
    $router->connect(...);
    my $generator = APISchema::Generator::Router::Simple->new;
    $generator->inject_routes($schema => $router);

    # Documentation
    use APISchema::Generator::Markdown;
    print do {
        my $generator = APISchema::Generator::Markdown->new;
        $generator->format_schema($schema);
    };

    # Middleware (in app.psgi)

    enable "APISchema::ResponseValidator", schema => $schema;
    enable "APISchema::RequestValidator", schema => $schema;

# DESCRIPTION

APISchema is Schema for API

It provides DSL to describe API specification schema.
It generates router, validator, document from API schema.

# LICENSE

Copyright (C) hitode909 and tarao.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

hitode909 <hitode909@gmail.com>

tarao <tarao.gnn@gmail.com>
