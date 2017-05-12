#
# This script detects expressions like
#
#
#	WHERE a REGEXP '^d'
#
# which will always match the start of the string, and converts them to
#
#	a REGEXP '^d' AND a LIKE 'b%'
#
# which enables the optimizer to use an index on `a` if one exists
#

use strict;
use DBIx::MyParse;
use DBIx::MyParse::Item;

my $sql = "SELECT a FROM b WHERE (c REGEXP '^d') AND (x = y)";
my $parser = DBIx::MyParse->new( database => 'test' );
my $query = $parser->parse($sql);
print "Old: ".$query->print()."\n";

my $where = $query->getWhere();
$query->setWhere(optimize($where)) if defined $where;

sub optimize {
	my $item = shift;

	# We are only interested in REGEXP and AND
	return $item if ($item->getType() ne 'FUNC_ITEM') && ($item->getType() ne 'COND_ITEM');
	
	if ($item->getFuncName() eq 'regexp') {
		my $param_item = $item->getFirstArg();
		my $regexp_item = $item->getSecondArg();
		if (
			($param_item->getType() eq 'FIELD_ITEM') &&
			($regexp_item->getType() eq 'STRING_ITEM') &&
			(my ($fixed) = $regexp_item->getValue() =~ m{^\^([\w ]+)}sio)
		) {
			return DBIx::MyParse::Item->newAnd(
				DBIx::MyParse::Item->newLike(
					$param_item,
					DBIx::MyParse::Item->newString($fixed.'%')
				),
				$item
			);
		} else {
			return $item;	# No optimization
		}
	} else {
		# Check if lower branches can be optimized
		map { $_ = optimize($_) } @{$item->getArguments()} if $item->hasArguments();
		return $item;
	}
}

print "New: ".$query->print()."\n";
