package Dancer2::Plugin::GraphQL;
# ABSTRACT: a plugin for adding GraphQL route handlers
use strict;
use warnings;
use Dancer2::Core::Types qw(Bool);
use Dancer2::Plugin;
use GraphQL::Execution qw(execute);
use Module::Runtime qw(require_module);

our $VERSION = '0.09';

has graphiql => (
  is => 'ro',
  isa => Bool,
  from_config => sub { '' },
);

my @DEFAULT_METHODS = qw(get post);
my $TEMPLATE = join '', <DATA>;
my $EXECUTE = sub {
  my ($schema, $query, $root_value, $per_request, $variables, $operationName, $field_resolver) = @_;
  execute(
    $schema,
    $query,
    $root_value,
    $per_request,
    $variables,
    $operationName,
    $field_resolver,
  );
};
sub make_code_closure {
  my ($schema, $root_value, $field_resolver) = @_;
  sub {
    my ($app, $body, $execute) = @_;
    $execute->(
      $schema,
      $body->{query},
      $root_value,
      $app->request->headers,
      $body->{variables},
      $body->{operationName},
      $field_resolver,
    );
  };
};

my $JSON = JSON::MaybeXS->new->utf8->allow_nonref;
sub _safe_serialize {
  my $data = shift or return 'undefined';
  my $json = $JSON->encode( $data );
  $json =~ s#/#\\/#g;
  return $json;
}

