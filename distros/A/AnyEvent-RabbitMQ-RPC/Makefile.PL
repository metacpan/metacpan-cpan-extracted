use inc::Module::Install;

all_from 'lib/AnyEvent/RabbitMQ/RPC.pm';
requires 'AnyEvent::RabbitMQ';
requires 'Try::Tiny';

makemaker_args( MAN3PODS => {} ); # Don't write any man files
auto_install();
WriteAll;
