package DBIx::Compare;

use 5.006;
use strict;
use warnings;
use DBI;

our $VERSION = '1.7';

BEGIN {
	$SIG{__WARN__} = \&trap_warn;
}
sub trap_warn {
	my $signal = shift;
	if ($ENV{ _VERBOSE_ }){
		warn $signal;
	} else {
		return;
	}
}

{ package db_comparison;

	sub new {
		my $class = shift;
		my $self = { };
		bless $self, $class;
		if (@_){
			$self->set_dbh(@_);
			if ($class eq 'db_comparison'){
				if (my $new_class = $self->guess_class){
					bless $self, $new_class;
				}
			}
		} else {
			die "DBIx::Compare ERROR: Need two database handles to compare\n";		
		}
		return $self;
	}
	sub guess_class {
		my $self = shift;
		if (my $dbd = $self->get_db_driver){
			use Module::List qw(list_modules);
			my $want_this = 'DBIx::Compare::'.$dbd;
			my $class = lc($dbd)."_comparison";
			
			my $hModules = list_modules('DBIx::Compare::',{list_modules=>1});
			for my $module (keys %$hModules){
				if ($want_this =~ /^$module/){	# i.e. driver SQLite2 will match DBIx::Compare::SQLite
					eval "require $module";
					return $class;
				}
			}
			warn "DBIx::Compare ERROR; No plug-in for driver '$dbd'\nSome comparisons may not work\n";
		}
		return;		
	}
	sub set_dbh {
		my ($self,$dbh1,$dbh2) = @_;
		die "DBIx::Compare ERROR: Need two database handles to compare\n" unless ($dbh2);
		die "DBIx::Compare ERROR: Not a database handle\n"
			unless (($dbh1->isa('DBI::db')) && ($dbh2->isa('DBI::db')));
					
		$self->{ _db1 }{ _dbh } = $dbh1;
		$self->{ _db1 }{ _Name } = $dbh1->{ Name };
		$self->{ _db2 }{ _dbh } = $dbh2;
		$self->{ _db2 }{ _Name } = $dbh2->{ Name };
	
		$self->set_parsed_name($dbh1);
		$self->set_parsed_name($dbh2);

		my $dbd1 = $dbh1->{ Driver }{ Name };
		my $dbd2 = $dbh2->{ Driver }{ Name };
		if ($dbd1 eq $dbd2){
			$self->{ _DB_Driver } = $dbd1;
		} else {
			warn "DBIx::Compare ERROR; Database drivers need to be the same for some comparisons\n";	
		}
	}
	# Allow certain forms of dsn:
	#   "...[database|dbname]=mydb..." or
	#   "mydb:..." or
	#   "mydb;..."
	#   "mydb"
	#
	sub set_parsed_name {
		my ($self,$dbh) = @_;
		my $parsed_name = undef;
		my $name = $dbh->{ Name };
		if ($name =~ m/((database|dbname)(\w)*=(\w)+((-)*(\w)*)*)/) {
			$parsed_name = $1;
			$parsed_name =~ s/(database|dbname)(\w)*=//;
		} elsif ($name =~ m/^((\w)+((-)*(\w)*)*):/) {
			$parsed_name = $1;
		} elsif ($name =~ m/^((\w)+((-)*(\w)*)*);/) {
			$parsed_name = $1;
		} elsif ($name =~ m/^((\w)+((-)*(\w)*)*$)/) {
 			$parsed_name = $1;
  		}

		if (!$parsed_name || ($parsed_name =~ m/(\w)+=(\w)+/)) {
			die "DBIx::Compare ERROR; Cannot extract database name from connection string: $name\n";
		}
		$self->{ $name }{ _parsed_Name } = $parsed_name;
	}
	sub get_parsed_name {
		my ($self,$dbh) = @_;
		return $self->{ $dbh->{ Name } }{ _parsed_Name };
	}
	sub verbose {
		$ENV{ _VERBOSE_ }++;
	}
	sub be_verbose {
		$ENV{ _VERBOSE_ };
	}
	sub get_dbh {
		my $self = shift;
		return ($self->{ _db1 }{ _dbh },$self->{ _db2 }{ _dbh }); 
	}
	sub get_db_names {
		my $self = shift;
		return ($self->{ _db1 }{ _Name },$self->{ _db2 }{ _Name });
	}
	# DBD will not be set if plug-in not available
	sub get_db_driver {
		my $self = shift;
		return $self->{ _DB_Driver };
	}
	sub get_tables {
		my $self = shift;
		unless (defined $self->{ _db1 }{ _Tables } && $self->{ _db2 }{ _Tables }){
			my ($dbh1,$dbh2) = $self->get_dbh;
			$self->{ _db1 }{ _Tables } = $self->fetch_multisinglefield("show tables",$dbh1);
			$self->{ _db2 }{ _Tables } = $self->fetch_multisinglefield("show tables",$dbh2);
		}
		if (wantarray()){
			return ( $self->{ _db1 }{ _Tables },$self->{ _db2 }{ _Tables } );
		} else {
			return $self->{ _db1 }{ _Tables };
		}
	}
	#Êlist of tables in each db
	sub common_tables {
		my $self = shift;
		if (@_){
			$self->{ _common_tables } = shift;
		} else {
			$self->compare_table_lists unless (defined $self->{ _common_tables });
			return $self->{ _common_tables };
		}
	}
	# list of tables in each db with same row count
	sub similar_tables {
		my $self = shift;
		if (@_){
			$self->{ _similar_tables } = shift;
		} else {
			$self->compare_row_counts unless (defined $self->{ _similar_tables });
			return $self->{ _similar_tables };
		}
	}
	sub get_differences {
		my $self = shift;
		if (@_){
			my $type = shift;
			unless (defined $self->{ _error_list }{ $type }){
				$self->{ _error_list }{ $type } = [];
			}
			return $self->{ _error_list }{ $type };
		} else {
			unless (defined $self->{ _error_list }){
				$self->{ _error_list } = {};
			}
			return $self->{ _error_list };
		}
	}
	sub add_errors {
		my $self = shift;
		my $aErrors = $self->get_differences(shift);
		push (@$aErrors, @_);
	}
	sub deep_compare {
		my $self = shift;

		my ($dbh1,$dbh2) = $self->get_dbh;
		my $same = 1;
			
		my @aTables;
		if (@_){
			@aTables = @_;
		} else {
			$same = $self->compare;	# sets minimal similar tables
			warn "Only running deep_compare() on similar tables\n" unless ($same);
			@aTables = @{ $self->similar_tables };
		}
		
		TABLE:for my $table (@aTables){
			my $primary_key = $self->get_primary_keys($table,$dbh1);
			# recursively calls compare_field_lists() and common_tables()
			# if relevant $self fields are not already filled
			my $fields = $self->field_list($table);	# common fields
			my $statement = "select $fields from $table order by $primary_key";

			my $sth1 = $dbh1->prepare($statement);
			$sth1->execute(); 
			my $sth2 = $dbh2->prepare($statement);
			$sth2->execute(); 
			
			my $row = 0;
			
			ROW:while(my $aResult_Row1 = $sth1->fetchrow_arrayref()) {
				$row++;
				my $aResult_Row2 = $sth2->fetchrow_arrayref();
				my @aResult_Row1 = map { $_ ? $_ : '' } @$aResult_Row1;
				my @aResult_Row2 = map { $_ ? $_ : '' } @$aResult_Row2;	
				unless (join(',',@aResult_Row1) eq join(',',@aResult_Row2)){
					warn "Discrepancy in table '$table' at row $row\n";
					$self->add_errors("Discrepancy in table $table",$row);
					$same = undef;
					next TABLE;
				}
			}
			$sth1->finish(); # we're done with this query
			$sth2->finish(); # we're done with this query
		}
		return $same;
	}
	sub compare {
		my $self = shift;
		
		my $tables = $self->compare_table_lists;
		my $fields = $self->compare_table_fields;
		my $rows = $self->compare_row_counts;
		my $stats = $self->compare_table_stats;
		
		if ($tables && $fields && $rows && $stats){
			return 1;
			warn "No differences were found\n";
		} else {
			unless ($tables){
				warn 	"Table lists are different\n".
						"\tComparing the common tables...\n";
			}
			unless ($rows){
				warn 	"Row counts in some tables are different\n".
						"\tComparing the content of tables with the same row count...\n";
			}	
			unless ($fields){
				warn 	"Table field names are different\n".
						"\tComparing the common fields...\n";
			}
			unless ($stats){
				warn 	"Some field values are different\n";
			}
			my $hDiffs = $self->get_differences;
			if (%$hDiffs){
				while (my ($type,$aErrors) = each %$hDiffs){
					warn "$type:\n";
					for my $error (@$aErrors){
						warn "\t$error\n";
					}
				}
			}
			return;
		}
	}
	sub compare_table_stats {
		my $self = shift;
		
		my $aTables = $self->similar_tables;
		my @aNew_Similar_Tables = ();
		my $similar = 1;
		
		TABLE:for my $table (@$aTables){
			my @aFields = $self->field_list($table);
			my @aBad_Fields = ();
			
			FIELD:for my $field (@aFields){
				unless ($self->compare_field_stats($table,$field)){	
					push(@aBad_Fields,$field);		
				}
			}
			if (@aBad_Fields){
				$self->add_errors("Bad fields in table $table",@aBad_Fields);
				$similar = undef;
			} else {
				push (@aNew_Similar_Tables,$table);
			}
		}
		# reset similar tables
		$self->similar_tables(\@aNew_Similar_Tables);
		return $similar;
	}
	sub compare_field_stats {
		my ($self,$table,$field) = @_;
		
		my ($type1,$type2) = $self->get_field_type($table,$field);
		if (($type1 =~ /date|time|interval/i)&&($type2 =~ /date|time|interval/i)){
			return $self->compare_datetime_field($table,$field);			
		} elsif (($type1 =~ /int|double|real|float|num|dec/i) && ($type2 =~ /int|double|real|float|num|dec/i)){
			return $self->compare_numeric_field($table,$field);			
		} elsif (($type1 =~ /char|text|lob|byte|binary/i)&&($type2 =~ /char|text|lob|byte|binary/i)){
			return $self->compare_string_field($table,$field);			
		} else {
			$self->add_errors("Could not compare field types",($type1,$type2));
			return;
		}
	}	
	sub do_compare_field {
		my ($self,$statement) = @_;
		my ($dbh1,$dbh2) = $self->get_dbh;
		my $aResult1 = $self->sql_fetcharray_singlerow($statement,$dbh1);
		my $aResult2 = $self->sql_fetcharray_singlerow($statement,$dbh2);
		# avoid unnecessary warnings 
		my @aResult1 = map { $_ ? $_ : '' } @$aResult1;
		my @aResult2 = map { $_ ? $_ : '' } @$aResult2;	
		if (join(',',@aResult1) eq join(',',@aResult2)){
			return 1;
		} else {
			return;
		}
	}
	sub set_field_info {
		my ($self,$table) = @_;
		my @aDBH = $self->get_dbh;
		
		for my $dbh (@aDBH){
			my $db_name = $dbh->{ Name };
			my $ahResults = $self->fetchhash_multirow("DESCRIBE $table",$dbh);
			my @aFields = ();
			for my $hResult (@$ahResults){
				my $field = $$hResult{ Field };
				push (@aFields, $field);
				my $type = $$hResult{ Type };
				$self->{ $db_name }{ $table }{ Fields }{ $field } = $type;
			}
			my @aSorted_Fields = sort @aFields;
			$self->{ $db_name }{ $table }{ Sorted_Fields } = \@aSorted_Fields;
		}
	}
	sub get_fields {
		my ($self,$table,$dbh) = @_;
		my $db_name = $dbh->{ Name };
		unless ((defined $self->{ $db_name }{ $table }) && (defined $self->{ $db_name }{ $table }{ Sorted_Fields })){
			$self->set_field_info($table);
		}
		return $self->{ $db_name }{ $table }{ Sorted_Fields };
	}
	sub get_field_type {
		my ($self,$table,$field) = @_;
		my ($db1,$db2) = $self->get_db_names;
		unless ((defined $self->{ $db1 }{ $table }) && (defined $self->{ $db2 }{ $table }) 
				&& (defined $self->{ $db1 }{ $table }{ Fields }) && (defined $self->{ $db2 }{ $table }{ Fields })){
			$self->set_field_info($table);
		}
		my $type1 = $self->{ $db1 }{ $table }{ Fields }{ $field };
		my $type2 = $self->{ $db2 }{ $table }{ Fields }{ $field };
		return ($type1,$type2);		
	}
	sub compare_table_fields {
		my $self = shift;
		my $aTables = $self->common_tables;
		my $diffs = 1;
		for my $table (@$aTables){
			my $same = $self->compare_field_lists($table);
			$diffs = undef unless ($same);
		}
		return $diffs;
	}
	sub compare_field_lists {
		my ($self,$table) = @_;
		
		my ($dbh1,$dbh2) = $self->get_dbh;
		my $aFields1 = $self->get_fields($table,$dbh1);
		my $aFields2 = $self->get_fields($table,$dbh2);
		
		if (join(',',@$aFields1) eq join(',',@$aFields2)){
			$self->field_list($table,$aFields1);
			return 1;
		} else {
			$self->find_field_diffs($table,$aFields1,$aFields2);
			return;
		}
	}
	sub find_field_diffs {
		my ($self,$table,$aFields1,$aFields2) = @_;

		my ($dbh1,$dbh2) = $self->get_dbh;
		
		my (%hFields1,%hFields2,@aNotIn1,@aNotIn2,@aInBoth);
		
		for my $field1 (@$aFields1){
			$hFields1{ $field1 }++;
		}
		for my $field2 (@$aFields2){
			$hFields2{ $field2 }++;
			if (defined $hFields1{ $field2 }){
				push(@aInBoth,$field2);
			} else {
				push(@aNotIn1,$field2);
			}
		}
		for my $field1 (@$aFields1){
			unless (defined $hFields2{ $field1 }){
				push(@aNotIn2,$field1);
			}
		}
		$self->field_list($table,\@aInBoth);
		my ($db1,$db2) = $self->get_db_names;
		$self->add_errors("Fields unique to $db1\.$table",@aNotIn2) if (@aNotIn2);
		$self->add_errors("Fields unique to $db2\.$table",@aNotIn1) if (@aNotIn1);
	}
	sub field_list {
		my $self = shift;
		my $table = shift;
		if (@_){
			my $aInBoth = shift;
			$self->{ _field_lists }{ $table } = $aInBoth;
			$self->{ _fields_strings }{ $table } = join(',',@$aInBoth);
		} else {
			$self->compare_field_lists($table) unless (defined $self->{ _field_lists }{ $table });
			if (wantarray()){
				@{ $self->{ _field_lists }{ $table } };
			} else {
				$self->{ _fields_strings }{ $table };
			}
		}
	}
	sub compare_table_lists {
		my $self = shift;
		my ($aTables1,$aTables2) = $self->get_tables;
		if (join(',',@$aTables1) eq join(',',@$aTables2)){
			$self->common_tables($aTables1);
			return 1;
		} else {
			$self->find_table_diffs($aTables1,$aTables2);
			return;
		}
	}
	sub find_table_diffs {
		my ($self,$aTables1,$aTables2) = @_;
		
		my ($dbh1,$dbh2) = $self->get_dbh;
		
		my (%hTables1,%hTables2,@aNotIn1,@aNotIn2,@aInBoth);
		
		for my $table1 (@$aTables1){
			$hTables1{ $table1 }++;
		}
		for my $table2 (@$aTables2){
			$hTables2{ $table2 }++;
			if (defined $hTables1{ $table2 }){
				push(@aInBoth,$table2);
			} else {
				push(@aNotIn1,$table2);
			}
		}
		for my $table1 (@$aTables1){
			unless (defined $hTables2{ $table1 }){
				push(@aNotIn2,$table1);
			}
		}
		$self->common_tables(\@aInBoth);
		my ($db1,$db2) = $self->get_db_names;
		$self->add_errors("Tables unique to $db1",@aNotIn2) if (@aNotIn2);
		$self->add_errors("Tables unique to $db2",@aNotIn1) if (@aNotIn1);
	}
	
	sub compare_row_counts {
		my $self = shift;
		my ($dbh1,$dbh2) = $self->get_dbh;
		my ($aTables,@aErrors,@aOK_Tables);
		if (@_){
			$aTables = [shift];
		} else {
			$aTables = $self->common_tables;
		}
		TABLE:for my $table (@$aTables){
			if ($self->row_count($table,$dbh1) != $self->row_count($table,$dbh2)){
				push(@aErrors,$table);
			} else {
				push(@aOK_Tables,$table);
			}
		}
		$self->similar_tables(\@aOK_Tables);
		if (@aErrors){
			$self->add_errors('Row count',@aErrors);
			return;
		} else {
			return 1;
		}
	}
	sub get_primary_keys {
		my ($self,$table,$dbh) = @_;
		my $db = $dbh->{ Name }; 
		unless (defined $self->{ $db }{ $table }{ _primary_keys }){
			$self->set_primary_keys($table,$dbh);
		} 
		my $aKeys = $self->{ $db }{ $table }{ _primary_keys };
		if (@$aKeys){
			if (wantarray()){
				return @$aKeys;
			} else {
				return join(',',@$aKeys);
			}
		} else {
			return;
		}
	}
	sub set_primary_keys {
		my ($self,$table,$dbh) = @_;
		my $db = $dbh->{ Name }; 
		my $db_name = $self->get_parsed_name($dbh);
		my @aKeys = $dbh->primary_key( $db_name,undef,$table );
		$self->{ $db }{ $table }{ _primary_keys } = \@aKeys;
	}
	sub row_count {
		my ($self,$table,$dbh) = @_;
		return $self->fetch_singlefield("select count(*) from $table",$dbh);	# shifting $dbh
	}
	sub fetchhash_multirow {
		my ($self,$statement,$dbh) = @_;
		my @ahResults_Rows;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			while(my $hResult_Row = $sth->fetchrow_hashref()) {
				push @ahResults_Rows, $hResult_Row;
			}
			$sth->finish(); # we're done with this query
		};
		if ($@) {
			die $@;
		} else {
			return \@ahResults_Rows;
		}
	}	
	sub fetch_multisinglefield {
		my ($self,$statement,$dbh) = @_;
		my @aValues;
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$sth->bind_columns(undef, \$value);
			while($sth->fetch()) {
				push @aValues, $value;
			}
			$sth->finish(); 
		};
		if ($@) {
			die $@;
		} else {
			return \@aValues;
		} 
	} 
	sub fetch_singlefield {
		my ($self,$statement,$dbh) = @_;
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$sth->bind_columns(undef, \$value);
			$sth->fetch();
			$sth->finish(); 
		};
		if ($@) {
			die $@;
		} else {
			return $value;
		}
	}
	sub sql_fetcharray_singlerow {
		my ($self,$statement,$dbh) = @_;
		my $aResult_Row;
		eval {	
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$aResult_Row = $sth->fetchrow_arrayref();
			$sth->finish(); 
		};
		if ($@) {
			die $@;
		} else {
			return $aResult_Row;
		}
	}
}

