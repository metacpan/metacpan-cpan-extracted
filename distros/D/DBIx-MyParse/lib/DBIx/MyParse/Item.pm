package DBIx::MyParse::Item;

use strict;
use warnings;

our $VERSION = '0.88';

#
# If you change those constants, do not forget to change
# the corresponding C #defines in my_parse.h
#

use constant MYPARSE_ITEM_ITEM_TYPE	=> 0;
use constant MYPARSE_ITEM_ALIAS		=> 1;
# For functions
use constant MYPARSE_ITEM_FUNC_TYPE	=> 2;
use constant MYPARSE_ITEM_FUNC_NAME	=> 3;
use constant MYPARSE_ITEM_ARGUMENTS	=> 4;
# For literals
use constant MYPARSE_ITEM_VALUE		=> 2;
use constant MYPARSE_ITEM_CHARSET	=> 3;
# For fields and tables
use constant MYPARSE_ITEM_FIELD_NAME	=> 2;
use constant MYPARSE_ITEM_TABLE_NAME	=> 3;
use constant MYPARSE_ITEM_DB_NAME	=> 4;
use constant MYPARSE_ITEM_DIR		=> 5;
use constant MYPARSE_ITEM_USE_INDEX	=> 6;
use constant MYPARSE_ITEM_IGNORE_INDEX	=> 7;
use constant MYPARSE_ITEM_FORCE_INDEX	=> 8;
# For intervals
use constant MYPARSE_ITEM_INTERVAL	=> 2;
# For variables
use constant MYPARSE_ITEM_VAR_TYPE	=> 2;
use constant MYPARSE_ITEM_VAR_NAME	=> 3;
use constant MYPARSE_ITEM_VAR_COMPONENT => 4;
# For subselects
use constant MYPARSE_ITEM_SUBSELECT_TYPE	=> 2;
use constant MYPARSE_ITEM_SUBSELECT_EXPR	=> 3;
use constant MYPARSE_ITEM_SUBSELECT_COND	=> 4;
use constant MYPARSE_ITEM_SUBSELECT_QUERY	=> 5;
# For JOINs
use constant MYPARSE_ITEM_JOIN_TYPE	=> 2;
use constant MYPARSE_ITEM_JOIN_ITEMS	=> 3;
use constant MYPARSE_ITEM_JOIN_COND	=> 4;
use constant MYPARSE_ITEM_JOIN_FIELDS	=> 5;

# ====================

use constant FUNC_PLACEMENT_FRONT	=> 1;
use constant FUNC_PLACEMENT_MIDDLE	=> 2;
use constant FUNC_PLACEMENT_SPECIAL	=> 3;
use constant FUNC_PLACEMENT_UNKNOWN	=> 4;

my %func_placement = (
	'UNKNOWN_FUNC'		=> FUNC_PLACEMENT_FRONT,
	'EQ_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'EQUAL_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'NE_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'LT_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'LE_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'GE_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'GT_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'FT_FUNC'		=> FUNC_PLACEMENT_SPECIAL,	# FULL TEXT
	'LIKE_FUNC'		=> FUNC_PLACEMENT_SPECIAL,
	'ISNULL_FUNC'		=> FUNC_PLACEMENT_FRONT,
	'ISNOTNULL_FUNC'	=> FUNC_PLACEMENT_SPECIAL,
	'COND_AND_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'COND_OR_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'COND_XOR_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'BETWEEN'		=> FUNC_PLACEMENT_SPECIAL,
	'IN_FUNC'		=> FUNC_PLACEMENT_SPECIAL,
	'MULT_EQUAL_FUNC'	=> FUNC_PLACEMENT_MIDDLE,	# Does not occur during parsing
	'INTERVAL_FUNC'		=> FUNC_PLACEMENT_UNKNOWN,
	'ISNOTNULLTEST_FUNC'	=> FUNC_PLACEMENT_SPECIAL,
	'SP_EQUALS_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_DISJOINT_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_INTERSECTS_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_TOUCHES_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_CROSSES_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_WITHIN_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_CONTAINS_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_OVERLAPS_FUNC'	=> FUNC_PLACEMENT_FRONT,
	'SP_STARTPOINT'		=> FUNC_PLACEMENT_FRONT,
	'SP_ENDPOINT'		=> FUNC_PLACEMENT_FRONT,
	'SP_EXTERIORRING'	=> FUNC_PLACEMENT_FRONT,
	'SP_POINTN'		=> FUNC_PLACEMENT_FRONT,
	'SP_GEOMETRYN'		=> FUNC_PLACEMENT_FRONT,
	'SP_INTERIORRINGN'	=> FUNC_PLACEMENT_FRONT,
	'NOT_FUNC'		=> FUNC_PLACEMENT_FRONT,
	'NOT_ALL_FUNC'		=> FUNC_PLACEMENT_SPECIAL,	# Used in subqueries?
	'NOW_FUNC'		=> FUNC_PLACEMENT_FRONT,
	'TRIG_COND_FUNC'	=> FUNC_PLACEMENT_UNKNOWN,	# Internal use only
	'SUSERVAR_FUNC'		=> FUNC_PLACEMENT_SPECIAL,
	'GUSERVAR_FUNC'		=> FUNC_PLACEMENT_SPECIAL,
	'COLLATE_FUNC'		=> FUNC_PLACEMENT_MIDDLE,
	'EXTRACT_FUNC'		=> FUNC_PLACEMENT_SPECIAL,
	'CHAR_TYPECAST_FUNC'	=> FUNC_PLACEMENT_SPECIAL,
	'FUNC_SP'		=> FUNC_PLACEMENT_FRONT,
	'UDF_FUNC'		=> FUNC_PLACEMENT_FRONT
);

my %args = (
	item_type => MYPARSE_ITEM_ITEM_TYPE,
	alias	  => MYPARSE_ITEM_ALIAS,

	func_type => MYPARSE_ITEM_FUNC_TYPE,
	func_name => MYPARSE_ITEM_FUNC_NAME,
	arguments => MYPARSE_ITEM_ARGUMENTS,

	value	=> MYPARSE_ITEM_VALUE,
	charset => MYPARSE_ITEM_CHARSET,
	
	field_name => MYPARSE_ITEM_FIELD_NAME,
	table_name => MYPARSE_ITEM_TABLE_NAME,
	db_name		=> MYPARSE_ITEM_DB_NAME,
	dir		=> MYPARSE_ITEM_DIR,
	use_index => MYPARSE_ITEM_USE_INDEX,
	ignore_index => MYPARSE_ITEM_IGNORE_INDEX,
	force_index => MYPARSE_ITEM_FORCE_INDEX,
	
	interval => MYPARSE_ITEM_INTERVAL,
	
	var_name => MYPARSE_ITEM_VAR_NAME,
	var_component => MYPARSE_ITEM_VAR_COMPONENT,

	subselect_type => MYPARSE_ITEM_SUBSELECT_TYPE,
	subselect_expr => MYPARSE_ITEM_SUBSELECT_EXPR,
	subselect_cond => MYPARSE_ITEM_SUBSELECT_COND,
	subselect_query => MYPARSE_ITEM_SUBSELECT_QUERY,
	
	join_type => MYPARSE_ITEM_JOIN_TYPE,
	join_items => MYPARSE_ITEM_JOIN_ITEMS,
	join_cond => MYPARSE_ITEM_JOIN_COND,
	join_fields => MYPARSE_ITEM_JOIN_FIELDS
);

