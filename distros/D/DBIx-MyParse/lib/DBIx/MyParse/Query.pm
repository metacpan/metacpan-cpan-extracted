package DBIx::MyParse::Query;

use strict;
use warnings;
use Carp;

our $VERSION = '0.88';

#
# If you change those constants, do not forget to change
# the corresponding C #defines in my_parse.h
#

use constant MYPARSE_COMMAND		=> 0;
use constant MYPARSE_ORIG_COMMAND	=> 1;
use constant MYPARSE_QUERY_OPTIONS	=> 2;
use constant MYPARSE_SELECT_ITEMS	=> 3;
use constant MYPARSE_INSERT_FIELDS	=> 4;
use constant MYPARSE_UPDATE_FIELDS	=> 5;
use constant MYPARSE_INSERT_VALUES	=> 6;
use constant MYPARSE_UPDATE_VALUES	=> 7;

use constant MYPARSE_TABLES		=> 8;
use constant MYPARSE_ORDER		=> 9;
use constant MYPARSE_GROUP		=> 10;
use constant MYPARSE_WHERE		=> 11;
use constant MYPARSE_HAVING		=> 12;
use constant MYPARSE_LIMIT		=> 13;
use constant MYPARSE_ERROR		=> 14;
use constant MYPARSE_ERRNO		=> 15;
use constant MYPARSE_ERRSTR		=> 16;
use constant MYPARSE_SQLSTATE		=> 17;

use constant MYPARSE_DELETE_TABLES	=> 18;

use constant MYPARSE_SAVEPOINT		=> 20;

use constant MYPARSE_SCHEMA_SELECT	=> 21;
use constant MYPARSE_WILD		=> 22;


1;

sub getCommand {
	return $_[0]->[MYPARSE_COMMAND];
}

sub setCommand {
	$_[0]->[MYPARSE_COMMAND] = $_[1];
}

sub getOrigCommand {
	return $_[0]->[MYPARSE_ORIG_COMMAND];
}

sub setOrigCommand {
	return $_[0]->[MYPARSE_ORIG_COMMAND] = $_[1];
}

sub getOptions {
	return $_[0]->[MYPARSE_QUERY_OPTIONS];
}

sub setOptions {
	return $_[0]->[MYPARSE_QUERY_OPTIONS] = $_[1];
}

sub getOption {
	my ($query, $option) = @_;

	my $options = $query->getOptions();

	return undef if not defined $options;
	
	foreach my $o (@{$options}) {
		return 1 if $option eq $o;
	}
	return 0;
}

sub setOption {
	my $options = $_[0]->getOptions();
	$options = [] if not defined $options;
	push @{$options}, $_[1];
	$_[0]->setOptions($options);
}

sub getSelectItems {
	return $_[0]->[MYPARSE_SELECT_ITEMS];
}

sub setSelectItems {
	$_[0]->[MYPARSE_SELECT_ITEMS] = $_[1];
}

sub getInsertFields {
	return $_[0]->[MYPARSE_INSERT_FIELDS];
}

sub setInsertFields {
	$_[0]->[MYPARSE_INSERT_FIELDS] = $_[1];
}

sub getInsertValues {
	return $_[0]->[MYPARSE_INSERT_VALUES];
}

sub setInsertValues {
	$_[0]->[MYPARSE_INSERT_VALUES] = $_[1];
}

sub getUpdateFields {
	return $_[0]->[MYPARSE_UPDATE_FIELDS];
}

sub setUpdateFields {
	$_[0]->[MYPARSE_UPDATE_FIELDS] = $_[1];
}

sub getUpdateValues {
	return $_[0]->[MYPARSE_UPDATE_VALUES];
}

sub setUpdateValues {
	$_[0]->[MYPARSE_UPDATE_VALUES] = $_[1];
}	

sub getTables {
	return $_[0]->[MYPARSE_TABLES];
}

sub setTables {
	$_[0]->[MYPARSE_TABLES] = $_[1];
}

sub getDeleteTables {
	return $_[0]->[MYPARSE_DELETE_TABLES];
}

sub setDeleteTables {
	$_[0]->[MYPARSE_DELETE_TABLES] = $_[1];
}

sub getOrder {
	return $_[0]->[MYPARSE_ORDER];
}

sub setOrder {
	$_[0]->[MYPARSE_ORDER] = $_[1];
}

sub getOrderBy {
	return $_[0]->[MYPARSE_ORDER];
}

