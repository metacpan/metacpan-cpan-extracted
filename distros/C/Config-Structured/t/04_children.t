use strict;
use warnings qw(all);
use v5.022;

use Test2::V0;

use Config::Structured;

my $def_file  = 't/conf/yml/definition.yml';
my $conf_file = 't/conf/yml/config.yml';

my $conf = Config::Structured->new(structure => $def_file, config => $conf_file);
my $db   = $conf->db;

is([$conf->__get_child_node_names],    [qw(db)],             'Check child nodes at top level');
is([sort $db->__get_child_node_names], [sort qw(user pass)], 'Check deep child nodes');

done_testing;
