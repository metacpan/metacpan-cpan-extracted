#!/usr/bin/env perl
use inc::Module::Package 'Au:dry 1';
all_from        'lib/Convert/GeekCode.pm';
requires        'Text::Wrap';
requires        'YAML';
install_script  qw[ script/geekdec script/geekgen ];