1;

sub new {
	my $class = shift;
	my $item = bless([], $class);

	my $max_arg = (scalar(@_) / 2) - 1;
	
	foreach my $i (0..$max_arg) {
		if (exists $args{$_[$i * 2]}) {
			$item->[$args{$_[$i * 2]}] = $_[$i * 2 + 1];
		} else {
			warn("Unkown argument '$_[$i * 2]' to $class"."::new()");
                }
        }
	return $item;
}

sub newNull {
	return $_[0]->new( item_type => 'NULL_ITEM' );
}

sub newString {
	return $_[0]->new( item_type => 'STRING_ITEM', value => $_[1] );
}

sub newVarbin {
	return $_[0]->new( item_type => 'VARBIN_ITEM', value => $_[1] );
}

sub newInt {
	return $_[0]->new( item_type => 'INT_ITEM', value => $_[1] );
}

sub newReal {
	return $_[0]->new( item_type => 'REAL_ITEM', value => $_[1] );
}

sub newField {
	return $_[0]->new( item_type => 'FIELD_ITEM', field_name => $_[1], table_name => $_[2], db_name => $_[3] );
}

sub newNot {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'NOT_FUNC', func_name => 'not', arguments => \@_ );
}

sub newAnd {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'COND_AND_FUNC', func_name => 'and', arguments => \@_ );
}

sub newOr {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'COND_OR_FUNC', func_name => 'or', arguments => \@_ );
}

sub newPlus {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'UNKNOWN_FUNC', func_name => '+', arguments => \@_ );
}

sub newMinus {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'UNKNOWN_FUNC', func_name => '-', arguments => \@_ );
}

sub newEq {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'EQ_FUNC', func_name => '=', arguments => \@_ );
}

sub newGt {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'GT_FUNC', func_name => '>', arguments => \@_ );
}
sub newLt {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'LT_FUNC', func_name => '<', arguments => \@_ );
}

sub newLike {
	my $class = shift;
	return $class->new( item_type => 'FUNC_ITEM', func_type => 'LIKE_FUNC', func_name => 'like', arguments => \@_ );
}

sub getItemType {
	return $_[0]->[MYPARSE_ITEM_ITEM_TYPE];
}

sub setItemType {
	$_[0]->[MYPARSE_ITEM_ITEM_TYPE] = $_[1];
}

sub getType {
	return $_[0]->[MYPARSE_ITEM_ITEM_TYPE];
}

sub setType {
	$_[0]->[MYPARSE_ITEM_ITEM_TYPE] = $_[1];
}

sub getAlias {
	return $_[0]->[MYPARSE_ITEM_ALIAS];
}

sub setAlias {
	$_[0]->[MYPARSE_ITEM_ALIAS] = $_[1];
}

sub getFuncType {
	my $item = shift;
	my $item_type = $item->[MYPARSE_ITEM_ITEM_TYPE];
	if (
		($item_type eq 'COND_ITEM') ||
		($item_type eq 'FUNC_ITEM') ||
		($item_type eq 'SUM_FUNC_ITEM')
	) {
		return $item->[MYPARSE_ITEM_FUNC_TYPE];
	} else {
		warn("getFuncType() called, but getType() = $item_type.");
		return undef;
	}
}

sub setFuncType {
	$_[0]->[MYPARSE_ITEM_FUNC_TYPE] = $_[1];
}

sub getFuncName {
	my $item = shift;
	my $item_type = $item->getItemType();
	if (
		($item_type eq 'COND_ITEM') ||
		($item_type eq 'FUNC_ITEM') ||
		($item_type eq 'SUM_FUNC_ITEM')
	) {
		return $item->[MYPARSE_ITEM_FUNC_NAME];
	} else {
		warn("getFuncName() called, but getType() = $item_type");
		return undef;
	}
}

sub setFuncName {
	$_[0]->[MYPARSE_ITEM_FUNC_NAME] = $_[1];

}

sub getArguments {
	my $item = shift;
	my $item_type = $item->getItemType();

	if (
		($item_type eq 'COND_ITEM') ||
		($item_type eq 'FUNC_ITEM') ||
		($item_type eq 'SUM_FUNC_ITEM') ||
		($item_type eq 'ROW_ITEM')
	) {
		return $item->[MYPARSE_ITEM_ARGUMENTS];
	} else {
		warn("getArguments() called, but getType() eq '$item_type'");
		return undef;
	}
}

sub hasArguments {
	return (defined $_[0]->[MYPARSE_ITEM_ARGUMENTS]);
}

sub getFirstArg {
	return $_[0]->getArguments()->[0];
}

sub getSecondArg {
	return $_[0]->getArguments()->[1];	
}

sub getThirdArg {
	return $_[0]->getArguments()->[2];	
}

sub setArguments {
	$_[0]->[MYPARSE_ITEM_ARGUMENTS] = $_[1];
}


sub getValue {
	my $item = shift;
	my $type = $item->getItemType();

	if ($type eq 'NULL_ITEM') {
		return undef;
	} elsif (
		($type eq 'STRING_ITEM') ||
		($type eq 'INT_ITEM') ||
		($type eq 'DECIMAL_ITEM') ||
		($type eq 'REAL_ITEM') ||
		($type eq 'VARBIN_ITEM')
	) {
		return $item->[MYPARSE_ITEM_VALUE];
	} else {
		warn("getValue() called, but getType() eq '$type'");
		return undef;
	}
}

sub setValue {
	$_[0]->[MYPARSE_ITEM_VALUE] = $_[1];
}

sub getCharset {
	my $item = shift;
	my $type = $item->getItemType();

	if (
		($type eq 'CHARSET_ITEM') ||
		($type eq 'STRING_ITEM') ||
		($type eq 'VARBIN_ITEM')
	) {
		return $item->[MYPARSE_ITEM_CHARSET];
	} else {
		warn("getCharset() called, but getType() eq '$type'");
		return undef;
	}	
}

