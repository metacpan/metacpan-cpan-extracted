#
# This example walks the three non-recursively looking for simple additions which can be folded
#
#

use strict;
use DBIx::MyParse;
use DBIx::MyParse::Item;

my $parser = DBIx::MyParse->new( database => 'test' );
my $sql = "SELECT 1 + 2 + 3 + 4 + 5 FROM a WHERE 6 + 7 + 8 + 9 + 10";
my $query = $parser->parse($sql);
print "Old: ".$query->print()."\n";

# Optimize SELECT items
foreach my $select_item (@{$query->getSelectItems()}) {
	foreach my $level (1..(my $max_depth = 5)) {
		$select_item = optimize ($select_item);
	}
}

# Optimize WHERE
if (defined $query->getWhere()) { 
	foreach my $level (1..(my $max_depth = 5)) {
		$query->setWhere(optimize($query->getWhere()));
	}
}

print "New: ".$query->print()."\n";

sub optimize {
	my $new_item = my $orig_item = shift;
	return $orig_item if ($orig_item->getType() ne 'FUNC_ITEM') && ($orig_item->getType() ne 'COND_ITEM');
	if ($orig_item->getFuncName() eq '+') {
		my $left_item = $orig_item->getFirstArg();
		my $right_item = $orig_item->getSecondArg();
		if (
			($left_item->getType() eq 'INT_ITEM') &&
			($right_item->getType() eq 'INT_ITEM')
		) {
			$new_item = DBIx::MyParse::Item->newInt($left_item->getValue() + $right_item->getValue());
		}
	}

	map { $_ = optimize($_) } @{$orig_item->getArguments()} if $orig_item->hasArguments();

	return $new_item;
}