1;

__END__


=head1 NAME

DBIx::Compare - Compare database content

=head1 SYNOPSIS

	use DBIx::Compare;

	my $oDB_Comparison = db_comparison->new($dbh1,$dbh2);
	$oDB_Comparison->verbose;
	$oDB_Comparison->compare;
	$oDB_Comparison->deep_compare;
	$oDB_Comparison->deep_compare(@aTable_Names);	

=head1 DESCRIPTION

DBIx::Compare takes two database handles and performs comparisons of their table content. 

=head1 DATABASE CONNECT DESCRIPTORS

The database name is required for some operations. Unfortunately the variety of possible syntax for a connection description makes extraction of this difficult. This problem is worked around by placing some restrictions on the syntax:

These connection descriptions are allowed:

	"...[database|dbname]=mydb;..." or
	"mydb:..." or
	"mydb;..." 

i.e using the "database" or "dbname" keyword or else specifying the database name as the first field. 

Other variants will result in the error:
	DBIx::Compare ERROR; Cannot extract database name from connection string: ...";

=head1 COMPARISON METHODS

=head2 deep_compare, deep_compare(@aTables)

When called without any arguments, this method performs a row-by-row comparison on any table that passes the rapid comparison test (see L</compare>). Returns true if the tables are identical, false/undef if a difference was found. In verbose mode, reports differences found I<as per> L</compare>, together with the table name and row number of any differences found by the row-by-row comparison. 