sub setCharset {
	$_[0]->[MYPARSE_ITEM_CHARSET] = $_[1];
}

sub getFieldName {
	my $item = shift;
	my $item_type = $item->getType();

	if (
		($item_type eq 'FIELD_ITEM') ||
		($item_type eq 'REF_ITEM') ||
		($item_type eq 'DEFAULT_VALUE_ITEM')
	) {
		return $item->[MYPARSE_ITEM_FIELD_NAME];
	} else {
		warn("getFieldName() called, but getType() eq '$item_type'");
		return undef;
	}
}

sub setFieldName {
	return $_[0]->[MYPARSE_ITEM_FIELD_NAME] = $_[1];
}

sub getTableName {
	my $item = shift;
	my $item_type = $item->getType();
	if (
		($item_type eq 'FIELD_ITEM') ||
		($item_type eq 'REF_ITEM') ||
		($item_type eq 'DEFAULT_VALUE_ITEM') ||
		($item_type eq 'TABLE_ITEM')
	) {
		return $item->[MYPARSE_ITEM_TABLE_NAME];			
	} else {
		warn("getTableName() called, but getType() = $item_type.\n");
		return undef;
	}
}

sub setTableName {
	$_[0]->[MYPARSE_ITEM_TABLE_NAME] = $_[1];
}

sub getDatabaseName {
	my $item = shift;
	my $item_type = $item->getType();

	if (
		($item_type eq 'FIELD_ITEM') ||
		($item_type eq 'REF_ITEM') ||
		($item_type eq 'DEFAULT_VALUE_ITEM') ||
		($item_type eq 'TABLE_ITEM') ||
		($item_type eq 'DATABASE_ITEM')
	) {
		return $item->[MYPARSE_ITEM_DB_NAME];
	} else {
		warn("getDatabaseName() called, but getType() = $item_type.\n");
		return undef;
	}
}

sub setDatabaseName {
	$_[0]->[MYPARSE_ITEM_DB_NAME] = $_[1];
}

sub getDirection {	
	return $_[0]->[MYPARSE_ITEM_DIR];
}

sub setDirection {
	$_[0]->[MYPARSE_ITEM_DIR] = $_[1];
}

sub getDir {	
	return $_[0]->[MYPARSE_ITEM_DIR];
}

sub setDir {
	$_[0]->[MYPARSE_ITEM_DIR] = $_[1];	
}

sub getInterval {
	my $item = shift;
	if ($item->getType() eq 'INTERVAL_ITEM') {
		return $item->[MYPARSE_ITEM_INTERVAL];
	} else {
		warn("getInterval() called, but getType() ne 'INTERVAL_ITEM'");
	}
}

sub setInterval {
	$_[0]->[MYPARSE_ITEM_INTERVAL] = $_[1];
}

sub getVarName {
	my $item = shift;
	if (
		($item->getType() eq 'SYSTEM_VAR_ITEM') ||
		($item->getType() eq 'USER_VAR_ITEM')
	) {
		return $item->[MYPARSE_ITEM_VAR_NAME];
	} else {
		warn("getVarName() called, but getType() ne '*_VAR_ITEM'");
		return undef;
	}
}

sub setVarName {
	$_[0]->[MYPARSE_ITEM_VAR_NAME] = $_[1];
}

sub getVarType {
	my $item = shift;
	if (
		($item->getType() eq 'SYSTEM_VAR_ITEM') ||
		($item->getType() eq 'USER_VAR_ITEM')
	) {
		return $item->[MYPARSE_ITEM_VAR_TYPE];
	} else {
		warn("getVarType() called, but getItemType() ne '*_VAR_ITEM'");
		return undef;
	}
}

sub setVarType {
	$_[0]->[MYPARSE_ITEM_VAR_NAME] = $_[1];
}

sub getVarComponent {
	my $item = shift;
	if ($item->getType() eq 'SYSTEM_VAR_ITEM') {
		return $item->[MYPARSE_ITEM_VAR_COMPONENT];
	} else {
		warn("getVarComponent() called, but getType() ne 'SYSTEM_VAR_ITEM'");
		return undef;
	}
}

sub setVarComponent {
	$_[0]->[MYPARSE_ITEM_VAR_COMPONENT] = $_[1];
}

sub getSubselectType {
	my $item = shift;
	if ($item->getItemType() eq 'SUBSELECT_ITEM') {
		return $item->[MYPARSE_ITEM_SUBSELECT_TYPE];
	} else {
		warn("getSubselectType() called, but getItemType() ne 'SUBSELECT_ITEM'");
	}
}

sub setSubselectType {
	$_[0]->[MYPARSE_ITEM_SUBSELECT_TYPE] = $_[1];
}

sub getSubselectExpr {
	my $item = shift;
	if ($item->getItemType() eq 'SUBSELECT_ITEM') {
		return $item->[MYPARSE_ITEM_SUBSELECT_EXPR];
	} else {
		warn("getSubselectExpr() called, but getItemType() ne 'SUBSELECT_ITEM'");
	}
}

sub setSubselectExpr {
	$_[0]->[MYPARSE_ITEM_SUBSELECT_EXPR] = $_[1];
}

sub getSubselectCond {
	my $item = shift;
	if ($item->getItemType() eq 'SUBSELECT_ITEM') {
		return $item->[MYPARSE_ITEM_SUBSELECT_COND];
	} else {
		warn("getSubselectCond() called, but getItemType() ne 'SUBSELECT_ITEM'");
	}
}

sub setSubselectCond {
	$_[0]->[MYPARSE_ITEM_SUBSELECT_COND] = $_[1];
}

sub getSubselectQuery {
	my $item = shift;
	if ($item->getItemType() eq 'SUBSELECT_ITEM') {
		return $item->[MYPARSE_ITEM_SUBSELECT_QUERY];
	} else {
		warn("getSubselectQuery() called, but getItemType() ne 'SUBSELECT_ITEM'");
	}
}

sub setSubselectQuery {
	$_[0]->[MYPARSE_ITEM_SUBSELECT_QUERY] = $_[1];
}


sub getJoinCond {
	return $_[0]->getJoinCondition();
}

sub setJoinCond {
	$_[0]->[MYPARSE_ITEM_JOIN_COND] = $_[1];
}

sub getJoinCondition {
	my $item = shift;
	if ($item->getType() eq 'JOIN_ITEM') {
		return $item->[MYPARSE_ITEM_JOIN_COND];
	} else {
		warn("getJoinCondition() called, but getType() ne 'JOIN_ITEM'");
		return undef;
	}
}

sub setJoinCondition {
	$_[0]->[MYPARSE_ITEM_JOIN_COND] = $_[1];
}