sub setOrderBy {
	$_[0]->[MYPARSE_ORDER] = $_[1];
}

sub getGroup {
	return $_[0]->[MYPARSE_GROUP];
}

sub setGroup {
	return $_[0]->[MYPARSE_GROUP] = $_[1];
}
sub getGroupBy {
	return $_[0]->[MYPARSE_GROUP];
}

sub setGroupBy {
	$_[0]->[MYPARSE_GROUP] = $_[1];
}

sub getWhere {
	return $_[0]->[MYPARSE_WHERE];
}

sub setWhere {
	$_[0]->[MYPARSE_WHERE] = $_[1];
}

sub getHaving {
	return $_[0]->[MYPARSE_HAVING];
}

sub setHaving {
	$_[0]->[MYPARSE_HAVING] = $_[1];
}

sub getLimit {
	return $_[0]->[MYPARSE_LIMIT];
};

sub setLimit {
	$_[0]->[MYPARSE_LIMIT] = $_[1];
}

sub getError {
	return $_[0]->[MYPARSE_ERROR];
}

sub setError {
	$_[0]->[MYPARSE_ERROR] = $_[1];
}

sub getErrno {
	return $_[0]->[MYPARSE_ERRNO];
}

sub setErrno {
	$_[0]->[MYPARSE_ERRNO] = $_[1];
}

sub getErrstr {
	return $_[0]->[MYPARSE_ERRSTR];
}

sub setErrStr {
	$_[0]->[MYPARSE_ERRSTR] = $_[1];
}

sub getSQLState {
	return $_[0]->[MYPARSE_SQLSTATE];
}

sub setSQLState {
	$_[0]->[MYPARSE_SQLSTATE] = $_[1];
}

sub getSavepoint {
	if (
		($_[0]->[MYPARSE_COMMAND] eq 'SQLCOM_SAVEPOINT') ||
		($_[0]->[MYPARSE_COMMAND] eq 'SQLCOM_ROLLBACK_TO_SAVEPOINT') ||
		($_[0]->[MYPARSE_COMMAND] eq 'SQLCOM_RELEASE_SAVEPOINT')
	) {
		return $_[0]->[MYPARSE_SAVEPOINT];
	} else {
		carp("getSavepoint() called, but getCommand() == ".$_[0]->[MYPARSE_COMMAND]);
		return undef;
	}
}

sub setSavepoint {
	$_[0]->[MYPARSE_SAVEPOINT] = $_[1];
}

sub getSchemaSelect {
	my $query = shift;

	my $command = $query->getCommand();
	my $orig_command = $query->getOrigCommand();

	if (
		($orig_command eq 'SQLCOM_SHOW_FIELDS') ||
		($orig_command eq 'SQLCOM_SHOW_TABLES') ||
		($orig_command eq 'SQLCOM_SHOW_TABLE_STATUS') ||
		($command eq 'SQLCOM_CHANGE_DB') ||
		($command eq 'SQLCOM_DROP_DB') ||
		($command eq 'SQLCOM_CREATE_DB')
	) {
		return $query->[MYPARSE_SCHEMA_SELECT];
	} else {
		warn("getSchemaSelect() called, but getOrigCommand() == ".$query->getOrigCommand());
		return undef;
	}
}

sub setSchemaSelect {
	$_[0]->[MYPARSE_SCHEMA_SELECT] = $_[1];
}

sub getWild {
	return $_[0]->[MYPARSE_WILD];
}

sub setWild {
	$_[0]->[MYPARSE_WILD] = $_[1];
}

sub isPrintable {
	my $query = shift;
	if (
		($query->getCommand() eq 'SQLCOM_SELECT') &&
		($query->getOrigCommand() ne 'SQLCOM_END')
	) {
		return 0;	# We can not print SHOW TABLES and the like for the time being
	} elsif ($query->getOrigCommand() =~ m{SELECT|INSERT|UPDATE|DELETE|REPLACE|DROP_DB|DROP_TABLE|CREATE_DB|RENAME_TABLE|TRUNCATE|BEGIN|COMMIT|ROLLBACK|SAVEPOINT}io) {
		return 1;
	} else {
		return 0;
	}
}

