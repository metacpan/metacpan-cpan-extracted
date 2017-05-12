package DBIx::DBO::Table;

use strict;
use warnings;
use Carp 'croak';

use overload '**' => \&column, fallback => 1;

sub _row_class { $_[0]{DBO}->_row_class }

*_isa = \&DBIx::DBO::DBD::_isa;

=head1 NAME

DBIx::DBO::Table - An OO interface to SQL queries and results.  Encapsulates a table in an object.

=head1 SYNOPSIS

  # Create a Table object
  my $table = $dbo->table('my_table');
  
  # Get a column reference
  my $column = $table ** 'employee_id';
  
  # Quickly display my employee id
  print $table->fetch_value('employee_id', name => 'Vernon');
  
  # Find the IDs of fired employees
  my @fired = @{ $table->fetch_column('id', status => 'fired');
  
  # Insert a new row into the table
  $table->insert(employee_id => 007, name => 'James Bond');
  
  # Remove rows from the table where the name IS NULL
  $table->delete(name => undef);

=head1 DESCRIPTION

C<Table> objects are mostly used for column references in a L<Query|DBIx::DBO::Query>.
They can also be used for INSERTs, DELETEs and simple lookups (fetch_*).

=head1 METHODS

=head3 C<new>

  DBIx::DBO::Table->new($dbo, $table);
  # or
  $dbo->table($table);

Create and return a new C<Table> object.
The C<$table> argument that specifies the table can be a string containing the table name, C<'customers'> or C<'history.log'>, it can be an arrayref of schema and table name C<['history', 'log']> or as another Table object to clone.

=cut

sub new {
    my $proto = shift;
    eval { $_[0]->isa('DBIx::DBO') } or croak 'Invalid DBO Object';
    my $class = ref($proto) || $proto;
    $class->_init(@_);
}

sub _init {
    my($class, $dbo, $table) = @_;
    (my $schema, $table, my $info) = $dbo->table_info($table);
    bless { %$info, Schema => $schema, Name => $table, DBO => $dbo, LastInsertID => undef }, $class;
}

=head3 C<tables>

Return a list of C<Table> objects, which will always be this C<Table> object.

=cut

sub tables {
    wantarray ? $_[0] : 1;
}

sub _table_alias {
    undef;
}

=head3 C<name>

  $table_name = $table->name;
  ($schema_name, $table_name) = $table->name;

In scalar context it returns the name of the table in list context the schema and table names are returned.

=cut

sub name {
    wantarray ? @{$_[0]}{qw(Schema Name)} : $_[0]->{Name};
}

sub _from {
    my $me = shift;
    defined $me->{_from} ? $me->{_from} : ($me->{_from} = $me->{DBO}{dbd_class}->_qi($me, @$me{qw(Schema Name)}));
}

=head3 C<columns>

Return a list of column names.

=cut

sub columns {
    @{$_[0]->{Columns}};
}

=head3 C<column>

  $table->column($column_name);
  $table ** $column_name;

Returns a reference to a column for use with other methods.
The C<**> method is a shortcut for the C<column> method.

=cut

sub column {
    my($me, $col) = @_;
    croak 'Missing argument for column' unless defined $col;
    croak 'Invalid column '.$me->{DBO}{dbd_class}->_qi($me, $col).' in table '.$me->_from
        unless exists $me->{Column_Idx}{$col};
    $me->{Column}{$col} ||= bless [$me, $col], 'DBIx::DBO::Column';
}
*_inner_col = \&column;

=head3 C<row>

Returns a new empty L<Row|DBIx::DBO::Row> object for this table.

=cut

sub row {
    my $me = shift;
    $me->_row_class->new($me->{DBO}, $me);
}

=head3 C<fetch_row>

  $table->fetch_row(%where);

Fetch the first matching row from the table returning it as a L<Row|DBIx::DBO::Row> object.

The C<%where> is a hash of field/value pairs.
The value can be a simple SCALAR or C<undef> for C<NULL>
It can also be a SCALAR reference, which will be used without quoting, or an ARRAY reference for multiple C<IN> values.

  $someone = $table->fetch_row(age => 21, join_date => \'CURDATE()', end_date => undef);
  $a_child = $table->fetch_row(name => \'NOT NULL', age => [5 .. 15]);

=cut

sub fetch_row {
    my $me = shift;
    $me->row->load(@_);
}

=head3 C<fetch_value>

  $table->fetch_value($column, %where);

Fetch the first matching row from the table returning the value in one column.

=cut

sub fetch_value {
    my($me, $col) = splice @_, 0, 2;
    my @bind;
    $col = $me->{DBO}{dbd_class}->_build_val($me, \@bind, $me->{DBO}{dbd_class}->_parse_col_val($me, $col));
    my $sql = "SELECT $col FROM ".$me->_from;
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $me->{DBO}{dbd_class}->_build_quick_where($me, \@bind, @_);
    my $ref = $me->{DBO}{dbd_class}->_selectrow_arrayref($me, $sql, undef, @bind);
    return $ref && $ref->[0];
}

=head3 C<fetch_hash>

  $table->fetch_hash(%where);

Fetch the first matching row from the table returning it as a hashref.

=cut

sub fetch_hash {
    my $me = shift;
    my $sql = 'SELECT * FROM '.$me->_from;
    my @bind;
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $me->{DBO}{dbd_class}->_build_quick_where($me, \@bind, @_);
    $me->{DBO}{dbd_class}->_selectrow_hashref($me, $sql, undef, @bind);
}

=head3 C<fetch_column>

  $table->fetch_column($column, %where);

Fetch all matching rows from the table returning an arrayref of the values in one column.

=cut

sub fetch_column {
    my($me, $col) = splice @_, 0, 2;
    my @bind;
    $col = $me->{DBO}{dbd_class}->_build_val($me, \@bind, $me->{DBO}{dbd_class}->_parse_col_val($me, $col));
    my $sql = "SELECT $col FROM ".$me->_from;
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $me->{DBO}{dbd_class}->_build_quick_where($me, \@bind, @_);
    $me->{DBO}{dbd_class}->_sql($me, $sql, @bind);
    return $me->rdbh->selectcol_arrayref($sql, undef, @bind);
}

=head3 C<insert>

  $table->insert(name => 'Richard', age => 103);

Insert a row into the table.  Returns true on success or C<undef> on failure.

On supporting databases you may also use C<$table-E<gt>last_insert_id> to retreive
the autogenerated ID (if there was one) from the last inserted row.

=cut

sub insert {
    my $me = shift;
    croak 'Called insert() without args on table '.$me->_from unless @_;
    croak 'Wrong number of arguments' if @_ & 1;
    my @cols;
    my @vals;
    my @bind;
    my %remove_duplicates;
    while (@_) {
        my @val = $me->{DBO}{dbd_class}->_parse_val($me, pop);
        my $col = $me->{DBO}{dbd_class}->_build_col($me, $me->{DBO}{dbd_class}->_parse_col($me, pop));
        next if $remove_duplicates{$col}++;
        push @cols, $col;
        push @vals, $me->{DBO}{dbd_class}->_build_val($me, \@bind, @val);
    }
    my $sql = 'INSERT INTO '.$me->_from.' ('.join(', ', @cols).') VALUES ('.join(', ', @vals).')';
    $me->{DBO}{dbd_class}->_sql($me, $sql, @bind);
    my $sth = $me->dbh->prepare($sql) or return undef;
    my $rv = $sth->execute(@bind) or return undef;
    $me->{LastInsertID} = $me->{DBO}{dbd_class}->_save_last_insert_id($me, $sth);
    return $rv;
}

=head3 C<last_insert_id>

  $table->insert(name => 'Quentin');
  my $row_id = $table->last_insert_id;

Retreive the autogenerated ID (if there was one) from the last inserted row.

Returns the ID or undef if it's unavailable.

=cut

sub last_insert_id {
    my $me = shift;
    $me->{LastInsertID};
}

=head3 C<bulk_insert>

  $table->bulk_insert(
      columns => [qw(id name age)], # Optional
      rows => [{name => 'Richard', age => 103}, ...]
  );
  $table->bulk_insert(
      columns => [qw(id name age)], # Optional
      rows => [[ undef, 'Richard', 103 ], ...]
  );

Insert multiple rows into the table.
Returns the number of rows inserted or C<undef> on failure.

The C<columns> need not be passed in, and will default to all the columns in the table.

On supporting databases you may also use C<$table-E<gt>last_insert_id> to retreive
the autogenerated ID (if there was one) from the last inserted row.

=cut

sub bulk_insert {
    my($me, %opt) = @_;
    croak 'The "rows" argument must be an arrayref' if ref $opt{rows} ne 'ARRAY';
    my $sql = 'INSERT INTO '.$me->_from;

    my @cols;
    if (defined $opt{columns}) {
        @cols = map $me->column($_), @{$opt{columns}};
        $sql .= ' ('.join(', ', map $me->{DBO}{dbd_class}->_build_col($me, $_), @cols).')';
        @cols = map $_->[1], @cols;
    } else {
        @cols = @{$me->{Columns}};
    }
    $sql .= ' VALUES ';

    $me->{DBO}{dbd_class}->_bulk_insert($me, $sql, \@cols, %opt);
}

=head3 C<delete>

  $table->delete(name => 'Richard', age => 103);

Delete all rows from the table matching the criteria.  Returns the number of rows deleted or C<undef> on failure.

=cut

sub delete {
    my $me = shift;
    my $sql = 'DELETE FROM '.$me->_from;
    my @bind;
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $me->{DBO}{dbd_class}->_build_quick_where($me, \@bind, @_);
    $me->{DBO}{dbd_class}->_do($me, $sql, undef, @bind);
}

=head3 C<truncate>

  $table->truncate;

Truncate the table.  Returns true on success or C<undef> on failure.

=cut

sub truncate {
    my $me = shift;
    $me->{DBO}{dbd_class}->_do($me, 'TRUNCATE TABLE '.$me->_from);
}

=head2 Common Methods

These methods are accessible from all DBIx::DBO* objects.

=head3 C<dbo>

The C<DBO> object.

=head3 C<dbh>

The I<read-write> C<DBI> handle.

=head3 C<rdbh>

The I<read-only> C<DBI> handle, or if there is no I<read-only> connection, the I<read-write> C<DBI> handle.

=cut

sub dbo { $_[0]{DBO} }
sub dbh { $_[0]{DBO}->dbh }
sub rdbh { $_[0]{DBO}->rdbh }

=head3 C<config>

  $table_setting = $table->config($option);
  $table->config($option => $table_setting);

Get or set the C<Table> config settings.  When setting an option, the previous value is returned.  When getting an option's value, if the value is undefined, the L<DBIx::DBO|DBIx::DBO>'s value is returned.

See L<DBIx::DBO/Available_config_options>.

=cut

sub config {
    my $me = shift;
    my $opt = shift;
    return $me->{DBO}{dbd_class}->_set_config($me->{Config} ||= {}, $opt, shift) if @_;
    $me->{DBO}{dbd_class}->_get_config($opt, $me->{Config} ||= {}, $me->{DBO}{Config}, \%DBIx::DBO::Config);
}

sub DESTROY {
    undef %{$_[0]};
}

1;

__END__

=head1 SEE ALSO

L<DBIx::DBO>

=cut

