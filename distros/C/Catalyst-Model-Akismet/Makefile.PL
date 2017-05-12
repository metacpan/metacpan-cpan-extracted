use strict;
use warnings;
use inc::Module::Install 0.87;

name 'Catalyst-Model-Akismet';
all_from 'lib/Catalyst/Model/Akismet.pm';
license 'perl';

build_requires 'Test::More';

requires 'Carp';
requires 'Class::C3' => '0.20';
requires 'Catalyst::Runtime' => '5.70';
requires 'Catalyst::Component::InstancePerContext' => '0.001000';
requires 'Net::Akismet::Protocol';
requires 'Moose';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Model-Akismet/';

WriteAll;