sub print {
	my $query = shift;

	my $command = $query->getCommand();

	if ($command eq 'SQLCOM_SELECT') {
		return $query->_printSelect();
	} elsif (
		($command eq 'SQLCOM_UPDATE') ||
		 ($command eq 'SQLCOM_UPDATE_MULTI')
	) {
		return $query->_printUpdate();
	} elsif (
		($command eq 'SQLCOM_DELETE') ||
		($command eq 'SQLCOM_DELETE_MULTI')
	) {
		return $query->_printDelete();
	} elsif (
		($command eq 'SQLCOM_INSERT') ||
		($command eq 'SQLCOM_REPLACE') ||
		($command eq 'SQLCOM_INSERT_SELECT') ||
		($command eq 'SQLCOM_REPLACE_SELECT')
	) {
		return $query->_printInsertReplace();
	} elsif (
		($command eq 'SQLCOM_DROP_DB') ||
		($command eq 'SQLCOM_DROP_TABLE')
	) {
		return $query->_printDrop();
	} elsif ($command eq 'SQLCOM_CREATE_DB') {
		return $query->_printCreate();
	} elsif ($command eq 'SQLCOM_RENAME_TABLE') {
		return $query->_printRename();
	} elsif ($command eq 'SQLCOM_TRUNCATE') {
		return "TRUNCATE TABLE ".$query->getTables()->[0]->_printTable(0);
	} elsif ($command eq 'SQLCOM_BEGIN') {
		if ($command->getOption("WITH_CONSISTENT_SNAPSHOT")) {
			return "START TRANSACTION WITH CONSISTENT SNAPSHOT";
		} else {
			return "START TRANSACTION";
		}
	} elsif (
			($command eq 'SQLCOM_COMMIT') ||
			($command eq 'SQLCOM_ROLLBACK')
	) {
		my $chain = $query->getOption("CHAIN") ? "AND CHAIN " : "";
		my $no_chain = $query->getOption("NO_CHAIN") ? "AND NO CHAIN " : "";
		my $release = $query->getOption("RELEASE") ? "RELEASE " : "";
		my $no_release = $query->getOption("NO_RELEASE") ? "NO RELEASE " : "";
		if ($command eq 'SQLCOM_ROLLBACK') {
			return "ROLLBACK ".$chain.$no_chain.$release.$no_release;
		} else {
			return "COMMIT ".$chain.$no_chain.$release.$no_release;
		}
	} elsif ($command eq 'SQLCOM_SAVEPOINT') {
		return "SAVEPOINT ".$query->getSavepoint();
	} elsif ($command eq 'SQLCOM_ROLLBACK_TO_SAVEPOINT') {
		return "ROLLBACK TO SAVEPOINT ".$query->getSavepoint();
	} elsif ($command eq 'SQLCOM_RELEASE_SAVEPOINT') {
		return "RELEASE SAVEPOINT ".$query->getSavepoint();
	} else {
		warn("DBIx::MyParse::Query::print() called, but command eq '$command'");
		return undef;
	}
}

sub _printRename {
	my $query = shift;
	my $command = $query->getCommand();

	if ($command eq 'SQLCOM_RENAME_TABLE') {
		my @tables = @{$query->getTables()};
		my @tables_printed;
		while (my ($table1, $table2) = splice(@tables,0,2)) {
			push @tables_printed, $table1->_printTable(0)." TO ".$table2->_printTable(0);
		}
		return "RENAME TABLE ".join(', ', @tables_printed);
	}
}

sub _printDrop {
	my $query = shift;
	my $command = $query->getCommand();
	
	if ($command eq 'SQLCOM_DROP_DB') {
		my $drop_if_exists = $query->getOption("DROP_IF_EXISTS") ? "IF EXISTS " : "";
		return "DROP DATABASE ".$drop_if_exists.$query->getSchemaSelect()->print();
	} elsif ($command eq 'SQLCOM_DROP_TABLE') {
		my $drop_if_exists = $query->getOption("DROP_IF_EXISTS") ? "IF EXISTS " : "";
		my $drop_temporary = $query->getOption("DROP_TEMPORARY") ? "TEMPORARY " : "";
		my $drop_restrict = $query->getOption("DROP_RESTRICT") ? " RESTRICT" : "";
		my $drop_cascade = $query->getOption("DROP_CASCADE") ? " CASCADE" : "";
		return "DROP ".$drop_temporary."TABLE ".$drop_if_exists.join(', ', map { $_->_printTable(0) } @{$query->getTables()}).$drop_restrict.$drop_cascade;
	}
}

sub _printCreate {
	my $query = shift;
	my $command = $query->getCommand();
	
	if ($command eq 'SQLCOM_CREATE_DB') {
		my $create_if_not_exists = $query->getOption("CREATE_IF_NOT_EXISTS") ? "IF NOT EXISTS " : "";
		return "CREATE DATABASE ".$create_if_not_exists.$query->getSchemaSelect()->print();
	}
}

