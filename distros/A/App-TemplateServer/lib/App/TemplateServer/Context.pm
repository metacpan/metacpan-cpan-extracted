package App::TemplateServer::Context;
use Moose;

has 'server' => (
    is  => 'ro',
    isa => 'HTTP::Daemon',
);

has 'data' => (
    is  => 'ro',
    isa => 'HashRef',
);

has 'request' => (
    is  => 'ro',
    isa => 'HTTP::Request',
);

1;
