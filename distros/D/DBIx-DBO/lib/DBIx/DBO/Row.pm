package DBIx::DBO::Row;

use 5.014;
use warnings;
use DBIx::DBO;

use Carp 'croak';
use Scalar::Util qw(blessed weaken);
use Storable ();

use overload '@{}' => sub {${$_[0]}->{array} || []}, '%{}' => sub {${$_[0]}->{hash}}, fallback => 1;

sub query_class { ${$_[0]}->{DBO}->query_class }

*_isa = \&DBIx::DBO::DBD::_isa;

=head1 NAME

DBIx::DBO::Row - An OO interface to SQL queries and results.  Encapsulates a fetched row of data in an object.

=head1 SYNOPSIS

  # Create a Row object for the `users` table
  my $row = $dbo->row('users');
  
  # Load my record
  $row->load(login => 'vlyon') or die "Where am I?";
  
  # Double my salary :)
  $row->update(salary => {FUNC => '? * 2', COL => 'salary'});
  
  # Print my email address
  print $row->{email};
  
  # Delete my boss
  $row->load(id => $row->{boss_id})->delete or die "Can't kill the boss";

=head1 METHODS

=head3 C<new>

  DBIx::DBO::Row->new($dbo, $table);
  DBIx::DBO::Row->new($dbo, $query_object);

Create and return a new C<Row> object.
The object returned represents rows in the given table/query.
Can take the same arguments as L<DBIx::DBO::Query/new> or a L<Query|DBIx::DBO::Query> object can be used.

=cut

sub new {
    my $proto = shift;
    eval { $_[0]->isa('DBIx::DBO') } or croak 'Invalid DBO Object for new Row';
    my $class = ref($proto) || $proto;
    $class->_init(@_);
}

sub _init {
    my($class, $dbo, @args) = @_;

    my $me = bless \{ DBO => $dbo, array => undef, hash => {} }, $class;
    my $parent = (@args == 1 and _isa($args[0], 'DBIx::DBO::Query'))
    ? $args[0]
    : $me->query_class->new($dbo, @args);

    if ($parent->isa('DBIx::DBO::Query')) {
        croak 'This query is from a different DBO connection' if $parent->{DBO} != $dbo;
        # We must weaken this to avoid a circular reference
        $$me->{Parent} = $parent;
        weaken $$me->{Parent};
        # Add a weak ref onto the list of attached_rows to release freed rows
        push @{ $$me->{Parent}{attached_rows} }, $me;
        weaken $$me->{Parent}{attached_rows}[-1];
    } else {
        croak 'Invalid parent for new Row';
    }
    return wantarray ? ($me, $me->tables) : $me;
}

sub _build_data {
    ${$_[0]}->{build_data} // ${$_[0]}->{Parent}{build_data};
}

=head3 C<tables>

Return a list of L<Table|DBIx::DBO::Table> objects for this row.

=cut

sub tables {
    my $me = $_[0];
    return @{ ${exists $$me->{Parent} ? $$me->{Parent} : $$me}{Tables} };
}

sub _table_idx {
    my($me, $tbl) = @_;
    my $tables = ${exists $$me->{Parent} ? $$me->{Parent} : $$me}{Tables};
    for my $i (0 .. $#$tables) {
        return $i if $tbl == $tables->[$i];
    }
    return undef;
}

sub _table_alias {
    my($me, $tbl) = @_;
    return undef if $tbl == $me;
    my $i = $me->_table_idx($tbl);
    croak 'The table is not in this query' unless defined $i;
    return $me->tables > 1 ? 't'.($i + 1) : ();
}

=head3 C<columns>

Return a list of column names.

=cut

sub columns {
    my($me) = @_;

    return $$me->{Parent}->columns if exists $$me->{Parent};

    $$me->{Columns} //= [
        @{$me->_build_data->{select}}
        ? map {
                _isa($_, 'DBIx::DBO::Table', 'DBIx::DBO::Query') ? ($_->columns) : $me->_build_col_val_name(@$_)
            } @{$me->_build_data->{select}}
        : map { $_->columns } $me->tables
    ];

    @{$$me->{Columns}};
}

*_build_col_val_name = \&DBIx::DBO::Query::_build_col_val_name;

sub _column_idx {
    my($me, $col) = @_;
    my $idx = -1;
    my @show;
    @show = @{$me->_build_data->{select}} or @show = $me->tables;
    for my $fld (@show) {
        if (_isa($fld, 'DBIx::DBO::Table')) {
            if ($col->[0] == $fld and exists $fld->{Column_Idx}{$col->[1]}) {
                return $idx + $fld->{Column_Idx}{$col->[1]};
            }
            $idx += keys %{$fld->{Column_Idx}};
            next;
        }
        $idx++;
        return $idx if not defined $fld->[1] and @{$fld->[0]} == 1 and $col == $fld->[0][0];
    }
    return undef;
}

=head3 C<column>

  $row->column($column_name);

Returns a column reference from the name or alias.

=cut