When passed a list of table names, deep_compare is forced to perform the row-by-row comparison of each table, instead of only analysing those tables that pass the rapid comparison test. This can be useful to track down where the differences actually are. 

All differences can also be returned using the L</get_differences> method. 

=head2 Rapid (low-level) comparisons

=over

=item B<compare>

Performs a low level comparison. Calls the methods compare_table_lists, compare_table_fields, compare_row_counts and (if available) compare_table_stats. Returns true if no differences are found, otherwise returns undef. 

=item B<compare_table_lists>

Simple comparison of the table names. Returns true if no differences are found, otherwise returns undef. An array ref of tables unique to each database:host can be recovered with get_differences(), using the hash key C<'Tables unique to I<[db name:host]>'>

=item B<compare_table_fields>

Simple comparison of each table's field names. Returns true if no differences are found, otherwise returns undef. An array ref of fields unique to each database:host can be recovered with get_differences(), using the hash key C<'Fields unique to I<[db name:host.table]>'>

=item B<compare_row_counts>

Comparison of the row counts from each table. Can pass a table name, or will compare all tables. Returns true if no differences are found, otherwise returns undef. An array ref of tables with different row counts can be recovered with get_differences(), using the hash key C<'Row count'>. 

=item B<compare_table_stats>

Aggregate (mathematical) comparisons of each table field. For numeric fields, compares the average, minimum, maximum and standard deviation of all values. For string fields, performs these comparisons on the length (in bytes) of each string. For date/time fields, performs these comparisons on the numeric value of the date/time (when possible). Clearly, the value of these comparisons will vary hugely - but where there is enough variety in the table content, this can be informative of any differences. 