sub getJoinItems {
	my $item = shift;
	if ($item->getType() eq 'JOIN_ITEM') {
		return $item->[MYPARSE_ITEM_JOIN_ITEMS];
	} else {
		warn("getJoinItems() called, but getType() ne 'JOIN_ITEM'");
		return undef;
	}
}

sub setJoinItems {
	$_[0]->[MYPARSE_ITEM_JOIN_ITEMS] = $_[1];

}

sub getJoinFields {
	my $item = shift;
	if ($item->getType eq 'JOIN_ITEM') {
		return $item->[MYPARSE_ITEM_JOIN_FIELDS];
	} else {
		warn("getJoinFields() called, but getType() ne 'JOIN_ITEM'");
		return undef;
	}
}

sub setJoinFields {
	$_[0]->[MYPARSE_ITEM_JOIN_FIELDS] = $_[1];
}

sub getJoinType {
	my $item = shift;
	if ($item->getType() eq 'JOIN_ITEM') {
		return $item->[MYPARSE_ITEM_JOIN_TYPE];
	} else {
		warn("getJoinType() called, but getType() ne 'JOIN_ITEM'");
		return undef;
	}
}

sub setJoinType {
	$_[0]->[MYPARSE_ITEM_JOIN_TYPE] = $_[1];
}

sub getUseIndex {
	return $_[0]->[MYPARSE_ITEM_USE_INDEX];
}

sub setUseIndex {
	$_[0]->[MYPARSE_ITEM_USE_INDEX] = $_[1];
}

sub getIgnoreIndex {
	return $_[0]->[MYPARSE_ITEM_IGNORE_INDEX];
}

sub setIgnoreIndex {
	$_[0]->[MYPARSE_ITEM_IGNORE_INDEX] = $_[1];
}

sub getForceIndex {
	return $_[0]->[MYPARSE_ITEM_FORCE_INDEX];
}

sub setForceIndex {
	$_[0]->[MYPARSE_ITEM_FORCE_INDEX] = $_[1];
}

sub print {
	my ($item, $print_alias) = @_;

	my $type = $item->getType();
	
	my $printed;
	if (ref($item) eq 'DBIx::MyParse::Query') {
		return "(".$item->print().")";
	} elsif (
		($type eq 'INT_ITEM') ||
		($type eq 'DECIMAL_ITEM')
	) {
		$printed = $item->getValue();
	} elsif ($type eq 'STRING_ITEM') {
		$printed = $item->getValue();
		$printed =~ s{\\}{\\\\}sgio;
		$printed =~ s{'}{\\'}sgio;
		$printed =~ s{"}{\\"}sgio;
		$printed =~ s{\0}{\\0}sgio;
		$printed = "'".$printed."'";
		$printed = '_'.$item->getCharset().' '.$printed if defined $item->getCharset();
	} elsif (
		($type eq 'FIELD_ITEM') ||
		($type eq 'REF_ITEM') ||
		($type eq 'DEFAULT_VALUE_ITEM')
	) {
		$printed = $item->getFieldName() if defined $item->getFieldName();
		$printed = '`'.$printed.'`' if defined $printed && $printed ne '*';
		if (defined $item->getTableName()) {
			$printed = '`'.$item->getTableName().'`.'.$printed;
			$printed = '`'.$item->getDatabaseName().'`.'.$printed if defined $item->getDatabaseName();
		}
		if ($type eq 'DEFAULT_VALUE_ITEM') {
			if (defined $printed) {
				$printed = 'DEFAULT('.$printed.')';
			} else {
				$printed = 'DEFAULT';
			}
		}
	} elsif ($type eq 'TABLE_ITEM') {
		return $item->_printTable($print_alias);
	} elsif ($type eq 'DATABASE_ITEM') {
		$printed = '`'.$item->getDatabaseName().'`';
	} elsif ($type eq 'NULL_ITEM') {
		$printed = 'NULL';
	} elsif ($type eq 'PARAM_ITEM') {
		$printed = '?';
	} elsif ($type eq 'FUNC_ITEM') {
		$printed = $item->_printFunc();
	} elsif ($type eq 'SUM_FUNC_ITEM') {
		my $sum_func_name = $item->getFuncName();
		my $args = $item->getArguments();
		my $arg_string = join(", ", map {$_->print()} @{$args}) if defined $args->[0];
		if ($sum_func_name eq 'group_concat') {	
			$printed = $sum_func_name.'('.$arg_string.')';
		} else {
			$printed = $sum_func_name.$arg_string.')';
		}
	} elsif ($type eq 'COND_ITEM') {
		my $cond_name = $item->getFuncName();
		my $args = $item->getArguments();
		if (scalar(@{$args}) == 1) {
			my $arg1 = $args->[0]->print();
			$printed =  "($cond_name($arg1))";
		} elsif (scalar(@{$args}) > 1) {
			$printed = "(".join(" $cond_name ", map {$_->print()} @{$args}).")";
		}
	} elsif ($type eq 'VARBIN_ITEM') {
		foreach (split('',$item->getValue())) {
			$printed .= sprintf('%2.2x',ord($_));
		}
		$printed = '0x'.$printed;
	} elsif ($type eq 'REAL_ITEM') {
		$printed = $item->getValue().'e0';
	} elsif ($type eq 'INTERVAL_ITEM') {
		$printed = $item->getInterval();
		$printed =~ s{^INTERVAL_}{}sio;
	} elsif ($type eq 'SYSTEM_VAR_ITEM') {
		my $component = $item->getVarComponent();
		if (defined $component) {
			$printed = "@@".$component.'.'.$item->getVarName();
		} else {
			$printed = "@@".$item->getVarName();
		}
	} elsif ($type eq 'USER_VAR_ITEM') {
		$printed = "@".$item->getVarName();
	} elsif ($type eq 'SUBSELECT_ITEM') {
		my $subs_type = $item->getSubselectType();
		my $subs_expr = $item->getSubselectExpr();
		my $subs_cond = $item->getSubselectCond();
		my $subs_query = $item->getSubselectQuery();
		my $subs_query_printed = $subs_query->print();

		if (not defined $subs_type) {
			$printed = "(".$subs_query_printed.")";
		} elsif	($subs_type eq 'SINGLEROW_SUBS') {
			$printed = "(".$subs_query_printed.")";
		} elsif ($subs_type eq 'IN_SUBS') {
			$printed = $subs_expr->print()." IN (".$subs_query_printed.")";
		} elsif ($subs_type eq 'EXISTS_SUBS') {
			$printed = "EXISTS (".$subs_query_printed.")";
		} elsif ($subs_type eq 'ANY_SUBS') {
			$printed = $subs_expr->print()." ".$subs_cond." ANY (".$subs_query_printed.")";
		} elsif ($subs_type eq 'ALL_SUBS') {
			$printed = $subs_expr->print()." ".$subs_cond." ALL (".$subs_query_printed.")";
		} else {
			warn("unknown subselect type $subs_type");
			return undef;
		}
	} elsif ($type eq 'JOIN_ITEM') {
		return $item->_printJoin();
	} elsif ($type eq 'ROW_ITEM') {
		my $args = $item->getArguments();
		$printed = "(".join(", ", map {$_->print()} @{$args}).")";
	} elsif ($type eq 'CHARSET_ITEM') {
		$printed = $item->getCharset();
	} else {
		warn("item is $type, can not print");
	}

	$printed .= " AS `".$item->getAlias().'`' if (defined $print_alias) && (defined $item->getAlias());

	return $printed;
}

