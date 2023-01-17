use Test::Most;

{
  package MyApp::Controller::Example;
  $INC{'MyApp/Controller/Example.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub url_to_self :Local Args(1) {
    my ($self, $c) = @_;
    $c->res->body( $c->uri(":url_to_self", [1]));
  }

  sub uri_to_other :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body( $c->uri(":url_to_self", [1]));
  }

  sub url_to_self2 :Local Args(1) {
    my ($self, $c) = @_;
    $c->res->body( $c->uri("Example:url_to_self", [1]));
  }

  sub uri_to_other2 :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body( $c->uri("Example:url_to_self", [1]));
  }

  package MyApp::Controller::Other;
  $INC{'MyApp/Controller/Other.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub uri_to_other :Local Args(0) Name(hi) {
    my ($self, $c) = @_;
    $c->res->body($c->uri("Example:url_to_self", [1])) unless $c->res->body;
  }

  sub named_uri :Local Args(0) {
    my ($self, $c) = @_;
    $c->res->body($c->uri("#hi"));
    $c->detach("#hi");
  }

  package MyApp;
  use Catalyst 'URI';
  
  MyApp->config('Plugin::URI' => { version => 2 });
  MyApp->setup;
}

use Catalyst::Test 'MyApp';

{
  ok my $res = request "/example/url_to_self/1";
  is $res->content, 'http://localhost/example/url_to_self/1';
}

{
  ok my $res = request "/example/uri_to_other";
  is $res->content, 'http://localhost/example/url_to_self/1';
}

{
  ok my $res = request "/example/url_to_self2/1";
  is $res->content, 'http://localhost/example/url_to_self/1';
}

{
  ok my $res = request "/example/uri_to_other2";
  is $res->content, 'http://localhost/example/url_to_self/1';
}

{
  ok my $res = request "/other/uri_to_other";
  is $res->content, 'http://localhost/example/url_to_self/1';
}

{
  ok my $res = request "/other/named_uri";
  is $res->content, 'http://localhost/other/uri_to_other';
}
done_testing;
