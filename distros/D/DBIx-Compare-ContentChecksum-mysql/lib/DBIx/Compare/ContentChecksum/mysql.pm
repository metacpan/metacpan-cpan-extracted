package DBIx::Compare::ContentChecksum::mysql;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.2';

require DBIx::Compare;

{ package compare_mysql_checksum;

	our @ISA = qw( db_comparison );
	
	sub compare {
		my $self = shift;
		
		my $tables = $self->compare_table_lists;
		my $tfields = $self->compare_table_fields;
		my $rows = $self->compare_row_counts;
		my $fields = $self->compare_fields_checksum;

		if ($tables && $tfields && $rows && $fields){
			return 1;
			warn "No differences were found\n";
		} else {
			unless ($tables){
				warn 	"Table Lists are different\n".
						"\tComparing the common tables...\n";
			}
			unless ($rows){
				warn 	"Row counts in some tables are different\n".
						"\tComparing the content of tables with the same row count...\n";
			}	
			unless ($tfields){
				warn 	"Table fields are different\n".
						"\tComparing the common fields...\n";
			}
			unless ($fields){
				warn 	"Data are different in some tables\n";
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
	sub compare_fields_checksum {
		my $self = shift;
		my $aTables;
		if (@_){
			$aTables = [shift];
		} else {
			$aTables = $self->similar_tables;
		}
		my ($dbh1,$dbh2) = $self->get_dbh;
		my $same = 1;
		TABLE:for my $table (@$aTables){
			my @aErrors = ();
			my @aFields = $self->field_list($table);
			FIELD:for my $field (@aFields){
				my ($string1,$string2) = $self->field_checksum($table,$field);
				unless ((($string1 && $string2) && ($string1 eq $string2)) || (!$string1 && !$string2)){
					push(@aErrors, $field);
				}
			}
			if (@aErrors){
				$self->add_errors("Table $table fields",@aErrors);	
				$same = undef;		
			}
		}
		return $same;
	} 
	sub field_checksum {
		my $self = shift;
		my ($table,$field) = @_;
		my @aDBH = $self->get_dbh;
		my @aChecksum;
		for my $dbh (@aDBH){
			my $statement = "select md5(group_concat($field";
			my $statement_desc = $statement;
			if (my $primary_keys = $self->get_primary_keys($table,$dbh)){
				$statement .= " order by $primary_keys";
				# make the descending keys
				$statement_desc .= " order by $primary_keys desc";
				$statement_desc =~ s/,/ desc,/g;	# descend compound keys
			}
			$statement .= ")) from $table";
			$statement_desc .= ")) from $table";
			my $checksum = $self->fetch_singlefield($statement,$dbh);
			unless (($statement eq $statement_desc)||!$checksum){	# i.e. no primary key, or $checksum = null
				my $checksum2 = $self->fetch_singlefield($statement_desc,$dbh);
				$checksum .= $checksum2;
			}
			push (@aChecksum,$checksum);
		}
		return @aChecksum;
	}
	sub do_group_concat_max_len {
		my $self = shift;
		my $concat_length = shift;
		$self->{ _group_concat_max_len } = $concat_length;
		my ($dbh1,$dbh2) = $self->get_dbh;
		eval {
			$dbh1->do("set group_concat_max_len = $concat_length");
			$dbh2->do("set group_concat_max_len = $concat_length");
		};
		if ($@) {
			die "DBIx::Compare::ContentChecksum::mysql ERROR: Could not 'set group_concat_max_len'\n".$@;
		} 
	}
	sub group_concat_max_len {
		my $self = shift;
		if (@_){
			$self->do_group_concat_max_len(shift);
		} else {
			if (defined $self->{ _group_concat_max_len }){
				return $self->{ _group_concat_max_len };
			} else {
				return $self->mysql_group_concat_max_len;	# mysql default
			}
		}
	}
	sub mysql_group_concat_max_len {
		my $self = shift;
		my ($dbh1,$dbh2) = $self->get_dbh;
		my @aLength1 = $self->fetchlist_singlerow("show variables like 'group_concat_max_len'",$dbh1);
		my @aLength2 = $self->fetchlist_singlerow("show variables like 'group_concat_max_len'",$dbh2);
		return ($aLength1[1],$aLength2[1]);
	}
	sub fetchlist_singlerow {
		my $self = shift;
		my $statement = shift;
		my $dbh = shift;		
		my @aResult_Row;
		eval {	
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			@aResult_Row = $sth->fetchrow_array();
			$sth->finish(); 
		};
		if ($@) {
			die $@;
		} else {
			if (@aResult_Row){
				return @aResult_Row;
			} else {
				return;
			}
		}
	}
	sub fetch_singlefield {
		my $self = shift;
		my $statement = shift;
		my $dbh = shift;	
		my $value;
		eval {
			my $sth = $dbh->prepare($statement);
			$sth->execute(); 
			$sth->bind_columns(undef, \$value);
			$sth->fetch();
			### looking for mysql warnings
			if ($sth->{mysql_warning_count}){
				die "*** warning ***\n\t$statement\n";
			}
			$sth->finish(); 
		};
		if ($@) {
			die $@;
		} else {
			return $value;
		}
	}

}


1;

__END__


=head1 NAME

DBIx::Compare::ContentChecksum::mysql - Extension to L<DBIx::Compare|DBIx::Compare>, enables more detailed comparison of MySQL databases.

=head1 SYNOPSIS

	use DBIx::Compare::ContentChecksum::mysql;

	my $oDB_Comparison = compare_mysql_checksum->new($dbh1,$dbh2);
	$oDB_Comparison->group_concat_max_len(10000000);
	$oDB_Comparison->compare;

=head1 DESCRIPTION

DBIx::Compare::ContentChecksum::mysql takes two MySQL database handles and performs a low level comparison of their table content. It was developed to compare databases before and after table optimisation, but would be useful in any scenario where you need to check that two databases are identical.

DBIx::Compare::ContentChecksum::mysql utilises the MySQL functions 'GROUP_CONCAT' and 'MD5' to generate MD5 checksums from each field of a table, ordered by their primary keys, both ascending and descending. Then it simply compares the checksums returned from each database and prints out a list of the tables/fields in which differences were found. 

MySQL has a built in variable called C<group_concat_max_len>. This limits the length of values returned by the C<group_concat> function, truncating longer values. Helpfully, MySQL will issue a warning to let you know that the returned value has been truncated. The default value for C<group_concat_max_len> is a paltry 1024 (bytes, I assume) which isn't useful for much. If your database is likely to generate larger concatenated values, then calculate/determine/guess the C<group_concat_max_len> you'll need and set it with the method L</"group_concat_max_len()">. See the L</"DISCLAIMER"> below.

=head2 Caveats

Its worth noting that while this process can conclusively prove that two databases are different, it can only indicate that its likely two databases are identical. My understanding of the way MD5 works is that identical checksums will provide a very high probability that the inputs to the algorithm were identical. DBIx::Compare::ContentChecksum::mysql attempts to improve upon this probability by generating two separate checksums for each field, sorted by ascending or descending primary keys, which it concatenates prior to comparison. (Its conjecture on my part that this improves the comparison, but please feel free to let me know if that's not the case).

Regardless there could always be occassions where the table contents are indeed different, but where the same checksum is produced. For instance, if a field in table 1 has values(1,21), whereas table 2 has values(12,1), then the GROUP_CONCAT function will return '121' in both cases and in both sort orders, and the resulting MD5 checksum will be identical. You'll have to judge for yourself if this kind of issue is likely in your schema, and whether this is a sensible approach to testing your database content.

One issue I discovered during testing of this module is that in some cases, identical data in two tables of different Engine types (MyISAM and InnoDB) will return different MD5 checksums. I've no idea how that happens, but hopefully someone will tell me.... Currently the module does not check the Engine types, and can't bring this to your attention other than telling you the tables are different. 

=head1 METHODS

=over

=item B<compare>

Performs the comparison. Calls the methods compare_table_lists, compare_table_fields, compare_row_counts and compare_fields_checksum in order, each method comparing tables and fields that have passed the preceeding test. Returns true if no differences are found, otherwise returns undef. 

=item B<compare_fields_checksum>

Comparison of the MD5 checksum of each concatenated field. Can pass a table name, or will compare all tables. Returns true if no differences are found, otherwise returns undef. An array ref of fields that return different checksums can be recovered with get_differences(), using the hash key C<'Table I<[table name]> fields'>.

=item B<field_checksum($table,$field)>

Returns the combined MD5 checksum for the given table/field. Actually this is two joined checksums - one of the group_concat sorted by ascending primary key, and the other sorted by descending key (or by descending each key in the case of a compound primary key). 

=item B<group_concat_max_len()>

Set the MySQL variable C<group_concat_max_len>. This defaults to 1024, but you might need a larger value depending on your data. 

=back

=head1 DISCLAIMER

I have no idea how big a concatenated value would have to be to cause havoc with your system..... I took care to gradually test the limits of my own system before I risked crashing everything spectacularly, and would suggest you do the same. I accept no responsibility for the consequences of using this module to test a database with billions of rows, containing huge text fields, or massive blobs, and then wonder why it dies... (In fact, this module has not even been tested on blobs, and I don't even know if you can concatenate them).  

Having said that, a dual-Quad-core-Xeon MySQL server with 4Gb of RAM and a C<group_concat_max_len> value of 1,000,000,000 was happy (albeit a bit slow) concatenating 100,000,000 rows of a varchar(20) with an average length of 7.5. This is only a guide to the possibilities, and is in no way a recommendation or formula for success. 

=head1 SEE ALSO

L<DBIx::Compare|DBIx::Compare>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut