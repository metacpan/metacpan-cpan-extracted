use strict;
use warnings;

package Class::DBI::MSSQL;
use base qw(Class::DBI);

our $VERSION = '0.122';

=head1 NAME

Class::DBI::MSSQL - Class::DBI for MSSQL

=head1 VERSION

version 0.122

 $Id: /my/cs/projects/cdbi-mssql/trunk/lib/Class/DBI/MSSQL.pm 27829 2006-11-11T04:02:42.956483Z rjbs  $

=head1 SYNOPSIS

	use base qw(Class::DBI::MSSQL);

	# lots of normal-looking CDBI code

=head1 DESCRIPTION

This is just a simple subclass of Class::DBI;  it makes Class::DBI play nicely
with MSSQL, at least if DBD::ODBC is providing the connection.

Here are the things it changes:

=over 4

=item * use C<SELECT @@IDENTITY> to get last autonumber value

=item * use C<INSERT INTO table DEFAULT VALUES> for C<create({})>

=back

It also implements some metadata methods, described below.

=cut

sub _auto_increment_value {
	my $self = shift;
	my $dbh  = $self->db_Main;

	my ($id) = $dbh->selectrow_array('SELECT @@IDENTITY');
	$self->_croak("Can't get last insert id") unless defined $id;
	return $id;
}

sub _insert_row {
	my $self = shift;
	my $data = shift;
	if (keys %$data) { 
		return $self->SUPER::_insert_row($data);
	} else {
		eval {
			my $sth     = $self->sql_MakeNewEmptyObj();
			$sth->execute;
			my @primary_columns = $self->primary_columns;
			$data->{ $primary_columns[0] } = $self->_auto_increment_value
				if @primary_columns == 1
				&& !defined $data->{ $primary_columns[0] };
		};
		if ($@) {
			my $class = ref $self;
			return $self->_croak(
				"Can't insert new $class: $@",
				err    => $@,
				method => 'create'
			);
		}
		return 1;
	}
}

__PACKAGE__->set_sql(MakeNewEmptyObj => 'INSERT INTO __TABLE__ DEFAULT VALUES');

=head1 METHODS

=head2 C<< set_up_table($table_name) >>

This method sets up the columns from the named table by querying MSSQL's
C<information_schema> metadata tables.  It will set up the key(s) as Primary
and all other columns as Essential.

=cut

__PACKAGE__->set_sql(desc_table => <<'SQL');
	SELECT col.table_name, col.column_name, col.data_type, ccu.constraint_name
	FROM information_schema.columns col
	LEFT JOIN information_schema.constraint_column_usage ccu
	       ON col.table_catalog = ccu.table_catalog 
	      AND col.table_schema = ccu.table_schema 
	      AND col.table_name = ccu.table_name
	      AND col.column_name = ccu.column_name
	WHERE (col.table_name = '__TABLE__')
SQL

sub set_up_table {
	my $class = shift;
	$class->table(shift || $class->table);
	(my $sth = $class->sql_desc_table)->execute;
	my (@cols, @pri);
	while (my $hash = $sth->fetch_hash) {
		my ($col) = $hash->{column_name} =~ /(\w+)/;
		if($hash->{constraint_name} =~ /^PK_/) {
			push @pri, $col;
		} else {
			push @cols, $col;
		}
	}
	$class->_croak($class->table, " has no primary key") unless @pri;
	$class->columns(Primary => @pri);
	$class->columns(Essential => @cols);
}

=head2 C<< column_type($column_name) >>

This returns the named column's datatype.

=cut

sub _column_info {
	my $self = shift;
	my $dbh  = $self->db_Main;
	
	(my $sth = $self->sql_desc_table)->execute;
	return { map { $_->{column_name} => $_ } $sth->fetchall_hash };
}

sub column_type {
	my $class = shift;
	my $col = shift or Carp::croak "Need a column for column_type";
	return $class->_column_info->{$col}->{data_type};
}

=head2 C<< autoinflate($type => $class) >>

This will automatically set up has_a() relationships for all columns of
the specified type to the given class.  If the type is "dates" it will apply to
both datetime and smalldatetime columns.  If the class is Time::Piece,
Time::Piece::MSSQL will be required.

We currently assume that all classess passed will be able to inflate
and deflate without needing extra has_a arguments.

=cut

sub autoinflate {
	my ($class, %how) = @_;
	$how{$_} ||= $how{dates} for qw/datetime smalldatetime/;
	my $info = $class->_column_info;
	foreach my $col (keys %$info) {
		(my $type = $info->{$col}->{type}) =~ s/\W.*//;
		next unless $how{$type};
		my %args;
		if ($how{$type} eq "Time::Piece") {
			eval "use Time::Piece::MSSQL";
			$class->_croak($@) if $@;
			$args{inflate} = "from_mssql_$type";
			$args{deflate} = "mssql_$type";
		}
		$class->has_a($col => $how{$type}, %args);
	}
}


=head1 WARNINGS

For one thing, there are no useful tests in this distribution.  I'll take care
of that, but right now this is all taken care of in the tests I've written for
subclasses of this class, and I don't have a lot of motivation to write new
tests just for this package.

Class::DBI's C<_init> sub has a line that reads as follows:

 if (@primary_columns == grep defined, @{$data}{@primary_columns}) {     

This will cause the primary key columns to autovivify as I<undef>, which will
make inserts fail under MSSQL.  You should change that line to the following,
which will fix the behavior.

 if (@$data{@primary_columns}
 	and @primary_columns == grep defined, @{$data}{@primary_columns}
 ) {

I can't easily subclass that routine, as it relies on lexical variables above
its scope.  I've sent a patch to Tony, which I expect to be in the next
Class::DBI release.

=head1 THANKS

...to James O'Sullivan, for graciously sending me his own solution to this
problem, which I've happily included.

...to Michael Schwern and Tony Bowden for creating and maintaining,
respectively, the excellent Class::DBI system.

...to Casey West, for his crash course on Class::DBI at OSCON '04, which
finally convinced me to just use the darn thing.

=head1 AUTHOR

Ricardo SIGNES, <C<rjbs@cpan.org>>

C<set_up_table> and C<column_type> from James O'Sullivan.

=head1 COPYRIGHT

(C) 2004-2006, Ricardo SIGNES.  Class::DBI::MSSQL is available under the same
terms as Perl itself.

=cut

1;