sub column {
    my($me, $col) = @_;
    my @show;
    @show = @{$me->_build_data->{select}} or @show = $me->tables;
    for my $fld (@show) {
        return $$me->{Column}{$col} //= bless [$me, $col], 'DBIx::DBO::Column'
            if (_isa($fld, 'DBIx::DBO::Table') and exists $fld->{Column_Idx}{$col})
            or (_isa($fld, 'DBIx::DBO::Query') and eval { $fld->column($col) })
            or (ref($fld) eq 'ARRAY' and exists $fld->[2]{AS} and $col eq $fld->[2]{AS});
    }
    croak 'No such column: '.$$me->{DBO}{dbd_class}->_qi($me, $col);
}

sub _inner_col {
    my($me, $col, $_check_aliases) = @_;
    $_check_aliases = $$me->{DBO}{dbd_class}->_alias_preference($me, 'column') unless defined $_check_aliases;
    my $column;
    return $column if $_check_aliases == 1 and $column = $me->_check_alias($col);
    for my $tbl ($me->tables) {
        return $tbl->column($col) if exists $tbl->{Column_Idx}{$col};
    }
    return $column if $_check_aliases == 2 and $column = $me->_check_alias($col);
    croak 'No such column'.($_check_aliases ? '/alias' : '').': '.$$me->{DBO}{dbd_class}->_qi($me, $col);
}

sub _check_alias {
    my($me, $col) = @_;
    for my $fld (@{$me->_build_data->{select}}) {
        return $$me->{Column}{$col} //= bless [$me, $col], 'DBIx::DBO::Column'
            if ref($fld) eq 'ARRAY' and exists $fld->[2]{AS} and $col eq $fld->[2]{AS};
    }
}

=head3 C<value>

  $value = $row->value($column);

Return the value in the C<$column> field.
C<$column> can be a column name or a C<Column> object.

Values in the C<Row> can also be obtained by using the object as an array/hash reference.

  $value = $row->[2];
  $value = $row->{some_column};

=cut

sub value {
    my($me, $col) = @_;
    croak 'The row is empty' unless $$me->{array};
    if (_isa($col, 'DBIx::DBO::Column')) {
        my $i = $me->_column_idx($col);
        return $$me->{array}[$i] if defined $i;
        croak 'The field '.$$me->{DBO}{dbd_class}->_qi($me, $col->[0]{Name}, $col->[1]).' was not included in this query';
    }
    return $$me->{hash}{$col} if exists $$me->{hash}{$col};
    croak 'No such column: '.$$me->{DBO}{dbd_class}->_qi($me, $col);
}

=head3 C<load>

  $row->load(id => 123);
  $row->load(name => 'Bob', status => 'Employed');

Fetch a new row using the where definition specified.
Returns the C<Row> object if the row is found and loaded successfully.
Returns an empty list if there is no row or an error occurs.

=cut

