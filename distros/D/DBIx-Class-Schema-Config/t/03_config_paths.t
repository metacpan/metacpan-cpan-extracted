#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use base 'DBIx::Class::Schema::Config';
use File::HomeDir;

is_deeply(
    __PACKAGE__->config_paths,
    [ './dbic', File::HomeDir->my_home . "/.dbic", "/etc/dbic"  ],
    "_config_paths looks sane.");

__PACKAGE__->config_paths( [ ( './this', '/var/www/that' ) ] );

is_deeply(
    __PACKAGE__->config_paths,
    [ './this', '/var/www/that'  ],
    "_config_paths can be modified.");


done_testing;
