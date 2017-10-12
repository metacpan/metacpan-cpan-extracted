use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw<GET POST>;

{
  package GraphQLApp;
  use Dancer2;
  use Dancer2::Plugin::GraphQL;
  set plugins => { 'GraphQL' => { graphiql => 1 } };
  use GraphQL::Schema;
  use GraphQL::Type::Object;
  use GraphQL::Type::Scalar qw/ $String /;

  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'QueryRoot',
      fields => {
        helloWorld => {
          type => $String,
          resolve => sub { 'Hello, world!' },
        },
      },
    ),
  );
  graphql '/graphql' => $schema;
  graphql '/graphql2' => sub {
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
  graphql '/graphql-live-and-let-die' => sub { die "I died!\n" };
}

my $test = Plack::Test->create( GraphQLApp->to_app );

subtest 'GraphQL with POST' => sub {
  my $res = $test->request(
    POST '/graphql',
      Content_Type => 'application/json',
      Content => '{"query":"{helloWorld}"}',
  );
  my $json = JSON::MaybeXS->new->allow_nonref;
  is_deeply eval { $json->decode( $res->decoded_content ) },
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
    'Content as expected';
};

subtest 'GraphQL with route-handler' => sub {
  my $res = $test->request(
    POST '/graphql2',
      Content_Type => 'application/json',
      Content => '{"query":"{helloWorld}"}',
  );
  my $json = JSON::MaybeXS->new->allow_nonref;
  is_deeply eval { $json->decode( $res->decoded_content ) },
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
    'Content as expected';
};

subtest 'GraphQL with die' => sub {
  my $res = $test->request(
    POST '/graphql-live-and-let-die',
      Content_Type => 'application/json',
      Content => '{"query":"{helloWorld}"}',
  );
  my $json = JSON::MaybeXS->new->allow_nonref;
  is_deeply eval { $json->decode( $res->decoded_content ) },
    { errors => [ { message => "I died!\n" } ] },
    'error as expected';
};

subtest 'GraphiQL' => sub {
  my $res = $test->request(
    GET '/graphql',
      Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  );
  like $res->decoded_content, qr/React.createElement\(GraphiQL/, 'Content as expected';
};

done_testing;
