use strict;
use warnings;
use Test::More tests => 13;
use App::TemplateServer;
use YAML::Syck;
use Class::MOP;
use HTTP::Request;

{ 
    package TestProvider;
    use Data::Dumper;
    use Moose;
    with 'App::TemplateServer::Provider';
    sub list_templates  { qw/1 2 3/ }
    sub render_template { Dumper($_[2]->data) }
}

ok eval { Class::MOP::load_class('TestProvider') }, 'TestProvider loaded';

my $data = Load(do { local $/; <DATA> });
ok $data, 'data loaded';

my $serv = App::TemplateServer->new(
    _raw_data      => $data,
    provider_class => 'TestProvider',
    docroot        => ['/dev/null'], # not used
);
isa_ok $serv, 'App::TemplateServer', '$serv';

# due to laziness, the package Test doesn't exist now
ok !eval { Test->new }, 'no Test yet';

$serv->_data; # and now it's here

# first, test the created packages
isa_ok my $a = Test->new, 'Test', 'Test->new';
is $a->map_foo_bar('foo'), 'bar';
is $a->map_foo_bar('bar'), 'foo';
is $a->map_foo_bar(qw/foo gorch/), 'INVALID INPUT';

my $req = HTTP::Request->new(GET => '/foo');
my $res = $serv->_req_handler($req);
ok $res->content, 'got content';
my $result = eval 'my '. $res->content.'; $VAR1'; # yeck
ok $result, 'deserialized ok';

isa_ok $result->{another_test_instance}, 'Test', 'another_test_instance';
isa_ok $result->{test_instance}, 'Test', 'test_instance';

is $result->{another_test_instance}->map_foo_bar('foo'), 'bar';

__DATA__
---
foo: "bar"
packages:
  Test:
    constructors: ["new"]
    methods:
      map_foo_bar:
        - ["foo"]
        - "bar"
        - ["bar"]
        - "foo"
        - "INVALID INPUT"
instantiate:
  test_instance: "Test"
  another_test_instance:
    Test: "new"