sub _printSelect {
	my $query = shift;

	my $describe =  "";
	$describe = 'EXPLAIN ' if $query->getOption('DESCRIBE_NORMAL');
	$describe = 'EXPLAIN EXTENDED ' if $query->getOption('DESCRIBE_EXTENDED');

	my $distinct = $query->getOption('SELECT_DISTINCT') ? "DISTINCT " : "";
	my $high_priority = $query->getOption('TL_READ_HIGH_PRIORITY') ? "HIGH_PRIORITY " : "";
	my $straight_join = $query->getOption('SELECT_STRAIGHT_JOIN') ? "STRAIGHT_JOIN " : "";
	my $small_result = $query->getOption('SELECT_SMALL_RESULT') ? "SQL_SMALL_RESULT " : "";
	my $big_result = $query->getOption('SELECT_BIG_RESULT') ? "SQL_BIG_RESULT " : "";
	my $buffer_result = $query->getOption('OPTION_BUFFER_RESULT') ? "SQL_BUFFER_RESULT " : "";

	my $query_cache = "";
	$query_cache = 'SQL_NO_CACHE ' if $query->getOption('SQL_NO_CACHE');
	$query_cache = 'SQL_CACHE ' if $query->getOption('OPTION_TO_QUERY_CACHE');

	my $found_rows = $query->getOption("OPTION_FOUND_ROWS") ? "SQL_CALC_FOUND_ROWS ": "";

	my $for_update = $query->getOption("TL_WRITE") ? " FOR UPDATE" : "";
	my $share_mode = $query->getOption("TL_READ_WITH_SHARED_LOCKS") ? " LOCK IN SHARE MODE": "";

	my $with_cube = $query->getOption("WITH_CUBE") ? " WITH CUBE " : "";
	my $with_rollup = $query->getOption("WITH_ROLLUP") ? " WITH ROLLUP ": "";
	
	my $select_items_str;
	my $select_items = $query->getSelectItems();

	if (defined $select_items) {
		$select_items_str = join(', ', map { $_->print(1) } @{$select_items} );
	}

	return $describe.'SELECT '.$distinct.$high_priority.$straight_join.$small_result.$big_result.$buffer_result.
		$query_cache.$found_rows.$select_items_str." ".
		(defined $query->getTables() ? "FROM ".$query->_printFrom() : "").
		$query->_printWhere().
		$query->_printGroupBy().$with_rollup.$with_cube.
		$query->_printHaving().
		$query->_printOrderBy().
		$query->_printLimit().
		$for_update.$share_mode
	;
}

sub _printInsertReplace {
	my $query = shift;
	my $command = $query->getCommand();

	my $verb;

	if (
		($command eq 'SQLCOM_INSERT') ||
		($command eq 'SQLCOM_INSERT_SELECT')
	) {
		$verb = 'INSERT ';
	} elsif (
		($command eq 'SQLCOM_REPLACE') ||
		($command eq 'SQLCOM_REPLACE_SELECT')
	) {
		$verb = 'REPLACE ';
	}

	my $low_priority = ($query->getOption("TL_WRITE_LOW_PRIORITY") ? "LOW_PRIORITY " : "");
	my $high_priority = ($query->getOption("TL_WRITE") && $command =~ m{INSERT}o ? "HIGH_PRIORITY " : "");
	my $delayed = ($query->getOption("TL_WRITE_DELAYED") ? "DELAYED " : "");
	my $ignore = ($query->getOption("IGNORE") ? "IGNORE " : "");

	my $on_duplicate_key = "";

	my @all_tables = @{$query->getTables()};
	my $insert_table = shift @all_tables;
	# We do not use simply $insert_table->print() because INSERT does not accept table aliases
	my $table_printed = $insert_table->_printTable(0);

	my $insert_fields = $query->getInsertFields();
	my $fields_printed = scalar(@{$insert_fields}) > 0 ? "(".join(', ', map { $_->print() } @{$insert_fields}).") " : "";

	my $update_fields = $query->getUpdateFields();

	if (defined $update_fields) {
		my $update_count = scalar(@{$update_fields});
		my $update_values = $query->getUpdateValues();

		my @updates;
		foreach my $i (0..($update_count - 1)) {
			push @updates, $update_fields->[$i]->print()." = ".$update_values->[$i]->print();
		}
		$on_duplicate_key = "ON DUPLICATE KEY UPDATE ".join(', ', @updates);
	}

	if (
		($command eq 'SQLCOM_INSERT_SELECT') ||
		($command eq 'SQLCOM_REPLACE_SELECT')
	) {
		my $select_printed = $query->_printSelect();
		return $verb.$low_priority.$delayed.$high_priority.$ignore.'INTO '.$table_printed.' '.$fields_printed.' '.$select_printed.' '.$on_duplicate_key;
	} else {
	
		my $insert_values = $query->getInsertValues();
		my @values_printed;
		foreach my $row (@{$insert_values}) {
			push @values_printed, join(', ', map { $_->print() } @{$row});
		}
		my $values_printed = join(', ', map { "(".$_.")"} @values_printed)." ";
		return $verb.$low_priority.$delayed.$high_priority.$ignore.'INTO '.$table_printed.' '.$fields_printed."VALUES ".$values_printed.$on_duplicate_key;
	}
}