sub _printTable {
	my ($item, $print_alias) = @_;

	my $printed;
	$printed = '`'.$item->getTableName().'`';
	$printed = '`'.$item->getDatabaseName().'`.'.$printed if defined $item->getDatabaseName();
	$printed .= " AS `".$item->getAlias().'`' if $print_alias && defined $item->getAlias() && $item->getAlias() ne $item->getTableName();
	$printed .= " USE INDEX (".join(', ', @{$item->getUseIndex()}).")" if defined $item->getUseIndex();
	$printed .= " IGNORE INDEX (".join(', ', @{$item->getIgnoreIndex()}).")" if defined $item->getIgnoreIndex();
	$printed .= " FORCE INDEX (".join(', ', @{$item->getForceIndex()}).")" if defined $item->getForceIndex();
	return $printed;
	
}

sub _printFunc {
	my $item = shift;
	my $func_type = $item->getFuncType();
	my $func_name = $item->getFuncName();

	my $args = $item->getArguments();
	my $func_placement = $func_placement{$func_type};

	if (
		($func_name eq 'add_time') ||
		($func_name eq 'sub_time')
	) {
		$func_name =~ s{_}{}sgio;
	}

	if (my ($cast_type) = $func_name =~ m{^cast_as_(.*)}sio) {
		if (defined $args->[1]) {
			return "CAST(".$args->[0]->print()." AS ".uc($cast_type)."(".$args->[1]->getValue()."))";
		} else {
			return "CAST(".$args->[0]->print()." AS ".uc($cast_type).")";
		}
	} elsif ($func_name eq 'DIV') {
		return $args->[0]->print()." div ".$args->[1]->print();
	} elsif ($func_name eq 'decimal_typecast') {
		return "CAST(".$args->[0]->print()." AS DECIMAL)";
	} elsif ($func_name eq 'convert') {
		if (defined $args->[1]) {
			return "CONVERT(".$args->[0]->print()." USING ".$args->[1]->print().")";
		}
	} elsif (
		($func_name eq 'date_add_interval') ||
		($func_name eq 'date_sub_interval')
	) {
		my $real_name = $func_name;
		$real_name =~ s{_interval$}{}sio;
		return "$real_name(".$args->[0]->print().", INTERVAL ".$args->[1]->print()." ".$args->[2]->print().")";
	} elsif ($func_name eq 'case') {
		my @args = @{$args};
		my $case;
		while (my ($left, $right) = splice(@args,0,2)) {
			if (defined $right) {
				$case .= " WHEN ".$left->print()." THEN ".$right->print();
			} else {
				$case .= " ELSE ".$left->print();
			}
		}
		return "CASE ".$case." END";
	} elsif ($func_name eq 'case_switch') {
		my @args = @{$args};

		my $last_arg = pop(@args) if ($#args+1) % 2 == 0;
		my $first_arg = pop(@args);

		my $case;
		while (my ($left, $right) = splice(@args,0,2)) {
			$case .= " WHEN ".$left->print()." THEN ".$right->print();
		}

		if (defined $last_arg) {
			return "CASE ".$first_arg->print()." ".$case." ELSE ".$last_arg->print()." END";
		} else {
			return "CASE ".$first_arg->print()." ".$case." END";
		}
	} elsif ($func_name eq 'regexp') {
		return "(".$args->[0]->print()." REGEXP ".$args->[1]->print().")";
	} elsif ($func_name eq 'get_system_var') {
		return $args->[0]->print();
	} elsif (
			($func_name eq 'timestampadd') ||
			($func_name eq 'timestampdiff')
	) {
		my $first_arg = $args->[0]->print();
		$first_arg = 'FRAC_SECOND' if $first_arg eq 'MICROSECOND';
		return $func_name."(".$first_arg.", ".$args->[1]->print().", ".$args->[2]->print().")";
	} elsif (
		($func_type eq 'UNKNOWN_FUNC') && 
		($func_name =~ m{[^A-Za-z0-9_]}so)
	) {
		my @args = @{$args};
		if ($#args == 0) {
			return "(".$func_name." ".$args[0]->print()." )";
		} else {
			return "(".join($func_name, map { " ".$_->print()." "} @{$args}).")"
		}
	} elsif ($func_placement == FUNC_PLACEMENT_FRONT) {
		return $func_name."(".join(', ', map { $_->print() } @{$args}).")";
	} elsif ($func_placement == FUNC_PLACEMENT_MIDDLE) {
		return "(".join($func_name, map { " ".$_->print()." "} @{$args}).")"
	} elsif ($func_placement != FUNC_PLACEMENT_SPECIAL) {
		warn("Unknown function $func_type $func_name, can not print().");
		return undef;	
	}

	if (
		($func_type eq 'ISNOTNULL_FUNC') ||
		($func_type eq 'ISNOTNULLTEST_FUNC')
	) {
		return $args->[0]->print()." IS NOT NULL";
	} elsif ($func_type eq 'BETWEEN') {
		if (uc($func_name) eq 'BETWEEN') {
			return "(".$args->[0]->print()." BETWEEN ".$args->[1]->print()." AND ".$args->[2]->print().")";
		} elsif ($func_name eq 'NOT_BETWEEN') {
			return "(".$args->[0]->print()." NOT BETWEEN ".$args->[1]->print()." AND ".$args->[2]->print().")";
		}
	} elsif ($func_type eq 'IN_FUNC') {
		my @args = @{$args};
		my $first_arg = shift @args;
		return $first_arg->print()." IN(".join(',', map {$_->print()} @args).")";
	} elsif ($func_type eq 'NOT_IN_FUNC') {
		my @args = @{$args};
		my $first_arg = shift @args;
		return $first_arg->print()." NOT IN(".join(',', map {$_->print()} @args).")";
	} elsif ($func_type eq 'FT_FUNC') {
		my @args = @{$args};
		my $first_arg = shift @args;
		return "MATCH(".join(',',map {$_->print()} @args).") AGAINST (".$first_arg->print().")";
	} elsif ($func_type eq 'GUSERVAR_FUNC') {
		return $args->[0]->print();
	} elsif ($func_type eq 'SUSERVAR_FUNC') {
		return $args->[0]->print()." := ".$args->[1]->print();
	} elsif ($func_type eq 'NOT_ALL_FUNC') {
		return $args->[0]->print();
	} elsif ($func_type eq 'EXTRACT_FUNC') {
		return "EXTRACT(".$args->[0]->print()." FROM ".$args->[1]->print().")";
	} elsif ($func_type eq 'LIKE_FUNC') {
		if (defined $args->[2]) {
			return "(".$args->[0]->print()." LIKE ".$args->[1]->print()." ESCAPE ".$args->[2]->print().")";
		} else {
			return "(".$args->[0]->print()." LIKE ".$args->[1]->print().")";
		}
	} else {
		warn("Unknown function $func_type $func_name, can not print().");
		return undef;
	}
}

sub _printJoin {

	my $item = shift;

	my $join_items = $item->getJoinItems();
	if (not defined $join_items) {
		return "";
	}

	my @tables = @{$join_items};

	my $output;

	for (my $i = 0; $i <= $#tables; $i++) {

		my $this_table = $tables[$i];
		my $join_type = $item->getJoinType();
		my $this_table_print = $this_table->print();

		my $join_condition;
		$join_condition = " ON (".$item->getJoinCondition()->print().")" if defined $item->getJoinCondition();
		$join_condition = " USING (".join(', ', map { $_->print() } @{$item->getJoinFields()}).")" if defined $item->getJoinFields();

		if (not defined $join_type) {
			if ($i > 0) {
				$output .= ' INNER JOIN '.$this_table_print;
				$output .= $join_condition if (defined $join_condition);
			} else {
				$output .= $this_table_print;
			}
			next;
		}

		$i++;
		my $next_table = $tables[$i];
		my $next_table_print = $next_table->print();

		if ($join_type eq 'JOIN_TYPE_LEFT') {
			if (defined $join_condition) {
				$output .= $this_table_print." LEFT JOIN ".$next_table_print;
			} else {
				$output .= $this_table_print." NATURAL LEFT JOIN ".$next_table_print;
			}
		} elsif ($join_type eq 'JOIN_TYPE_RIGHT') {
			if (defined $join_condition) {
				$output .= $next_table_print." RIGHT JOIN ".$this_table_print;
			} else {
				$output .= $next_table_print." NATURAL RIGHT JOIN ".$this_table_print;
			}
		} elsif ($join_type eq 'JOIN_TYPE_STRAIGHT') {
			$output .= $this_table_print." STRAIGHT_JOIN ".$next_table_print;
		} elsif ($join_type eq 'JOIN_TYPE_NATURAL') {
			if (defined $join_condition) {
				$output .= $this_table_print." INNER JOIN ".$next_table_print;
			} else {
				$output .= $this_table_print." NATURAL JOIN ".$next_table_print;
			}
		}

		$output .= $join_condition if defined $join_condition;
	}
	
	return "(".$output.")";
}

1;

__END__

=head1 NAME

DBIx::MyParse::Item - Accessing the items from a C<DBIx::MyParse::Query> parse tree

=head1 SYNOPSIS

	use DBIx::MyParse;
	use DBIx::MyParse::Query;
	use DBIx::MyParse::Item;

	my $parser = DBIx::MyParse->new();
	my $query = $parser->parse("SELECT field_name FROM table_name");
	my $item_list = $query->getSelectItems();
	my $first_item = $item_list->[0];
	print $first_item->getItemType();	# Prints "FIELD_ITEM"
	print $first_item->getFieldName()	# Prints "field_name"

	$first_item->getFieldName('another_field');
	my $new_item_sql = $first_item->print();# Reconstructs the item as SQL
	my $new_query_sql = $query->print();	# Reconstructs entire query

	my $one = DBIx::MyParser->newInt(1);
	my $pi = DBIx::MyParse->newReal(3.14);
	my $sum = DBIx::MyParse->newPlus($one, $pi);
	my $sum_sql = $sum->print();


=head1 DESCRIPTION

MySQL uses a few dozen Item objects to store the various nodes possible in a
parse tree. For the sake of simplicity, we only use a single object type
in Perl to represent the same information.

=head1 CREATING, MODIFYING AND PRINTING ITEM OBJECTS

Item objects can be constructed from scratch using C<new()>. The arguments available to the constructor can be seen in
the C<%args> hash in C<Item.pm>.

For any C<get> function described below, a C<set()> function is available to modify the object.

You can call C<print()> on an C<DBIx::MyParse::Item> object to print an item. Passing C<1> as an argument to C<print()>
will cause the C<getAlias()>, if any, to be appended to the output with an C<AS> SQL clause.

The following convenience functions are available to create the simplest Item types: C<newNull()>, C<newInt($integer)>,
C<newString($string)>, C<newReal($number)>, C<newVarbin($data)>. Field items can be created usind
C<newField($field_name, $table, $database)>.

Additions, substractions can be created using C<newPlus($arg1, $arg2)>, C<newMinus($arg1, $arg2)>.
ORs, ANDs and NOTs can be created using C<newAnd($arg1, $arg2)>, C<newOr($arg1, $arg2)>, and C<newNot($arg)>.
Equations and inequalities can be created using C<newEq($arg1, $arg2)>, C<newGt($arg1, $arg2)> and C<newLt($arg1, $arg2)>.

=head1 METHODS

=over 4

=item C<getItemType()>

This returns the type of the C<Item> as a string, to facilitate dumping and debugging.

	if ($item->getItemType() eq 'FIELD_ITEM') { ... }	# Correct
	if ($item->getItemType() == FIELD_ITEM) { ... }	# Will not work

Some values are listed in C<enum Type> in F<sql/item.h> in the MySQL source.

	enum Type {FIELD_ITEM, FUNC_ITEM, SUM_FUNC_ITEM, STRING_ITEM,
		INT_ITEM, REAL_ITEM, NULL_ITEM, VARBIN_ITEM,
		COPY_STR_ITEM, FIELD_AVG_ITEM, DEFAULT_VALUE_ITEM,
		PROC_ITEM,COND_ITEM, REF_ITEM, FIELD_STD_ITEM,
		FIELD_VARIANCE_ITEM, INSERT_VALUE_ITEM,
		SUBSELECT_ITEM, ROW_ITEM, CACHE_ITEM, TYPE_HOLDER,
		PARAM_ITEM
	};

From those, the following are explicitly supported and are likely to occur during parsing:

	'FIELD_ITEM',
	'FUNC_ITEM', 'SUM_FUNC_ITEM',
	'STRING_ITEM', 'INT_ITEM', 'DECIMAL_ITEM', 'NULL_ITEM', 'REAL_ITEM'
	'REF_ITEM', 'COND_ITEM', 'PARAM_ITEM', 'VARBIN_ITEM', 'DEFAULT_VALUE_ITEM'
	'ROW_ITEM'

In addition, L<DBIx::MyParse> defines its own C<TABLE_ITEM> in case a table,
rather than a field, is being referenced. C<DATABASE_ITEM> may also be returned.

C<REF_ITEM> is a C<FIELD_ITEM> that is used in a C<HAVING> clause.
C<VARBIN_ITEM> is created when a Hex value is passed to MySQL (e.g. 0x5061756c).
C<PARAM_ITEM> is a ?-style placeholder.
All decimal values are returned as C<DECIMAL_ITEM>. C<REAL_ITEM> is only returned
if you use exponential notation (e.g. C<3.14e1>).
C<INTERVAL_ITEM> is returned as an argument to some date and time functions.
C<CHARSET_ITEM> is returned as an argument to some cast functions.
C<JOIN_ITEM> is returned for joins.

=item C<getAlias()>

Returns the name of the Item if provided with an AS clause, such as SELECT field AS alias. If no AS clause is present,
than (sort of) the SQL that produced the Item is returned. This is the same string that the mysql client would show
as column headings if you execute the query manually.

=over

=head1 FUNCTIONS

C<'FUNC_ITEM'> and C<'SUM_FUNC_ITEM'> denote functions in the parse tree.

=item C<getFuncType()>

if C<getType() eq 'FUNC_ITEM'>, you can call C<getFuncType()> to determine what type of
function it is. For MySQL, all operators are also of type C<FUNC_ITEM>.

The possible values are again strings (see above) and are listed in F<sql/item_func.h> under C<enum Functype>

	enum Functype {
		UNKNOWN_FUNC,EQ_FUNC,EQUAL_FUNC,NE_FUNC,LT_FUNC,LE_FUNC,
		GE_FUNC,GT_FUNC,FT_FUNC,
		LIKE_FUNC,NOTLIKE_FUNC,ISNULL_FUNC,ISNOTNULL_FUNC,
		COND_AND_FUNC, COND_OR_FUNC, COND_XOR_FUNC, BETWEEN, IN_FUNC,
		INTERVAL_FUNC, ISNOTNULLTEST_FUNC,
		SP_EQUALS_FUNC, SP_DISJOINT_FUNC,SP_INTERSECTS_FUNC,
		SP_TOUCHES_FUNC,SP_CROSSES_FUNC,SP_WITHIN_FUNC,
		SP_CONTAINS_FUNC,SP_OVERLAPS_FUNC,
		SP_STARTPOINT,SP_ENDPOINT,SP_EXTERIORRING,
		SP_POINTN,SP_GEOMETRYN,SP_INTERIORRINGN,
		NOT_FUNC, NOT_ALL_FUNC, NOW_FUNC, VAR_VALUE_FUNC
	};

if C<getType() eq 'SUM_FUNC_ITEM'>, C<getFuncType()> can be any of the aggregate functions listed
in enum Sumfunctype in F<sql/item_sum.h>:

	enum Sumfunctype {
		COUNT_FUNC,COUNT_DISTINCT_FUNC,SUM_FUNC, SUM_DISTINCT_FUNC, AVG_FUNC,MIN_FUNC,
		MAX_FUNC,UNIQUE_USERS_FUNC,STD_FUNC,VARIANCE_FUNC,SUM_BIT_FUNC,
		UDF_SUM_FUNC,GROUP_CONCAT_FUNC
	};

For MySQL, all functions not specifically listed above are C<UNKNOWN_FUNC> and you must call C<getFuncName()>. This may
include both general-purpose functions and user-defined ones.

=item C<getFuncName()>

Returns the name of the function called, such as C<"concat_ws">, C<"md5">, etc. If the C<Item> is not a function,
but an operator, the symbol of the operator is returned, such as C<'+'> or C<'||'>. The name of the function
will be lowercase regardless of the orginal case in the SQL string.

=item C<getArguments()>

Returns a reference to an array containing all the arguments to the function/operator. Each item from
the array is an DBIx::MyParse::Item object, even if it is a simple string or a field name.

C<hasArguments()>, C<getFirstArg()>, C<getSecondArg()> and C<getThirdArg()> are provided for convenience
and to increase code readibility.

=over

=head2 SPECIAL FUNCTIONS

Some functions are not entirely supported by L<DBIx::MyParse>, e.g. some fancy arguments may be missing from the
parse tree. Unfortunately, there is no way to know if you are missing any arguments. For a list of the currently
problematic functions, see L<DBIx::MyParse>.

The functions below are fully supported, however there are oddities you need to have in mind:

=item C<CAST(expr AS type (length))>, C<CONVERT(expr, type)>, C<SELECT BINARY expr>

C<getFuncName()> will return C<'cast_as_signed'>, C<'cast_as_unsigned'>, C<'cast_as_binary'>, C<'cast_as_char'>,
C<'cast_as_date'>, C<'cast_as_time'>, or C<'cast_as_datetime'>.

The thing being C<CAST>'ed will be returned as the first array item from C<getArguments()>. If there is a C<length>,
it will be returned as the second argument.

For C<CAST(expr AS DECIMAL)>, C<getFuncName()> will return C<'decimal_typecast'>.

=item C<CONVERT(expr USING charset)>

C<getFuncName()> will return C<'convert'>. The second item returned by C<getArguments()> will be of type C<'CHARSET_ITEM'>
and you can call C<getCharset()> on it.

=item C<DATE_ADD()> and C<DATE_SUB()>

C<getFuncName()> will return C<'get_add_interval'> and C<'get_sub_interval'> respectively. The second item returned by
C<getArguments()> will show the quantity of intervals that are to be added or substrated. This can be an C<'INT_ITEM'> for
round interval and C<'STRING_ITEM'> for partial intervals, e.g. C<'5.55' MINUTE>.

The last argument will be of type C<'INTERVAL_ITEM'> and you can call C<getInterval()> on it to determine the actual
interval being used. A string will be returned, as listed on the table in section 12.5 of the MySQL manual, except that
all strings are returned prefixed with C<'INTERVAL_'> e.g. a day interval will be returned at C<'INTERVAL_DAY'> and not
just C<'DAY'>.

=item C<ADDTIME()> and C<SUBTIME()>

C<getFuncName()> will return C<'add_time'> and C<'sub_time'> respectively, that is, with an underscore between the two words.

=item C<CASE WHEN condition THEN result1 ELSE result2 END>

For this form of C<CASE>, C<getFuncName()> will return C<'case'>. If C<getArguments()> returns an odd number of arguments,
this means that an C<ELSE result2> clause is present, and it will be the last argument.

=item C<CASE value WHEN compare_value THEN result ELSE result2 END>

For this form of C<CASE>, C<getFuncName()> will return C<'case_switch'>. If C<getArguments()> returns an even number of
arguments, this means that an C<ELSE result2> clause is present, and it will be the last argument. The C<value> you
are comparing against will be the last argument once you have C<pop>-ed out the C<ELSE result2> clause, if present.

=item C<expr IS NULL> and C<expr IS NOT NULL>

C<getFuncType()> will return either C<'ISNULL_FUNC'> or C<'ISNOTNULL_FUNC'>

=item C<expr BETWEEN value AND value> and C<expr NOT BETWEEN value AND value>

C<getFuncType()> will return C<'BETWEEN'>. C<getFuncName()> will return C<'BETWEEN'> or C<'NOT_BETWEEN'>, however the
case of the letters in C<'BETWEEN'> can vary.

=item C<expr IN (list)> and C<expr NOT IN (list)>

C<getFuncType()> will return either C<'IN_FUNC'> or C<'NOT_IN_FUNC'>. The first argument is the value you are examining,
the rest are the values you are comparing against. If C<list> contains just one value, MySQL will internally convert
the entire expression to a simle equality or inequality.

=item C<MATCH(list) AGAINST (expr)>

C<getFuncType()> will return C<'FT_FUNC'>. The thing you are looking for, C<expr> will be the first item from the
argument list. The rest of the arguments will be of type C<'FIELD_ITEM'>.

=item C<expr LIKE expr ESCAPE string>

C<getFuncType()> will return C<'LIKE_FUNC'>. If an escape string is defined, it will appear as the third argument
of the function.

=item C<SELECT @user_var>

C<getFuncType()> will return C<'GUSERVAR_FUNC'>. The first argument will be an Item of type C<'USER_VAR_ITEM'>.
Call C<getVarName()> on it to obtain the name of the user variable (without the leading @)

=item C<SELECT @user_var := value>

C<getFuncType()> will return C<'SUSERVAR_FUNC'>. The first argument will be of type C<'USER_VAR_ITEM'>. The second one will
contain the value being assigned.

=item C<SELECT @@component.system_var>

C<getFuncName()> will return C<'get_system_var'>. The first argument will be of type C<'SYSTEM_VAR_ITEM'>. You can
call C<getVarComponent()> to obtain the component name and C<getVarName()> to obtain the name of the variable. See
section "5.2.4.1. Structured System Variables" in the MySQL manual.

# =not_all_func

=over


=head1 LITERAL VALUES

For C<'STRING_ITEM'>, C<'INT_ITEM'>, C<'DECIMAL_ITEM'>, C<'REAL_ITEM'> and C<'VARBIN_ITEM'> you can call C<getValue()>.
Please note that the value of C<'VARBIN_ITEM'> is returned in a binary form, not as an integer or a hex string. This is
consistent with the behavoir of C<SELECT 0x4D7953514C>, which returns C<'MySQL'>.

You can also call C<'getCharset()'> to obtain the charset used for a particular string, if one was specified explicitly.

=head1 FIELDS, TABLES and DATABASES

=item C<getDatabaseName()>

if $item is FIELD_ITEM, REF_ITEM or a TABLE_ITEM, getDatabaseName() returns the database the field belongs to,
if it was explicitly specified. If it was not specified explicitly, such as was given previously with a
"USE DATABASE" command, getDatabaseName() will return undef. This may change in the future if we
incorporate some more of MySQL's logic that resolves table names.

=item C<getTableName()>

Returns the name of the table for a FIELD_ITEM or TABLE_ITEM object. For FIELD_ITEM, the table name must be
explicitly specified with "table_name.field_name" notation. Otherwise returns undef and does not attempt to
guess the name of the table.

=item C<getFieldName()>

Returns the name of the field for a FIELD_ITEM object.

=item C<getDirection()>

For an C<FIELD_ITEM> used in C<GROUP BY> or C<ORDER BY>, the function will return either the string
C<"ASC"> or the string C<"DESC"> depending on the group/ordering direction. Default is C<"ASC"> and will be
returned even if the query does not specify a direction explicitly.

=item C<getUseIndex()>, C<getForceIndex()> and C<getIgnoreIndex()>

Returns a reference to an array containing one string for each index mentioned in the
C<USE INDEX>, C<FORCE INDEX> or C<IGNORE INDEX> clause for the table in question.

=over

=head1 JOINS

C<getItemType()> will return C<'JOIN_ITEM'>. In C<DBIx::MyParse>, joins are a separate object, even if it is not
really so in the C<MySQL> source. This way all JOINs are represented properly nested.

=item C<getJoinItems()>

Will return the two sides of the join. Each side may be a C<'TABLE_ITEM'>, a <'SUBSELECT_ITEM'> or another C<'JOIN_ITEM'>
so please be prepared to handle all.

=item C<getJoinCond()>

Returns a reference to a an C<Item> object containing the C<ON> join condition

=item C<getJoinFields()>

Returns a reference to C<'FIELD_ITEM'> C<Item>s for each fields that appears in the C<USING> clause.

=item C<getJoinType()>

Returns, as string, the type of join that will be used. Possible values are:

	"JOIN_TYPE_LEFT"
	"JOIN_TYPE_RIGHT"
	"JOIN_TYPE_STRAIGHT"
	"JOIN_TYPE_NATURAL"

If undef is returned, this means C<'INNER JOIN'>.

=over

=head1 SUBQUERIES/SUBSELECTS

C<getItemType()> will return C<'SUBSELECT_ITEM>

=item C<getSubselectType()>

Returns one of the following, depending on the context where the subquery was seen:

	"SINGLEROW_SUBS"
	"IN_SUBS"
	"EXISTS_SUBS"
	"ANY_SUBS"
	"ALL_SUBS"

If undef is returned, this means a subquery in the C<FROM> clause, e.g. derived table 

=item C<getSubselectExpr()>

For subselect types C<'ANY_SUBS'>, C<'IN_SUBS'> and C<'ALL_SUBS'>, will return the C<Item> that is being
checked against the data returned by the subquery.

=item C<getSubselectCond()>

For subselect types C<'ANY_SUBS'> and C<'ALL_SUBS'> will return the function used to match the expression
against the data returned by the subquery, e.g. C<< '>' >>. A single-character string value is returned,
not a full C<Item> object of type C<"COND_ITEM"> .

=item C<getSubselectQuery()>

Returns an L<DBIx::MyParse::Query> object that contains the parse tree of the actual subselect itself.

=back
