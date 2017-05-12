package TestApp::Component::Foo;
use Moose;
use MooseX::Orochi;
use namespace::autoclean;

bind_constructor 'component/foo' => (
    args => {
        foo => bind_value 'foo'
    }
);

has foo => ( is => 'ro', required => 1 );

__PACKAGE__->meta->make_immutable();

1;

