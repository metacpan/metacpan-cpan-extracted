#!/usr/bin/perl

use common::sense;

use App::Office::CMS::Util::Config;
use App::Office::CMS::Database;

# --------------------------------------------------

sub pretty_print_node
{
	my($node, $opt) = @_;
	my($id) = ${$node -> attribute}{id} || '';

	print ' ' x $$opt{_depth}, $node -> name, " ($id)\n";

	return 1;

} # End of pretty_print_node.

# --------------------------------------------------

my($config) = App::Office::CMS::Util::Config -> new -> config;
my($db)     = App::Office::CMS::Database -> new(config => $config);
my($tree)   = $db -> menu -> get_menu_by_context('1/1');

$tree -> walk_down
	({
		callback => \&pretty_print_node,
		_depth   => 0,
	});
