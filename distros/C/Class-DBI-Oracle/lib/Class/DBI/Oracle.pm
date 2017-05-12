package Class::DBI::Oracle;

=head1 NAME

Class::DBI::Oracle - Extensions to Class::DBI for Oracle

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI::Oracle';
  Music::DBI->set_db('Main', 'dbi:Oracle:tnsname', 'username', 'password');

  package Artist;
  use base 'Music::DBI';
  __PACKAGE__->set_up_table('Artist');
  
  # ... see the Class::DBI documentation for details on Class::DBI usage

=head1 DESCRIPTION

This is an extension to Class::DBI that currently implements:

	* A sequence fix for Oracle databases.
	
	* Automatic column name discovery.
	
	* Automatic primary key detection.

	* Sequence name guessing.

	* Proper aliasing of reserved words.

Instead of setting Class::DBI as your base class, use this.

=head1 BUGS

The sequence guessing is just that. If your naming convention follows the
defacto standard of TABLENAME_SEQ, and you only use one sequence per table,
this will work.

The primary and column name detection lowercases all names found. This is
probably what you want. If it's not, don't use set_up_table.

=head1 AUTHOR

Teodor Zlatanov

Dan Sully E<lt>daniel-cpan@electricrain.comE<gt> added initial column, primary key and sequence finding.

Jay Strauss E<lt>classdbi@heyjay.comE<gt> updated column, primary key, and sequence finding. Added aliasing reserved words

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::mysql> L<Class::DBI::Pg>

=cut

use strict;
use base 'Class::DBI';

use vars qw($VERSION);
$VERSION = '0.51';

# Setup an alias if the tablename is an Oracle reserved word - 
# for example if the class name is: user
# make the table_alias q["user"]
#
# Note: actually not all oracle reserved words (v$reserved_words) seem
# to be a problem, but these have been identified

my @problemWords = qw{
	ACCESS ADD ALL ALTER AND ANY AS ASC AUDIT BETWEEN BY CHAR CHECK CLUSTER 
	COLUMN COMMENT COMPRESS CONNECT CREATE CROSS CURRENT CURRENT_DATE 
	CURRENT_TIMESTAMP CURSOR_SPECIFIC_SEGMENT DATE DBTIMEZONE DECIMAL 
	DEFAULT DELETE DESC DISTINCT DROP ELSE ESCAPE EXCLUSIVE EXISTS FALSE 
	FILE FLOAT FOR FROM GRANT GROUP HAVING IDENTIFIED IMMEDIATE IN INCREMENT
	INDEX INITIAL INSERT INTEGER INTERSECT INTO IS JOIN LDAP_REG_SYNC_INTERVAL
	LEVEL LIKE LOCALTIMESTAMP LOCK LOGICAL_READS_PER_SESSION LONG MAXEXTENTS
	MINUS MLSLABEL MODE MODIFY NLS_SORT NOAUDIT NOCOMPRESS NOT NOWAIT NULL 
	NUMBER OF OFFLINE ON ONLINE OPTION OR ORDER PASSWORD_VERIFY_FUNCTION 
	PRIOR PRIVILEGES PUBLIC RAW RENAME RESOURCE REVOKE ROW ROWID ROWNUM ROWS
	SELECT SESSION SESSIONTIMEZONE SET SHARE SIZE SMALLINT START SUCCESSFUL
	SYNONYM SYSDATE SYSTIMESTAMP SYS_OP_BITVEC SYS_OP_ENFORCE_NOT_NULL$ TABLE
	THEN TO TRIGGER UID UNION UNIQUE UPDATE USER VALIDATE VALUES VARCHAR 
	VARCHAR2 VIEW WHENEVER WHERE WITH
};

sub _die { require Carp; Carp::croak(@_); } 

sub set_up_table {
	my($class, $table) = @_;
	my $dbh = $class->db_Main();

	$class->table($table);

	$table = uc $table;

	# alias the table if needed.
	(my $alias = $class) =~ s/.*:://g;
	$class->table_alias(qq["$alias"]) if grep /$alias/i, @problemWords;

	# find the primary key and column names.
	my $sql = qq[
		select 	lower(a.column_name), b.position
		from 	user_tab_columns a,
				(
				select 	column_name, position
				from   	user_constraints a, user_cons_columns b
				where 	a.constraint_name = b.constraint_name
				and	a.constraint_type = 'P'
				and	a.table_name = ?
				) b
		where 	a.column_name = b.column_name (+)
		and	a.table_name = ?
		order by position, a.column_name];

	my $sth = $dbh->prepare($sql);
	$sth->execute($table,$table);
	
	my $col = $sth->fetchall_arrayref;
	
	$sth->finish();

	# deal with old revisions
	my $msg;
	my @primary = ();

	$msg = qq{has no primary key} unless $col->[0][1];

	# Class::DBI >= 0.93 can use multiple-primary-column keys.
	if ($Class::DBI::VERSION >= 0.93) {

		map { push @primary, $_->[0] if $_->[1] } @$col;

	} else {

		$msg = qq{has a composite primary key} if $col->[1][1];

		push @primary, $col->[0][0];
	}

	_die('The "',$class->table,qq{" table $msg}) if $msg;

	$class->columns(All => map {$_->[0]} @$col);
	$class->columns(Primary => @primary);

	# attempt to guess the sequence from the table name.
	# this won't work if there is inconsistent naming.
	#
	# This is potentially very dangerous code, there could be many
	# sequences with the same table name embedded, probably should 
	# only use the sequence if it's the only one that is found with the
	# same tablename

	# Go and get all the sequences where the table name is within the
	# name of the sequence
	$sql = qq[
		select	sequence_name
		from	user_sequences
		where	sequence_name like (?)
	];
	
	$sth = $dbh->prepare($sql);
	$sth->execute("\%$table\%");
	my @sequence = map {$_->[0]} @{$sth->fetchall_arrayref};
	$sth->finish();

	$class->sequence($sequence[0]) unless $#sequence;

}

     __PACKAGE__->set_sql('Nextval', <<'');
SELECT %s.NEXTVAL from DUAL

1;
