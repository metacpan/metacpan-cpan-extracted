use strict;
use warnings;
use inc::Module::Install 0.91;

name 'CatalystX-Restarter-GTK';
all_from 'lib/CatalystX/Restarter/GTK.pm';

requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::autoclean';

requires 'Catalyst::Runtime' => '5.80032';
requires 'Catalyst::Devel';
requires 'Try::Tiny';
requires 'Object::Destroyer';
requires 'AnyEvent';
requires 'Gtk2';
requires 'IPC::SysV';
requires 'IO::Handle';

build_requires 'Test::More' => '0.88';

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/CatalystX-Restarter-GTK/trunk';

WriteAll();
