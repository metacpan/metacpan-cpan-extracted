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

  my $schema = GraphQL::Schema->from_doc(<<'EOF');
schema {
  query: QueryRoot
}
type QueryRoot {
  helloWorld: String
}
EOF
  graphql '/graphql' => [ 'Test' ];
  graphql '/graphql2' => sub {
    my ($app, $body, $execute) = @_;
    # returns JSON-able Perl data
    $execute->(
      $schema,
      $body->{query},
      { helloWorld => 'Hello, world!' }, # $root_value
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