sub _printUpdate {
	my $query = shift;

	my $update_fields = $query->getUpdateFields();
	my $update_values = $query->getUpdateValues();
	
	my $field_count = scalar(@{$update_fields});

	my @updates;

	foreach my $i (0..($field_count - 1)) {
		push @updates, $update_fields->[$i]->print()." = ".$update_values->[$i]->print();
	}

	my $low_priority = ($query->getOption("TL_WRITE_LOW_PRIORITY") ? "LOW_PRIORITY " : "");
	my $ignore = ($query->getOption("IGNORE") ? "IGNORE " : "");

	return "UPDATE ".$low_priority.$ignore.$query->_printFrom().
		" SET ".join(', ', @updates).
		$query->_printWhere().
		$query->_printOrderBy().
		$query->_printLimit();
}

sub _printDelete {
	my $query = shift;

	my $low_priority = ($query->getOption("TL_WRITE_LOW_PRIORITY") ? "LOW_PRIORITY " : "");
	my $ignore = ($query->getOption("IGNORE") ? "IGNORE " : "");
	my $quick = ($query->getOption("OPTION_QUICK") ? "QUICK " : "");

	if ($query->getCommand() eq 'SQLCOM_DELETE_MULTI') {
		my $delete_tables = join(', ', map { $_->print() } @{$query->getDeleteTables()});
		return "DELETE ".$low_priority.$ignore.$quick.$delete_tables." FROM ".
			$query->_printFrom().
			$query->_printWhere();
	} else {
		my $delete_table = $query->getTables()->[0];
		my $table_printed = $delete_table->_printTable(0);

		return "DELETE ".$low_priority.$ignore.$quick."FROM ".$table_printed.
			$query->_printWhere().
			$query->_printOrderBy().
			$query->_printLimit();
	}
}

sub _printFrom {
	my $query = shift;
	my $from = $query->getTables();
	my $command = $query->getCommand();

	if (not defined $from) {
		return "DUAL";
	} elsif (ref($from) eq 'ARRAY') {
		my @tables = @{$from};
		if  (
			($command eq 'SQLCOM_INSERT_SELECT') ||
			($command eq 'SQLCOM_REPLACE_SELECT')
		) {
			shift @tables;
		}
		
		if (scalar(@tables) > 0) {
			return join(', ', map { $_->print(1) } @tables);
		} else {
			return "DUAL";
		}
	} else {
		return $from->print(1);
	}
}

sub _printWhere {
	my $query = shift;
	my $where = $query->getWhere();
	if (defined $where) {
		return " WHERE ".$where->print();
	} else {
		return "";
	}
}

sub _printGroupBy {
	my $query = shift;
	if (defined $query->getGroupBy()) {
		return " GROUP BY ".join(', ', map {$_->print()} @{$query->getGroupBy()});
	} else {
		return "";
	}
}

sub _printOrderBy {
	my $query = shift;

	if (defined $query->getOrderBy()) {
		return " ORDER BY ".join(', ', map {$_->print()." ".$_->getDir()} @{$query->getOrderBy()});
	} else {
		return "";
	} 
}

sub _printHaving {
	my $query = shift;
	my $having = $query->getHaving();
	if (defined $having) {
		return " HAVING ".$having->print();
	} else {
		return "";
	}
}

sub _printLimit {
	my $query = shift;
	my $limit = $query->getLimit();
	return "" if not defined $limit;
	my $row_count = $limit->[0];
	my $offset = $limit->[1];
	my $limit_str = " LIMIT ".$row_count->print();
	$limit_str .= " OFFSET ".$offset->print() if defined $offset;
	return $limit_str;
}
1;

