use Test::Most;

{  
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';

  sub myaction :Chained(/) Does('NamedFields') PathPart('') Field(id=>$args[0]) CaptureArgs(1) {
    my ($self, $c, $arg) = @_;
    Test::Most::is ref($_), 'MyApp';
    Test::Most::is $_{id}, 22;
  }

    sub next_action_in_chain 
      :Chained(myaction) PathPart('') Args(0) Does('NamedFields') 
      Field(foo=>$query{foo}, bar=>$query{bar}) Field(baz=>$query{baz})
    {
      my ($self, $c, $arg) = @_;
      Test::Most::is ref($_), 'MyApp';
      Test::Most::is $_{foo}, 44;
      Test::Most::is $_{baz}, 77;
      Test::Most::is $_{bar}[0], 55;
      Test::Most::is $_{bar}[1], 66;

    }


  $INC{'MyApp/Controller/Root.pm'} = __FILE__;
  MyApp::Controller::Root->config(namespace=>'');

  package MyApp;
  use Catalyst;
  
  MyApp->setup;
}

use Catalyst::Test 'MyApp';
use HTTP::Request::Common;

{
  ok my $res = request(GET '/22?foo=44&bar=55&bar=66&baz=77');
}

done_testing;