sub load {
    my $me = shift;

    $me->_detach;

    # Use Quick_Where to load a row, but make sure to restore its value afterward
    my $old_qw = $#{$$me->{build_data}{Quick_Where}};
    push @{$$me->{build_data}{Quick_Where}}, @_;
    my $sql = $$me->{DBO}{dbd_class}->_build_sql_select($me);
    my @bind = $$me->{DBO}{dbd_class}->_bind_params_select($me);
    $old_qw < 0 ? delete $$me->{build_data}{Quick_Where} : ($#{$$me->{build_data}{Quick_Where}} = $old_qw);
    delete $$me->{build_data}{Where_Bind};

    return $me->_load($sql, @bind);
}

sub _load {
    my($me, $sql, @bind) = @_;
    undef $$me->{array};
    $$me->{hash} = \my %hash;
    $$me->{DBO}{dbd_class}->_sql($me, $sql, @bind);
    my $sth = $me->rdbh->prepare($sql);
    return unless $sth and $sth->execute(@bind);

    my $i;
    my @array;
    for ($me->columns) {
        $i++;
        $sth->bind_col($i, \$hash{$_}) unless exists $hash{$_};
    }
    $$me->{array} = $sth->fetch or return;
    $sth->finish;
    $me;
}

sub _detach {
    my $me = $_[0];
    if (exists $$me->{Parent}) {
        $$me->{array} &&= \@{ $$me->{array} };
        $$me->{hash} = \%{ $$me->{hash} };
        for ($$me->{Parent}{Row}, @{ $$me->{Parent}{attached_rows} }) {
            undef $_ if defined $_ and $_ == $me;
        }
        # Store needed build_data
        $$me->{Tables} = [ @{$$me->{Parent}{Tables}} ];
        $$me->{build_data}{from_sql} = $$me->{DBO}{dbd_class}->_build_from($$me->{Parent});
        for my $f (qw(select From_Bind where order group)) {
            $$me->{build_data}{$f} = $me->_copy($$me->{Parent}{build_data}{$f}) if exists $$me->{Parent}{build_data}{$f};
        }
        # Save config from Parent
        if ($$me->{Parent}{Config} and %{$$me->{Parent}{Config}}) {
            $$me->{Config} = { %{$$me->{Parent}{Config}}, $$me->{Config} ? %{$$me->{Config}} : () };
        }
    }
    delete $$me->{Parent};
}

sub _copy {
    my($me, $val) = @_;
    return bless [$me, $val->[1]], 'DBIx::DBO::Column'
        if _isa($val, 'DBIx::DBO::Column') and $val->[0] == $$me->{Parent};
    ref $val eq 'ARRAY' ? [map $me->_copy($_), @$val] : ref $val eq 'HASH' ? {map $me->_copy($_), %$val} : $val;
}

=head3 C<update>

  $row->update(id => 123);
  $row->update(name => 'Bob', status => 'Employed');

Updates the current row with the new values specified.
Returns the number of rows updated or C<'0E0'> for no rows to ensure the value is true,
and returns false if there was an error.

Note: If C<LIMIT> is supported on C<UPDATE>s then only the first matching row will be updated
otherwise ALL rows matching the current row will be updated.

=cut

sub update {
    my $me = shift;
    croak "Can't update an empty row" unless $$me->{array};
    my @update = $$me->{DBO}{dbd_class}->_parse_set($me, @_);
    local $$me->{build_data} = $$me->{DBO}{dbd_class}->_build_data_matching_this_row($me);
    $$me->{build_data}{limit} = ($me->config('LimitRowUpdate') and $me->tables == 1) ? [1] : undef;
    my $sql = $$me->{DBO}{dbd_class}->_build_sql_update($me, @update);

    my $rv = $$me->{DBO}{dbd_class}->_do($me, $sql, undef, $$me->{DBO}{dbd_class}->_bind_params_update($me));
    $$me->{DBO}{dbd_class}->_reset_row_on_update($me, @update) if $rv and $rv > 0;
    return $rv;
}

=head3 C<delete>

  $row->delete;

Deletes the current row.
Returns the number of rows deleted or C<'0E0'> for no rows to ensure the value is true,
and returns false if there was an error.
The C<Row> object will then be empty.

Note: If C<LIMIT> is supported on C<DELETE>s then only the first matching row will be deleted
otherwise ALL rows matching the current row will be deleted.

=cut

sub delete {
    my $me = shift;
    croak "Can't delete an empty row" unless $$me->{array};
    local $$me->{build_data} = $$me->{DBO}{dbd_class}->_build_data_matching_this_row($me);
    $$me->{build_data}{limit} = ($me->config('LimitRowDelete') and $me->tables == 1) ? [1] : undef;
    my $sql = $$me->{DBO}{dbd_class}->_build_sql_delete($me, @_);

    undef $$me->{array};
    $$me->{hash} = {};
    $$me->{DBO}{dbd_class}->_do($me, $sql, undef, $$me->{DBO}{dbd_class}->_bind_params_delete($me));
}

=head3 C<is_empty>

  return $row->{id} unless $row->is_empty;

Checks to see if it's an empty C<Row>, and returns true or false.

=cut

sub is_empty {
    my $me = shift;
    return not defined $$me->{array};
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

sub dbo { ${$_[0]}->{DBO} }
sub dbh { ${$_[0]}->{DBO}->dbh }
sub rdbh { ${$_[0]}->{DBO}->rdbh }

=head3 C<config>

  $row_setting = $row->config($option);
  $row->config($option => $row_setting);

Get or set the C<Row> config settings.  When setting an option, the previous value is returned.  When getting an option's value, if the value is undefined, the C<Query> object (If the the C<Row> belongs to one) or L<DBIx::DBO|DBIx::DBO>'s value is returned.

See L<DBIx::DBO/"Available config options">.

=cut

sub config {
    my $me = shift;
    my $opt = shift;
    return $$me->{DBO}{dbd_class}->_set_config($$me->{Config} //= {}, $opt, shift) if @_;
    $$me->{DBO}{dbd_class}->_get_config($opt, $$me->{Config} //= {}, defined $$me->{Parent} ? ($$me->{Parent}{Config}) : (), $$me->{DBO}{Config}, \%DBIx::DBO::Config);
}

if (eval { Storable->VERSION(2.38) }) {
    *STORABLE_freeze = sub {
        my($me, $cloning) = @_;
        $me->_detach;
        my $frozen = Storable::nfreeze($$me);
        return $frozen;
    };

    *STORABLE_thaw = sub {
        my($me, $cloning, @frozen) = @_;
        $$me = \%{ Storable::thaw(@frozen) }; # Copy the hash, or Storable will wipe it out
    };
}

sub DESTROY {
    undef %${$_[0]};
}

1;

__END__

=head1 SUBCLASSING

Classes can easily be created for tables in your database.
Assume you want to create a simple C<Row> class for a "Users" table:

  package My::User;
  use parent 'DBIx::DBO::Row';
  
  sub new {
      my($class, $dbo) = @_;
      
      return $class->SUPER::new($dbo, 'Users');
  }

=head3 C<query_class>

If you want this Row to belong to an existing Query class,
just define the C<query_class> method to return the class name of the parent Query.

  package My::User;
  use parent 'DBIx::DBO::Row';
  
  sub query_class { 'My::Users' }

=head1 SEE ALSO

L<DBIx::DBO>


=cut

