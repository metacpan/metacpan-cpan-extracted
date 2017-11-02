# NAME

Dancer2::Plugin::GraphQL - a plugin for adding GraphQL route handlers

# SYNOPSIS

    package MyWebApp;

    use Dancer2;
    use Dancer2::Plugin::GraphQL;
    use GraphQL::Schema;

    my $schema = GraphQL::Schema->from_doc(<<'EOF');
    schema {
      query: QueryRoot
    }
    type QueryRoot {
      helloWorld: String
    }
    EOF
    graphql '/graphql' => $schema, { helloWorld => 'Hello, world!' };

    dance;

    # OR, equivalently:
    graphql '/graphql' => $schema => sub {
      my ($app, $body, $execute) = @_;
      # returns JSON-able Perl data
      $execute->(
        $schema,
        $body->{query},
        undef, # $root_value
        $app->request->headers,
        $body->{variables},
        $body->{operationName},
        undef, # $field_resolver
      );
    };

    # OR, with bespoke user-lookup and caching:
    graphql '/graphql' => sub {
      my ($app, $body, $execute) = @_;
      my $user = MyStuff::User->lookup($app->request->headers->header('X-Token'));
      die "Invalid user\n" if !$user; # turned into GraphQL { errors => [ ... ] }
      my $cached_result = MyStuff::RequestCache->lookup($user, $body->{query});
      return $cached_result if $cached_result;
      MyStuff::RequestCache->cache_and_return($execute->(
        $schema,
        $body->{query},
        undef, # $root_value
        $user, # per-request info
        $body->{variables},
        $body->{operationName},
        undef, # $field_resolver
      ));
    };

# DESCRIPTION

The `graphql` keyword which is exported by this plugin allow you to
define a route handler implementing a GraphQL endpoint.

Parameters, after the route pattern.
The first three can be replaced with a single array-ref. If so,
the first element is a classname-part, which will be prepended with
"[GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert)::". The other values will be passed to
that class's ["to\_graphql" in GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert#to_graphql) method. The returned
hash-ref will be used to set options.

E.g.

    graphql '/graphql' => [ 'Test' ]; # uses GraphQL::Plugin::Convert::Test

- $schema

    A [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) object.

- $root\_value

    An optional root value, passed to top-level resolvers.

- $field\_resolver

    An optional field resolver, replacing the GraphQL default.

- $route\_handler

    An optional route-handler, replacing the plugin's default - see example
    above for possibilities.

    It must return JSON-able Perl data in the GraphQL format, which is a hash
    with at least one of a `data` key and/or an `errors` key.

    If it throws an exception, that will be turned into a GraphQL-formatted
    error.

If you supply two code-refs, they will be the `$resolver` and
`$handler`. If you only supply one, it will be `$handler`. To be
certain, pass all four post-pattern arguments.

The route handler code will be compiled to behave like the following:

- Passes to the [GraphQL](https://metacpan.org/pod/GraphQL) execute, possibly via your supplied handler,
the given schema, `$root_value` and `$field_resolver`.
- The action built matches POST / GET requests.
- Returns GraphQL results in JSON form.

# CONFIGURATION

By default the plugin will not return GraphiQL, but this can be overridden
with plugin setting 'graphiql', to true.

Here is example to use GraphiQL:

    plugins:
      GraphQL:
        graphiql: true

# AUTHOR

Ed J

Based heavily on [Dancer2::Plugin::Ajax](https://metacpan.org/pod/Dancer2::Plugin::Ajax) by "Dancer Core Developers".

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