__END__

=head1 NAME

DBIx::MyParse::Query - Access the parse tree produced by DBIx::MyParse

=head1 SYNOPSIS

        use DBIx::MyParse;
        my $parser = DBIx::MyParse->new();
        my $query = $parser->parse("INSERT INTO table VALUES (1)");
        print $query->getCommand();

	$query->setCommand("SQLCOM_REPLACE");	# Replace INSERT with SELECT
	$query->print();			# Print modified query as SQL

	

=head1 DESCRIPTION

This module attempts to provide structured access to the parse tree
that is produced by MySQL's SQL parser. Since the parser itself is not
exactly perfectly structured, please make sure you read this entire
document before attempting to make sense of C<DBIx::MyParse::Query> objects.

=head1 METHODS

=over

=item C<getCommand()>

Returns, as string, the name of SQL command that was parsed. All possible values
can be found in enum enum_sql_command in F<sql/sql_lex.h> from the MySQL source.

The commands that are currently supported (that is, a parse tree is created for them) are as follows:

	"SQLCOM_SELECT",	"SQLCOM_DO"
	"SQLCOM_INSERT",	"SQLCOM_INSERT_SELECT"
	"SQLCOM_REPLACE",	"SQLCOM_REPLACE_SELECT"
	"SQLCOM_UPDATE",	"SQLCOM_UPDATE_MULTI"
	"SQLCOM_DELETE",	"SQLCOM_DELETE_MULTI"

	"SQLCOM_BEGIN",		"SQLCOM_COMMIT",	"SQLCOM_ROLLBACK",
	"SQLCOM_SAVEPOINT",	"SQLCOM_ROLLBACK_TO_SAVEPOINT", "SQLCOM_RELEASE_SAVEPOINT"

	"SQLCOM_DROP_DB",	"SQLCOM_CREATE_DB",	"SQLCOM_DROP_TABLE",	"SQLCOM_RENAME_TABLE"

Please note that the returned value is a string, and not an integer. Please read the section
COMMANDS below for notes on individual commands

=item C<getOrigCommand()>

For C<DESCRIBE>, C<SHOW TABLES>, C<SHOW TABLE STATUS>, C<SHOW DATABASES> and C<SHOW FIELDS>,
the MySQL parser will rewrite the original query into a C<SELECT> query. The original query type
is preserved in C<getOrigCommand()> and the possible values are as follows:

	"SQLCOM_SHOW_FIELDS", "SQLCOM_SHOW_TABLES", "SQLCOM_SHOW_TABLE_STATUS", "SQLCOM_SHOW_DATABASES"

Please see the section "Information Schema Queries" below for more information.

=item C<getOptions()>

Returns a reference to an array containing, as strings, the various options specified for the query, such as
HIGH_PRIORITY, LOW_PRIORITY, DELAYED, IGNORE and the like. Some of the options are not returned with the names
you expect, but rather using their internal MySQL names. Some options may be returned more than once.

C<SQL_NO_CACHE> may be returned even if not explicitly present in the query, if the query contains uncacheable
elements, eg C<NOW()>.

=item C<getOption($option_name)>

Returns true if $option_name was specified for the query

=back

=head1 ERROR HANDLING

If there has been a parse error, C<getCommand() eq "SQLCOM_ERROR">. From there on, you can:

=over

=item C<getError()>

Returns the error code as string, in English, as defined in F<include/mysql_error.h>.

=item C<getErrno()>

Returns the error code as integer.

=item C<getErrstr()>

Returns the entire error message, in the language of the MySQL installation. This is the same text the C<mysql>
client will print for an identical error.

=item C<getSQLState()> 

Returns a null-terminated string containing the SQLSTATE error code. The error code consists of five characters.
"00000" means "no error". The values are specified by ANSI SQL and ODBC.

=back

The parser is supposed to only report syntax errors with C<"ER_PARSE_ERROR">, however due to the way MySQL
works, this is not always the case. Sometimes the parser would do things during the actual parsing process that
common sense would say should be done after. Therefore, expect other errors as well. For a list of possible values,
please see:

http://dev.mysql.com/doc/refman/5.0/en/error-handling.html

=head1 COMMANDS

=head2 C<"SQLCOM_SELECT">

=over

=item C<getSelectItems()>

Returns a reference to the array of the items the C<SELECT> query will return, each being a L<Item|DBIx::MyParse::Item> object.

