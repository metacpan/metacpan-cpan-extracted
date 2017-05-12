package DBIx::DBO::Row;

use strict;
use warnings;
use Carp 'croak';
use Scalar::Util qw(blessed weaken);
use Storable ();

use overload '@{}' => sub {${$_[0]}->{array} || []}, '%{}' => sub {${$_[0]}->{hash}}, fallback => 1;

sub _table_class { ${$_[0]}->{DBO}->_table_class }

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
Can take the same arguments as L<DBIx::DBO::Table/new> or a L<Query|DBIx::DBO::Query> object can be used.

=cut

sub new {
    my $proto = shift;
    eval { $_[0]->isa('DBIx::DBO') } or croak 'Invalid DBO Object for new Row';
    my $class = ref($proto) || $proto;
    $class->_init(@_);
}

sub _init {
    my($class, $dbo, $parent) = @_;
    croak 'Missing parent for new Row' unless defined $parent;

    my $me = bless \{ DBO => $dbo, array => undef, hash => {} }, $class;
    $parent = $me->_table_class->new($dbo, $parent) unless blessed $parent;

    $$me->{build_data}{LimitOffset} = [1];
    if ($parent->isa('DBIx::DBO::Query')) {
        croak 'This query is from a different DBO connection' if $parent->{DBO} != $dbo;
        $$me->{Parent} = $parent;
        # We must weaken this to avoid a circular reference
        weaken $$me->{Parent};
        $parent->columns;
        $$me->{Tables} = [ @{$parent->{Tables}} ];
        $$me->{Columns} = $parent->{Columns};
        $$me->{build_data}{from} = $dbo->{dbd_class}->_build_from($parent);
        $me->_copy_build_data;
    } elsif ($parent->isa('DBIx::DBO::Table')) {
        croak 'This table is from a different DBO connection' if $parent->{DBO} != $dbo;
        $$me->{build_data} = {
            show => '*',
            Showing => [],
            from => $parent->_from,
            group => '',
            order => '',
        };
        $$me->{Tables} = [ $parent ];
        $$me->{Columns} = $parent->{Columns};
    } else {
        croak 'Invalid parent for new Row';
    }
    return wantarray ? ($me, $me->tables) : $me;
}

sub _copy_build_data {
    my $me = $_[0];
    # Store needed build_data
    for my $f (qw(Showing From_Bind Quick_Where Where_Data Where_Bind group Group_Bind order Order_Bind)) {
        $$me->{build_data}{$f} = $me->_copy($$me->{Parent}{build_data}{$f}) if exists $$me->{Parent}{build_data}{$f};
    }
}

sub _copy {
    my($me, $val) = @_;
    return bless [$me, $val->[1]], 'DBIx::DBO::Column'
        if _isa($val, 'DBIx::DBO::Column') and $val->[0] == $$me->{Parent};
    ref $val eq 'ARRAY' ? [map $me->_copy($_), @$val] : ref $val eq 'HASH' ? {map $me->_copy($_), %$val} : $val;
}

sub _build_data {
    ${$_[0]}->{build_data};
}

=head3 C<tables>

Return a list of L<Table|DBIx::DBO::Table> objects for this row.

=cut

sub tables {
    @{${$_[0]}->{Tables}};
}

sub _table_idx {
    my($me, $tbl) = @_;
    for my $i (0 .. $#{$$me->{Tables}}) {
        return $i if $tbl == $$me->{Tables}[$i];
    }
    return;
}

sub _table_alias {
    my($me, $tbl) = @_;
    return undef if $tbl == $me;
    my $i = $me->_table_idx($tbl);
    croak 'The table is not in this query' unless defined $i;
    @{$$me->{Tables}} > 1 ? 't'.($i + 1) : ();
}

=head3 C<columns>

Return a list of column names.

=cut

sub columns {
    my($me) = @_;

    return $$me->{Parent}->columns if $$me->{Parent};

    @{$$me->{Columns}} = do {
        if (@{$$me->{build_data}{Showing}}) {
            map {
                _isa($_, 'DBIx::DBO::Table', 'DBIx::DBO::Query') ? ($_->columns) : $me->_build_col_val_name(@$_)
            } @{$$me->{build_data}{Showing}};
        } else {
            map { $_->columns } @{$$me->{Tables}};
        }
    } unless @{$$me->{Columns}};

    @{$$me->{Columns}};
}

