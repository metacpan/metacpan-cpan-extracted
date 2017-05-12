
use Test::More tests => 5;
use Symbol;
use XML::Compile;
use XML::Compile::Transport::SOAPHTTP;
BEGIN { use_ok('Catalyst::Model::SOAP') };

use lib 't/lib/';

{
    package MyFooModel;
    use base qw(Catalyst::Model::SOAP);
    __PACKAGE__->register_wsdl('t/hello.wsdl', 'Bar::Baz');
};

{
    package Catalyst::Model::SOAP::Instance;
    sub foo {
        return 'ok';
    }
};

ok(defined @MyFooModel::Bar::Baz::ISA, 'Loading the wsdl pre-registers the class.');
is(MyFooModel::Bar::Baz->foo(), 'ok', 'The dynamic class isa Catalyst::Model::SOAP::Instance.');
ok(defined &MyFooModel::Bar::Baz::Greet, 'Loading the wsdl pre-registers the method.');
ok(defined &MyFooModel::Bar::Baz::_Greet_data, 'Loading the wsdl pre-register the helper-method');