Valid options are 
	"SELECT_DISTINCT", "TL_READ_HIGH_PRIORITY", "SELECT_STRAIGHT_JOIN"
	"SELECT_SMALL_RESULT", "SELECT_BIG_RESULT", "OPTION_BUFFER_RESULT"
	"OPTION_FOUND_ROWS", "OPTION_TO_QUERY_CACHE" (force caching), "SQL_NO_CACHE",
	"TL_WRITE" (FOR UPDATE), "TL_READ_WITH_SHARED_LOCKS" (LOCK IN SHARE MODE),
	"WITH_ROLLUP", "WITH_CUBE",
	"SELECT_DESCRIBE", "DESCRIBE_NORMAL", "DESCRIBE_EXTENDED"

=item C<getTables()>

Rreturns a reference to the array of tables specified in the query. Each table is also an L<Item|DBIx::MyParse::Item>
object for which C<getType() eq "TABLE_ITEM"> which contains information on the Join type, join conditions,
indexes, etc. See L<DBIx::MyParse::Item|DBIx::MyParse::Item> for information on how to extract the individual properties.

=item C<getWhere()>

Returns an L<Item|DBIx::MyParse::Item> object that is the root of the tree containing all the WHERE conditions.

=item C<getHaving()>

Operates the same way as C<getWhere()> but for the HAVING clause.

=item C<getGroup()>

Returns a reference to an array containing one L<Item|DBIx::MyParse::Item> object for each GROUP BY condition.

=item C<getOrder()>

Returns a reference to an array containing the individual L<Items|DBIx::MyParse::Item> from the ORDER BY clause.

=item C<<getLimit()>

Returns a reference to a two-item array containing the two parts of the LIMIT clause as L<Item|DBIx::MyParse::Item> objects.

=back

=head2 C<"SQLCOM_DO">

C<getSelectItems()> will return the expressions being executed.

=head2 C<"SQLCOM_UPDATE"> and C<"SQLCOM_UPDATE_MULTI">

=over

=item C<< my $array_ref = $query->getUpdateFields() >>

Returns a reference to an array containing the fields that the query would update.

=item C<< my $array_ref = $query->getUpdateValues() >>

Returns a reference to an array containing the values that will be assigned to the fields being updated.

=back

C<getTables()>, C<getWhere()>, C<getOrder()> and C<getLimit()> can also be used for update queries.

For C<"SQLCOM_UPDATE">, C<getTables()> will return a reference to a one-item array containg a L<TABLE_ITEM|DBIx::MyParse::Item> object
describing the table being updated. For C<"SQLCOM_UPDATE_MULTI">, the array can include several tables or C<JOIN_ITEM>s.

=head2 C<"SQLCOM_DELETE"> and C<"SQLCOM_DELETE_MULTI">

For a multiple-table delete, C<getCommand() eq "SQLCOM_DELETE">

=over

=item C<getDeleteTables()>

Will return a reference to an array contwaining the table(s) we are deleting records from.

=item C<getTables()>

For a multiple-table delete, C<getTables()> will return the tables listed in the FROM clause,
which are used to provide referential integrity. Those may include C<JOIN_ITEM>s.

=back

C<getWhere()>, C<getOrder()> and C<getLimit()> can also be used.

=head2 C<"SQLCOM_INSERT">, C<"SQLCOM_INSERT_SELECT">, C<"SQLCOM_REPLACE"> and C<"SQLCOM_REPLACE_SELECT">

=over

=item C<getInsertFields()>

Returns a list of the fields you are inserting to.

=item C<getInsertValues()> 

For C<"SQLCOM_INSERT"> and C<"SQLCOM_REPLACE">, C<getInsertValues()> will return a reference to an array,
containing one sub-array for each row being inserted or replaced (even if there is only one row).

=back

For C<"SQLCOM_INSERT_SELECT"> and C<"SQLCOM_REPLACE_SELECT">, C<getSelectItems()>, C<getTables()>,
C<getWhere()> and the other SELECT-related properties will describe the C<SELECT> query used to provide values for the C<INSERT>.

If C<ON DUPLICATE KEY UPDATE> is also specified, then C<getUpdateFields()> and C<getUpdateValues()> will
also be defined.

=head2 C<"SQLCOM_BEGIN">

The C<"WITH_CONSISTENT_SNAPSHOT"> may be present

=head2 C<"SQLCOM_COMMIT"> and C<"SQLCOM_ROLLBACK">

