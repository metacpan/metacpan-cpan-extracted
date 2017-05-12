use inc::Module::Install;

name     'Catalyst-Plugin-ErrorCatcher-ActiveMQ-Stomp';
all_from 'lib/Catalyst/Plugin/ErrorCatcher/ActiveMQ/Stomp.pm';
author   'Jason Tang <tang.jason.ch@gmail.com>';

build_requires 'Test::More';

requires(
    'Catalyst::Plugin::ErrorCatcher' => '0.0.7',
    'Data::Dump'                     => 0,
    'Data::Serializer'               => 0,
    'DateTime'                       => 0,
    'Fcntl'                          => 0,
    'File::Slurp'                    => 0,
    'Moose'                          => 0,
    'Moose::Util::TypeConstraints'   => 0,
    'MooseX::Types'                  => 0,
    'MooseX::Types::Moose'           => 0,
    'Net::Stomp'                     => '0.42',
    'Path::Class'                    => 0,
    'Path::Class::File'              => 0,
    'version'                        => 0,
);
auto_install;

WriteAll;

