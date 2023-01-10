use strict;
use warnings qw(all);
use v5.022;

use Test::More;

use Config::Structured;

my $def_file  = 't/conf/yml/definition.yml';
my $conf_file = 't/conf/yml/config.yml';

plan tests => 2;

my $conf = Config::Structured->new(structure => $def_file, config => $conf_file);
my $db   = $conf->db;

is_deeply([$conf->__get_child_node_names],    [qw(db)],             'Check child nodes at top level');
is_deeply([sort $db->__get_child_node_names], [sort qw(user pass)], 'Check deep child nodes');