*_build_col_val_name = \&DBIx::DBO::Query::_build_col_val_name;

sub _column_idx {
    my($me, $col) = @_;
    my $idx = -1;
    for my $shown (@{$$me->{build_data}{Showing}} ? @{$$me->{build_data}{Showing}} : @{$$me->{Tables}}) {
        if (_isa($shown, 'DBIx::DBO::Table')) {
            if ($col->[0] == $shown and exists $shown->{Column_Idx}{$col->[1]}) {
                return $idx + $shown->{Column_Idx}{$col->[1]};
            }
            $idx += keys %{$shown->{Column_Idx}};
            next;
        }
        $idx++;
        return $idx if not defined $shown->[1] and @{$shown->[0]} == 1 and $col == $shown->[0][0];
    }
    return;
}

=head3 C<column>

  $row->column($column_name);

Returns a column reference from the name or alias.

=cut

sub column {
    my($me, $col) = @_;
    my @show;
    @show = @{$$me->{build_data}{Showing}} or @show = @{$$me->{Tables}};
    for my $fld (@show) {
        return $$me->{Column}{$col} ||= bless [$me, $col], 'DBIx::DBO::Column'
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
    for my $fld (@{$$me->{build_data}{Showing}}) {
        return $$me->{Column}{$col} ||= bless [$me, $col], 'DBIx::DBO::Column'
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
    undef $$me->{build_data}{where};
    my $sql = $$me->{DBO}{dbd_class}->_build_sql_select($me);
    my @bind = $$me->{DBO}{dbd_class}->_bind_params_select($me);
    $old_qw < 0 ? delete $$me->{build_data}{Quick_Where} : ($#{$$me->{build_data}{Quick_Where}} = $old_qw);
    delete $$me->{build_data}{where};
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
        $$me->{Columns} = [ @{$$me->{Columns}} ];
        $$me->{array} = [ @$me ];
        $$me->{hash} = { %$me };
        undef $$me->{Parent}{Row};
        # Save config from Parent
        if ($$me->{Parent}{Config} and %{$$me->{Parent}{Config}}) {
            $$me->{Config} = { %{$$me->{Parent}{Config}}, $$me->{Config} ? %{$$me->{Config}} : () };
        }
    }
    delete $$me->{Parent};
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
    $$me->{build_data}{LimitOffset} = ($me->config('LimitRowUpdate') and $me->tables == 1) ? [1] : undef;
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
    $$me->{build_data}{LimitOffset} = ($me->config('LimitRowDelete') and $me->tables == 1) ? [1] : undef;
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

See L<DBIx::DBO/Available_config_options>.

=cut

sub config {
    my $me = shift;
    my $opt = shift;
    return $$me->{DBO}{dbd_class}->_set_config($$me->{Config} ||= {}, $opt, shift) if @_;
    $$me->{DBO}{dbd_class}->_get_config($opt, $$me->{Config} ||= {}, defined $$me->{Parent} ? ($$me->{Parent}{Config}) : (), $$me->{DBO}{Config}, \%DBIx::DBO::Config);
}

*STORABLE_freeze = sub {
    my($me, $cloning) = @_;
    return unless exists $$me->{Parent};

    # Simulate detached row
    local $$me->{Columns} = [ @{$$me->{Columns}} ];
    # Save config from Parent
    my $parent = delete $$me->{Parent};
    local $$me->{Config} = { %{$parent->{Config}}, $$me->{Config} ? %{$$me->{Config}} : () }
        if $parent->{Config} and %{$parent->{Config}};

    my $frozen = Storable::nfreeze($me);
    $$me->{Parent} = $parent;
    return $frozen;
} if $Storable::VERSION >= 2.38;

*STORABLE_thaw = sub {
    my($me, $cloning, @frozen) = @_;
    $$me = { %${ Storable::thaw(@frozen) } }; # Copy the hash, or Storable will wipe it out!
} if $Storable::VERSION >= 2.38;

sub DESTROY {
    undef %${$_[0]};
}

1;

__END__

=head1 SUBCLASSING

Classes can easily be created for tables in your database.
Assume you want to create a simple C<Row> class for a "Users" table:

  package My::User;
  our @ISA = qw(DBIx::DBO::Row);
  
  sub new {
      my($class, $dbo) = @_;
      
      $class->SUPER::new($dbo, 'Users'); # Create the Row for the "Users" table
  }

=head1 SEE ALSO

L<DBIx::DBO>


=cut

