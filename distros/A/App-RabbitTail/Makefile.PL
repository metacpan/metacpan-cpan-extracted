use strict;
use warnings;
use inc::Module::Install;
#use Module::Install::AuthorRequires;
#use Module::Install::AuthorTests;

name 'App-RabbitTail';
all_from 'lib/App/RabbitTail.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'Net::RabbitFoot' => '1.03';
requires 'AnyEvent::RabbitMQ' => '1.03';
requires 'AnyEvent';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types';
requires 'Try::Tiny';
requires 'Moose::Autobox';

test_requires 'Test::More' => '0.88';

install_script 'script/rabbit_tail';

resources repository => 'git://github.com/bobtfish/App-RabbitTail.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/App/RabbitTail.pm > README")
        and die $!;
}

WriteAll;

