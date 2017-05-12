=head1 NAME

Class::DBI::Pg::More - Enhances Class::DBI::Pg with more goodies.

=head1 SYNOPSIS

   package MyClass;
   use base 'Class::DBI::Pg::More';
   
   __PACKAGE__->set_up_table("my_table");

   # a_date is a date column in my_table. 
   # Class::DBI::Plugin::DateFormat::Pg->has_date has been
   # called for a_date implicitly.
   my $a_date_info =  __PACKAGE__->pg_column_info('a_date')
   print $a_date_info->{type}; # prints "date"

   # an_important is an important column in my_table set to not null
   print $a_date_info->{is_nullable} ? "TRUE" : "FALSE"; # prints FALSE

=head1 DESCRIPTION

This class overrides Class::DBI::Pg C<set_up_table> method to setup more
things from the database.

It recognizes date, timestamp etc. columns and calls
C<Class::DBI::Plugin::DateTime::Pg> has_* methods on them.

It also fetches some constraint information (currently C<not null>).

=cut

use strict;
use warnings FATAL => 'all';

package Class::DBI::Pg::More;
use base 'Class::DBI';

our $VERSION = '0.05';
$Class::DBI::Weaken_Is_Available = 0;

sub find_primary_key {
	my ($class, $dbh, $table) = @_;
	return $dbh->selectcol_arrayref(<<'ENDS', undef, $table);
SELECT a.attname FROM pg_class c, pg_attribute a, pg_index i, pg_namespace n,
       generate_series(0, current_setting('max_index_keys')::integer ) idx(n)
WHERE c.oid = a.attrelid AND c.oid = i.indrelid AND i.indisprimary
	AND a.attnum = i.indkey[idx.n] AND NOT a.attisdropped
	AND has_schema_privilege(n.oid, 'USAGE'::text)
	AND n.nspname NOT LIKE 'pg!_%' ESCAPE '!'
	AND has_table_privilege(c.oid, 'SELECT'::text)
	AND c.relnamespace = n.oid and c.relname = ? and nspname = 'public';
ENDS
}

sub find_columns {
	my ($class, $dbh, $table) = @_;
	return $dbh->selectall_arrayref(<<ENDS, undef, $table);
SELECT column_name, data_type, is_nullable FROM information_schema.columns
	WHERE table_name = ? and table_schema = 'public'
ENDS
}

sub _handle_pg_datetime {
	my ($class, $col, $type) = @_;
	my $func;
	if ($type eq 'date') {
		$func = "has_$type";
	} elsif ($type =~ /^(time\w*)/) {
		$func = "has_$1";
		$func .= "tz" unless $type =~ /without time zone/;
	} else {
		return;
	}
	eval "use Class::DBI::Plugin::DateTime::Pg";
	die "Unable to use CDBIP::DT::Pg: $@" if $@;
	$class->$func($col);
}

=head1 METHODS

=head2 $class->set_up_table($table, $args)

This is main entry point to the module. Please see C<Class::DBI::Pg>
documentation for its description.

This class automagically uses Class::DBI::Plugin::DateTime::Pg for date/time
fields, so you should use DateTime values with them.

=cut
sub set_up_table {
	my ( $class, $table, $opts) = @_;
	$opts ||= {};

	my $dbh = $class->db_Main;
	my @primary = @{ $opts->{Primary} || $class->find_primary_key($dbh, $table) }
		or die "$table has no primary key";

	my %infos;
	my $arr = $class->find_columns($dbh, $table);
	$class->table($table);
	$class->columns(Primary => @primary);
	$class->columns(($opts->{ColumnGroup} || 'Essential') => map { $_->[0] } @$arr);

	my $def = $dbh->selectcol_arrayref(q{ select column_default
			from information_schema.columns where column_name = ?
				and table_name = ? and table_schema = 'public' }
			, undef, $table, $primary[0])->[0];
	my ($seq) = ($def =~ /nextval\(\'(\w+)/) if $def;
	$class->sequence($seq) if $seq;

	for my $a (@$arr) {
		my $i = { type => $a->[1] };
		$class->_handle_pg_datetime($a->[0], $a->[1]);
		$i->{is_nullable} = 1 if $a->[2] eq 'YES';
		$infos{ $a->[0] } = $i;
	}
	$class->mk_classdata("Pg_Column_Infos", \%infos);
}

sub _do_execute {
	my ($self, $sql, $arg_map, @rest) = @_;
	my @args;
	if (!(ref($self) && @$arg_map)) {
		@args = @rest;
		goto OUT;
	}
	for (my $i = 0; $i < @$arg_map; $i++) {
		my $a = $arg_map->[$i];
		push @args, $a ? $self->$a : shift @rest;
	}
	push @args, @rest;
OUT:
	my $sth = $self->$sql;
	$sth->execute(@args);
	return $sth;
}

sub _do_set_sql {
	my ($class, $name, $sql, $ex, $cb, @arg_map) = @_;
	$class->set_sql($name, $sql);
	my $f = "sql_$name";
	no strict 'refs';
	*{ "$class\::$ex\_$name" } = sub {
		return $cb->(shift()->_do_execute($f, \@arg_map, @_));
	};
}

=head2 $class->set_exec_sql($name, $sql, @arg_map)

Wraps C<Ima::DBI> C<set_sql> methods to create C<exec_$name> function
which basically calls C<execute> on C<sql_$name> handle.

C<@arg_map> provides mapping of the arguments to the exec function. It can
be used to call instance methods to get execution parameters.

For example given "update __TABLE__ set col = ? where id = ?" statement
argument map (undef, "id") tells to substitute last parameter by results of the
$self->id function.

=cut
sub set_exec_sql {
	my ($class, $name, $sql, @arg_map) = @_;
	$class->_do_set_sql($name, $sql, "exec"
			, sub { return $_[0]->rows; }, @arg_map);
}

=head2 $class->set_exec_sql($name, $sql, $slice, @arg_map)

Wraps C<Ima::DBI> C<set_sql> methods to create C<fetch_$name> function
which basically calls C<execute> and C<fetchall_arrayref> on C<sql_$name>
handle.

For description of C<$slice> parameter see DBI C<fetchall_arrayref> function.

C<@arg_map> is described above.

=cut
sub set_fetch_sql {
	my ($class, $name, $sql, $slice, @arg_map) = @_;
	$class->_do_set_sql($name, $sql, "fetch", sub {
		return $_[0]->fetchall_arrayref($slice);
	}, @arg_map);
}

=head2 $class->pg_column_info($column)

Returns column information as HASHREF. Currently supported flags are:

=over

=item type - Returns data type of the column (e.g. integer, text, date etc.).

=item is_nullable - Indicates whether the C<$column> can be null.

=back

=cut
sub pg_column_info {
	my ($class, $col) = @_;
	return $class->Pg_Column_Infos->{ $col };
}

1;

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

C<Class::DBI::Pg>, C<Class::DBI::Plugin::DateTime::Pg>.

=cut