# DSL args after $pattern: $schema, $root_value, $resolver, $handler
plugin_keywords graphql => sub {
  my ($plugin, $pattern, @rest) = @_;
  my ($schema, $root_value, $field_resolver, $handler);
  if (ref $rest[0] eq 'ARRAY') {
    my ($class, @values) = @{ shift @rest };
    $class = "GraphQL::Plugin::Convert::$class";
    require_module $class;
    my $converted = $class->to_graphql(@values);
    unshift @rest, @{$converted}{qw(schema root_value resolver)};
    push @rest, make_code_closure(@rest[0..2]) if @rest < 4;
  }
  if (@rest == 4) {
    ($schema, $root_value, $field_resolver, $handler) = @rest;
  } else {
    ($schema, $root_value) = grep ref ne 'CODE', @rest;
    my @codes = grep ref eq 'CODE', @rest;
    # if only one, is $handler
    ($handler, $field_resolver) = reverse @codes;
    $handler ||= make_code_closure($schema, $root_value, $field_resolver);
  }
  my $ajax_route = sub {
    my ($app) = @_;
    if (
      $plugin->graphiql and
      ($app->request->header('Accept')//'') =~ /^text\/html\b/ and
      !defined $app->request->params->{raw}
    ) {
      # disable layout
      my $layout = $app->config->{layout};
      $app->config->{layout} = undef;
      my $result = $app->template(\$TEMPLATE, {
        title            => 'GraphiQL',
        graphiql_version => 'latest',
        queryString      => _safe_serialize( $app->request->params->{query} ),
        operationName    => _safe_serialize( $app->request->params->{operationName} ),
        resultString     => _safe_serialize( $app->request->params->{result} ),
        variablesString  => _safe_serialize( $app->request->params->{variables} ),
      });
      $app->config->{layout} = $layout;
      $app->send_as(html => $result);
    }
    my $body = $JSON->decode($app->request->body);
    my $data = eval { $handler->($app, $body, $EXECUTE) };
    $data = { errors => [ { message => $@ } ] } if $@;
    $app->send_as(JSON => $data);
  };
  foreach my $method (@DEFAULT_METHODS) {
    $plugin->app->add_route(
      method => $method,
      regexp => $pattern,
      code   => $ajax_route,
    );
  }
};

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::GraphQL - a plugin for adding GraphQL route handlers

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The C<graphql> keyword which is exported by this plugin allow you to
define a route handler implementing a GraphQL endpoint.

Parameters, after the route pattern.
The first three can be replaced with a single array-ref. If so,
the first element is a classname-part, which will be prepended with
"L<GraphQL::Plugin::Convert>::". The other values will be passed to
that class's L<GraphQL::Plugin::Convert/to_graphql> method. The returned
hash-ref will be used to set options.

E.g.

  graphql '/graphql' => [ 'Test' ]; # uses GraphQL::Plugin::Convert::Test

=over 4

=item $schema

A L<GraphQL::Schema> object.

=item $root_value

An optional root value, passed to top-level resolvers.

=item $field_resolver

An optional field resolver, replacing the GraphQL default.

=item $route_handler

An optional route-handler, replacing the plugin's default - see example
above for possibilities.

It must return JSON-able Perl data in the GraphQL format, which is a hash
with at least one of a C<data> key and/or an C<errors> key.

If it throws an exception, that will be turned into a GraphQL-formatted
error.

=back

If you supply two code-refs, they will be the C<$resolver> and
C<$handler>. If you only supply one, it will be C<$handler>. To be
certain, pass all four post-pattern arguments.

The route handler code will be compiled to behave like the following:

=over 4

=item *

Passes to the L<GraphQL> execute, possibly via your supplied handler,
the given schema, C<$root_value> and C<$field_resolver>.

=item *

The action built matches POST / GET requests.

=item *

Returns GraphQL results in JSON form.

=back

=head1 CONFIGURATION

By default the plugin will not return GraphiQL, but this can be overridden
with plugin setting 'graphiql', to true.

Here is example to use GraphiQL:

  plugins:
    GraphQL:
      graphiql: true

=head1 AUTHOR

Ed J

Based heavily on L<Dancer2::Plugin::Ajax> by "Dancer Core Developers".

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;

__DATA__
<!--
Copied from https://github.com/graphql/express-graphql/blob/master/src/renderGraphiQL.js
Converted to use the simple template to capture the CGI args
Added the apollo-link-ws stuff, marked with "ADDED"
-->
<!--
The request to this GraphQL server provided the header "Accept: text/html"
and as a result has been presented GraphiQL - an in-browser IDE for
exploring GraphQL.
If you wish to receive JSON, provide the header "Accept: application/json" or
add "&raw" to the end of the URL within a browser.
-->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>GraphiQL</title>
  <meta name="robots" content="noindex" />
  <style>
    html, body {
      height: 100%;
      margin: 0;
      overflow: hidden;
      width: 100%;
    }
  </style>
  <link href="//cdn.jsdelivr.net/npm/graphiql@[% graphiql_version %]/graphiql.css" rel="stylesheet" />
  <script src="//cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js"></script>
  <script crossorigin src="https://unpkg.com/react@16/umd/react.production.min.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@16/umd/react-dom.production.min.js"></script>
  <script src="//cdn.jsdelivr.net/npm/graphiql@[% graphiql_version %]/graphiql.min.js"></script>
</head>
<body>
  <script type="module">
    var defaultQuery = `
# Welcome to GraphiQL
#
# GraphiQL is an in-browser tool for writing, validating, and
# testing GraphQL queries.
#
# Type queries into this side of the screen, and you will see intelligent
# typeaheads aware of the current GraphQL type schema and live syntax and
# validation errors highlighted within the text.
#
# GraphQL queries typically start with a "{" character. Lines that start
# with a # are ignored.
#
# An example GraphQL query might look like:
#
#     {
#       field(arg: "value") {
#         subField
#       }
#     }
#
# Calder notes:
#
#   Open the "Request Headers" panel located at the bottom of this page
#   to specify Business-Unit and other headers as a JSON object.
#
# Keyboard shortcuts:
#
#  Prettify Query:  Shift-Ctrl-P (or press the prettify button above)
#
#     Merge Query:  Shift-Ctrl-M (or press the merge button above)
#
#       Run Query:  Ctrl-Enter (or press the play button above)
#
#   Auto Complete:  Ctrl-Space (or just start typing)
#
`;
    // Collect the URL parameters
    var parameters = {};
    window.location.search.substr(1).split('&').forEach(function (entry) {
      var eq = entry.indexOf('=');
      if (eq >= 0) {
        parameters[decodeURIComponent(entry.slice(0, eq))] =
          decodeURIComponent(entry.slice(eq + 1));
      }
    });
    // Produce a Location query string from a parameter object.
    function locationQuery(params) {
      return '?' + Object.keys(params).filter(function (key) {
        return Boolean(params[key]);
      }).map(function (key) {
        return encodeURIComponent(key) + '=' +
          encodeURIComponent(params[key]);
      }).join('&');
    }
    // Derive a fetch URL from the current URL, sans the GraphQL parameters.
    var graphqlParamNames = {
      query: true,
      variables: true,
      operationName: true,
      headers: true
    };
    var otherParams = {};
    for (var k in parameters) {
      if (parameters.hasOwnProperty(k) && graphqlParamNames[k] !== true) {
        otherParams[k] = parameters[k];
      }
    }
    var fetchURL = locationQuery(otherParams);
    // Defines a GraphQL fetcher using the fetch API.
    function graphQLFetcher(graphQLParams) {
      var headers =  {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      };
      var extra_headers = JSON.parse(
        parameters.headers || localStorage.getItem('graphiql:headers') || '{ }'
      );
      Object.assign(headers, extra_headers);
      return fetch(fetchURL, {
        method: 'post',
        headers: headers,
        body: JSON.stringify(graphQLParams),
        credentials: 'include',
      }).then(function (response) {
        return response.text();
      }).then(function (responseBody) {
        try {
          return JSON.parse(responseBody);
        } catch (error) {
          return responseBody;
        }
      });
    }
    // When the query and variables string is edited, update the URL bar so
    // that it can be easily shared.
    function onEditQuery(newQuery) {
      parameters.query = newQuery;
      updateURL();
    }
    function onEditVariables(newVariables) {
      parameters.variables = newVariables;
      updateURL();
    }
    function onEditOperationName(newOperationName) {
      parameters.operationName = newOperationName;
      updateURL();
    }
    function onEditHeaders(newHeaders) {
      parameters.headers = newHeaders;
      updateURL();
    }
    function updateURL() {
      history.replaceState(null, null, locationQuery(parameters));
    }
    let myCustomFetcher = graphQLFetcher;
    // Render <GraphiQL /> into the body.
    ReactDOM.render(
      React.createElement(GraphiQL, {
        fetcher: myCustomFetcher, // ADDED changed from graphQLFetcher
        onEditQuery: onEditQuery,
        onEditVariables: onEditVariables,
        onEditOperationName: onEditOperationName,
        onEditHeaders: onEditHeaders,
        defaultSecondaryEditorOpen: true,
        shouldPersistHeaders: true,
        defaultQuery: defaultQuery,
        query: [% queryString %],
        response: [% resultString %],
        variables: [% variablesString %],
        operationName: [% operationName %],
      }),
      document.body
    );
  </script>
</body>
</html>
