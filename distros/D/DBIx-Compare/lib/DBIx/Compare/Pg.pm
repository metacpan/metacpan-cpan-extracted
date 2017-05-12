package DBIx::Compare::Pg;

use 5.006;
use strict;
use warnings;
require DBIx::Compare;

our $VERSION = '1.4';

{ package pg_comparison;
	
	our @ISA = qw( db_comparison );

	sub compare_string_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG(OCTET_LENGTH($field)), STDDEV(OCTET_LENGTH($field)), MIN(OCTET_LENGTH($field)), MAX(OCTET_LENGTH($field))
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
	sub compare_numeric_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG($field), STDDEV($field), MIN($field), MAX($field)
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
	sub compare_datetime_field {
		my ($self,$table,$field) = @_;
		my $statement = "
			SELECT AVG(DATE_PART('epoch', $field)::numeric), STDDEV(DATE_PART('epoch', $field)::numeric), MIN(DATE_PART('epoch', $field)::numeric), MAX(DATE_PART('epoch', $field)::numeric)
			FROM $table
		";
		return $self->do_compare_field($statement);
	}
	# implement SHOW TABLES but avoid system schema, slony ancillary ones
	# and the information schema
	sub get_tables {
		my $self = shift;
		unless (defined $self->{ _db1 }{ _Tables } && $self->{ _db2 }{ _Tables }){
			my ($dbh1,$dbh2) = $self->get_dbh;
			my $statement = "
				SELECT schemaname||'.'||tablename 
				FROM pg_catalog.pg_tables 
				WHERE substr(schemaname,1,3) != 'pg_' 
				AND substr(schemaname,1,1) != '_' 
				AND schemaname != 'information_schema'
				ORDER BY schemaname, tablename
				";
			$self->{ _db1 }{ _Tables } = $self->fetch_multisinglefield($statement,$dbh1);
			$self->{ _db2 }{ _Tables } = $self->fetch_multisinglefield($statement,$dbh2);
		}
		if (wantarray()){
			return ( $self->{ _db1 }{ _Tables },$self->{ _db2 }{ _Tables } );
		} else {
			return $self->{ _db1 }{ _Tables };
		}
	}
	# Separate schema and table name for primary_key_info call.
	sub set_primary_keys {
		my ($self,$table,$dbh) = @_;
		my $db_name = $dbh->{ Name };	
		my ($schema, $tableshort) = split(/\./, $table);
		my @aKeys = $dbh->primary_key(undef, $schema, $tableshort );

		$self->{ $db_name }{ $table }{ _primary_keys } = \@aKeys;
	}
	# implement DESCRIBE
	sub set_field_info {
		my ($self,$table) = @_;
		my @aDBH = $self->get_dbh;
		my ($schema, $tableshort) = split(/\./, $table);
		for my $dbh (@aDBH){
			my $db_name = $dbh->{ Name };	
			my $sth = $dbh->column_info(undef, $schema, $tableshort, undef);

			my @aCols = @{$sth->fetchall_arrayref};
			my @aFields = ();
			for my $aRef (@aCols) {
				my $field = @$aRef[3];
				my $type = @$aRef[5];
				push (@aFields, $field);
				$self->{ $db_name }{ $table }{ Fields }{ $field } = $type;
			}
			my @aSorted_Fields = sort @aFields;
			$self->{ $db_name }{ $table }{ Sorted_Fields } = \@aSorted_Fields;
		}
	}
	# do the same logic as super, but explicitly use a CURSOR to avoid libpq
	# trying to buffer both tables in memory (a huge trap for the unwary I must
	# say)
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

			# declare cursor for each table
			$dbh1->do("DECLARE cur CURSOR WITH HOLD FOR $statement");
			$dbh2->do("DECLARE cur CURSOR WITH HOLD FOR $statement");

			my $sth1 = $dbh1->prepare("FETCH 100 FROM cur");
			my $sth2 = $dbh2->prepare("FETCH 100 FROM cur");

			my $row = 0;
			
			# fetch each row.
			ROW:while(1) {

				$sth1->execute;
				$sth2->execute;
				last if ($sth1->rows == 0);

				while (my $aResult_Row1 = $sth1->fetchrow_arrayref()) {
					$row++;
					my $aResult_Row2 = $sth2->fetchrow_arrayref();
					my @aResult_Row1 = map { $_ ? $_ : '' } @$aResult_Row1;
					my @aResult_Row2 = map { $_ ? $_ : '' } @$aResult_Row2;	
					unless (join(',',@aResult_Row1) eq join(',',@aResult_Row2)){
						warn "Discrepancy in table '$table' at row $row\n";
						$self->add_errors("Discrepancy in table $table",$row);
						$same = undef;
						$sth1->finish;			# finish with statements
						$sth2->finish;
						$dbh1->do("CLOSE cur");	# ...and cursors
						$dbh2->do("CLOSE cur");
						next TABLE;
					}
				}

			}
			$sth1->finish;		# finish with statements
			$sth2->finish;

			$dbh1->do("CLOSE cur");
			$dbh2->do("CLOSE cur");
		}
		return $same;
	}
}

1;

__END__


=head1 NAME

DBIx::Compare::Pg - Compare PostgreSQL database content

=head1 SYNOPSIS

	use DBIx::Compare::Pg;

	my $oDB_Comparison = db_comparison->new($dbh1,$dbh2);
	$oDB_Comparison->verbose;
	$oDB_Comparison->compare;
	$oDB_Comparison->deep_compare;
	$oDB_Comparison->deep_compare(@aTable_Names);   

=head1 DESCRIPTION

DBIx::Compare::Pg takes two PostgreSQL database handles and performs comparisons of their table content. See L<DBIx::Compare|DBIx::Compare> for more information.

=head1 PORTING NOTES

=head2 deep_compare, deep_compare(@aTables)

Use is made of CURSORs to avoid triggering an OOM condition due to libpq's buffering behaviour when comparing tables larger than physical memory.

=head2 get_tables

All non-system schemata are searched. Some (hopefully) sensible decisions are made concerning skipping possible Slony schemata (beginning with "_"). Likewise the information schema is passed over.

=head1 SEE ALSO

L<DBIx::Compare|DBIx::Compare>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

This particular module has seen some hacking from;

Mark Kirkwood, Catalyst IT Limited, New Zealand.

mark.kirkwood@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