The C<"CHAIN">, C<"NO_CHAIN">, C<"RELEASE"> and C<"NO_RELEASE"> options may be present

=head2 C<"SQLCOM_SAVEPOINT">, C<"SQLCOM_ROLLBACK_TO_SAVEPOINT"> and C<"SQLCOM_RELEASE_SAVEPOINT">

=over

=item C<getSavepoint()>

Returns the name of the savepoint being referenced

=back

=head2 C<"SQLCOM_LOCK_TABLES"> and C<"SQLCOM_UNLOCK_TABLES">

You can use C<getTables()> to get a list of the tables being locked. Calling C<getOptions()> returns a list of lock
types so that the first lock type in the list corresponds to the first table and so on in a one-to-one relationship.

=head2 C<"SQLCOM_DROP_TABLE">, C<"SQLCOM_TRUNCATE"> and C<"SQLCOM_RENAME_TABLE">

For C<"SQLCOM_DROP_TABLE"> and C<"SQLOM_TRUNCATE">, use C<getTables()> to obtain a reference to an array of
C<TABLE_ITEM> objects for each table being dropped or truncated.

For C<"SQLCOM_RENAME_TABLE"> use C<getTables()> to obtain a reference to an array containing the tables being renamed.
The first (index 0) and all even-numbered (2,3,4, etc.) items of the array will be the table names you are renaming FROM
and the odd-numbered array items (1,2,3, etc.) will be the table names you are renaming TO. MySQL allows a one-at-a-time
table rename between databases. In this case, C<getDatabaseName()> on the C<TABLE_ITEM> objects will return the names of
the databases.

The following options may be present: C<"DROP_IF_EXISTS">, C<"DROP_TEMPORARY">, C<"DROP_RESTRICT"> and C<"DROP_CASCADE">.

=head1 Information Schema Queries

The following queries

	"SQLCOM_SHOW_FIELDS", "SQLCOM_SHOW_TABLES",
	"SQLCOM_SHOW_TABLE_STATUS", "SQLCOM_SHOW_DATABASES"

are rewritten internally by the MySQL parser into SELECT queries. To determine the original query, use C<getOrigCommand()>.

To determine the original table or database the query pertains to , use C<getSchemaSelect()> which
returns either a L<"DATABASE ITEM"|DBIx::MyParse::Item>, L<"TABLE_ITEM"|DBIx::MyParse::Item> or a L<"FIELD_ITEM"|DBIx::MyParse::Item> object.

To determine the contents of any C< LIKE > operator, use C<getWild()> which will return a string.

If you are actually interested in what result columns are expected from you, you can use C<getSelectItems()> as with
any other query for C"<SQLCOM_SHOW_FIELDS>" and C<"SQLCOM_SHOW_TABLE_STATUS">. C<"SQLCOM_SHOW_TABLES"> and
C<"SQLCOM_SHOW_DATABASES"> require that you only return a single column with table/database names. The C<FULL> attribute
to C<"SHOW TABLES"> is not supported at this time.

	"SQLCOM_CHANGE_DB"

For C<"USE database">, no such rewriting takes places, so C<getCommand() eq "SQLCOM_CHANGE_DB">. However, the actual
database being changed to is still found in the object that C<getSchemaSelect()> returns.

Please see C<t/show.t> for more examples on how to parse those queries.

	"SQLCOM_DROP_DB" and "SQLCOM_CREATE_DB"

also uses C<getSchemaSelect()>. A C<"DROP_IF_EXISTS"> or C<"CREATE_IF_NOT_EXISTS"> option may be present.

=head1 Dumping queries

C<print()> can be used to convert the parse tree back into SQL. C<SELECT>, C<INSERT>, C<REPLACE>, C<UPDATE> and C<DELETE>
statements are supported. Please note that the returned string may be very different from the orginal query due to internal
transformations that MySQL applies during parsing. Also, the C<print()>-ed query may have extra C<AS> clauses and an
abundance of nested brackets.

C<isPrintable()> can be used to test whether calling C<print()> would be meaningful.

=head1 Modifying the parse tree

For every C<get> method, there is a corresponding C<set> method that updates the parse tree, e.g.

	$query->setCommand("SQLCOM_UPDATE");

Also, any arrayrefs returned from C<get> methods can be modified and (since references are used) the results will be
reflected in the original object. If you do not want this to happen, you do need to dereference the arrayref and assign
it to a new array, e.g.:

	my $items = $query->getItems();
	my @items_copy = @{$items};

=cut
