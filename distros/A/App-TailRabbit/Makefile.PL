use strict;
use warnings;
use inc::Module::Install;

name 'App-TailRabbit';
all_from 'lib/App/TailRabbit.pm';
requires 'JSON';
requires 'Try::Tiny';
requires 'Moose';
requires 'MooseX::Types::Moose';
requires 'namespace::autoclean';
requires 'MooseX::Getopt';
requires 'Net::RabbitFoot' => '1.03';
requires 'AnyEvent::RabbitMQ' => '1.03'; # FIXME - Should be required in Net::RabbitFoot
requires 'MooseX::Types::Common';
requires 'AnyEvent';
requires 'YAML';
requires 'File::HomeDir';
requires 'Path::Class';
requires 'MooseX::Types::LoadableClass';

test_requires 'Test::More' => '0.88';

install_script 'script/tail_rabbit';

resources repository => 'git://github.com/bobtfish/App-TailRabbit.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/App/TailRabbit.pm > README") and die $!;
}

WriteAll();

