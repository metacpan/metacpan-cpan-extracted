use inc::Module::Install;
name 'AnyMQ-AMQP';
all_from 'lib/AnyMQ/AMQP.pm';
readme_from 'lib/AnyMQ/AMQP.pm';
build_requires 'Test::More';

requires 'AnyMQ';
requires 'File::ShareDir';
requires 'JSON';
requires 'Try::Tiny';
requires 'AnyEvent::RabbitMQ' => 1.03;

auto_include_deps;
auto_set_repository;
extra_tests;

WriteAll;