Returns true if no differences are found, or if the function is not supported for a particular database driver, or if there is no DBIx::Compare:: plug-in for that driver. Otherwise returns undef. An array ref of tables with different row counts can be recovered with get_differences(), using the hash key C<'Bad fields in table I<[db name:host.table]>'>. 

The SQL statements behind this method are provided by plug-in modules to DBIx::Compare, since the relevant SQL functions vary depending on the dialect. If a plug-in for your DBMS is not found, its easy enough to create one. 

=back

=head1 OTHER METHODS

=over

=item B<new($dbh1,$dbh2)>

You must pass two database handles at initialisation, and each database must be the same type. 

=item B<verbose>

Generates verbose output. Default is not verbose.  

=item B<get_primary_keys($table,$dbh)>

Returns the primary keys (in key order) for the given table/database, either as a list or as a comma separated string. 

=item B<get_differences>

Returns a hashref of differences between the two databases, where keys are the source of the difference, and values are an array ref of the differences found (see comparison methods above for details).

=item B<get_tables>

Returns a table list. Returns a 2D list of tables in list context, or just a list of tables in database1 in scalar context;

	my @aList = $oDB_Comparison->get_tables;	# returns (['table1','table2',etc],['table1','table2',etc])
	my $aList = $oDB_Comparison->get_tables;	# returns ['table1','table2',etc]

=item B<common_tables>

Returns a list of tables common to both databases. Recursively cals compare_table_lists() if not already called.

=item B<similar_tables>

Returns a list of tables common to both databases and with identical row counts. Recursively cals compare_table_lists() and compare_row_counts() if not already called.

=item B<field_list($table)>

Returns a list of fields for the particular table that are common in both databases. 

=back

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

With some enhancements and bug fixes from; 

Mark Kirkwood, Catalyst IT Limited, New Zealand.

mark.kirkwood@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
