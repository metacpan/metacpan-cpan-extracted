package APISchema;
use 5.014;
use strict;
use warnings;

our $VERSION = "1.36";

1;
__END__

=encoding utf-8

=head1 NAME

APISchema - Schema for API

=head1 SYNOPSIS

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

=head1 DESCRIPTION

APISchema is Schema for API

It provides DSL to describe API specification schema.
It generates router, validator, document from API schema.

=head1 LICENSE

Copyright (C) hitode909 and tarao.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

hitode909 E<lt>hitode909@gmail.comE<gt>

tarao E<lt>tarao.gnn@gmail.comE<gt>

=cut

