=head1 NAME

Class::DBI::Audit - Audit changes to columns in CDBI objects.

=head1 SYNOPSIS

    # Base class
    package Music::DBI;
    use base 'Class::DBI';
    use mixin 'Class::DBI::Audit';  
    Music::DBI->connection('dbi:mysql:dbname', 'username', 'password');
    __PACKAGE__->auditColumns({
        remote_user => [ from_hash => 
            { name => 'ENV', key => 'REMOTE_USER' } ], 
        time_stamp  => [ from_sub => 
            { subroutine => sub { scalar localtime; } } ]
    });

    # Derived class
    package Music::Artist;
    use base 'Music::DBI';
    __PACKAGE__->table('artist');
    __PACKAGE__->auditTable('artist_audit');
    __PACKAGE__->columns(All   => qw/artistid first_name last_name/); 
    __PACKAGE__->columns(Audit => qw/first_name last_name/); 
    __PACKAGE__->add_audit_triggers;
    
    # (or everything can go in the base or derived class, if you want)

  /* 
   * Now create an audit table, to track changes to first + last names
   * of artists :
   */ 
   create table artist_audit (
       id           int unsigned NOT NULL auto_increment primary key,

       /* These 5 columns are mandatory */
       parent_id    int unsigned NOT NULL, 
       query_type   enum('update','insert','delete'),  
       column_name  varchar(255),
       value_before blob,
       value_after  blob,

       /* The rest reflect auditColumns (above) */
       time_stamp   datetime,
       remote_user  varchar(255)
    );

    # Then in your main program :

    $ENV{REMOTE_USER} = 'Puff'
    $artist = Music::Artist->insert({ 
            first_name => 'Jennifer', 
            last_name => 'Lopez' });

    $ENV{REMOTE_USER} = 'Ben'
    $artist->first_name('J');
    $artist->last_name('Lo');
    $artist->update;

    for my $column (qw(first_name last_name)) {
        for ($artist->column_history($column)) {
            print $_->{remote_user}.
                  " set $column to ".
                  $_->{value_after}.
                  "\n";
        }
    }
    # Puff set first_name to Jennifer
    # Ben set first_name to J
    # Puff set last_name to Jennifer
    # Ben set last_name to Lo

=head1 DESCRIPTION

This module allows easy tracking of changes to values in tables
managed by CDBI classes.  It helps you answer the question
"who set that value to be 'foobar', I thought I set it to
be 'farbar'?" without resorting to digging through snapshots of
your database tables and comparing them to your webserver's
http logs.

Use this module as a mixin with either your base CDBI class, or
a derived one, and the following methods will be added to
your class (or classes) :

    auditTable()
    auditColumns()
    add_audit_triggers()
    column_history()

The first two specify the external audit table, ('artist_audit' above),
and the columns of this table (time_stamp and remote_user above).

The third method adds the necessary triggers to your CDBI class which
will track the changes, writing them to the auditTable.

The fourth returns a history of changes to a column (i.e. the
data from the audit table) as an array of hashrefs.

Only columns in the 'Audit' group are audited.  Set this
like so :

    __PACKAGE__->columns(Audit => qw/first_name last_name);

You can use either one huge audit table for all of the classes
you wish to audit (in which case you'll want 'table' to be
an element of the auditColumns, see below), or you can have separate 
audit tables for each class.  Or some combination.   Since audit
tables get big quickly, you'll probably want several tables.

=head1 METHODS

=over

=cut

package Class::DBI::Audit;
use Carp;
use mixin::with 'Class::DBI';
use SQL::Abstract;
use strict;
use warnings;
our $VERSION=0.04;

=item auditColumns

Set this class data to be a hash which specifies what goes in your
audit table, e.g.

    __PACKAGE__->auditColumns({
        # hash from column name to where it comes from
        remote_addr => [ from_hash   => { name => 'ENV', 
                                          key => 'REMOTE_ADDR' } ], 
        remote_user => [ from_hash   => { name => 'ENV', 
                                          key => 'REMOTE_USER' } ], 
        request_uri => [ from_hash   => { name => 'ENV', 
                                          key => 'REQUEST_URI' } ],
        command     => [ from_scalar => { name => '0',    } ], 
        table       => [ from_method => { name => 'table' } ],
        time_stamp  => [ from_sub    => { subroutine => sub { 
                        strftime("%Y-%m-%d %H:%M:%S",localtime) 
                        } } ]
    });

...means store these values :

    $ENV{REMOTE_ADDR},
    $ENV{REMOUTE_USER},
    $ENV{REQUEST_URI},
    $0,
    $self->table,
    the value returned by the anonymous subroutine 
        sub { strftime("%Y-%m-%d %H:%M:%S",localtime)  }

in columns named remote_addr, remote_user, remote_uri, command, table, 
and time_stamp respectively.

from_hash and from_scalar columns both look in the 'main::' symbol
table for their variables, override this with a 'package' entry if 
desired.

=cut

__PACKAGE__->mk_classdata( auditColumns => { } );

=item auditTable

By default the audit table is the name of the CDBI table
with '_audit' appended to the end.  Change this by calling
auditTable().  If multiple tables are using the same database
table for auditing, you'll want to give 'table' as one
of the methods in auditColumns (so you can tell what table
a row in the audit table refers to).

=cut

__PACKAGE__->mk_classdata( auditTable => undef );

#
# Private functions (mixin.pm ignores them, so they
# aren't class methods)
#
sub _audit_table {
    my $obj = shift;
    return $obj->auditTable || join '_', $obj->table, 'audit';
}

# taken from the man page for DBI, as an example of prepare_cached
sub _insert_hash {
   my ($dbh,$table, $field_values) = @_;
   Carp::cluck("adding audit data for $table but we are not in a transaction") if $dbh->{AutoCommit};
   # sort to keep field order, and thus sql, stable for prepare_cached
   my @fields = sort keys %$field_values;
   my @values = @{$field_values}{@fields};
   my $sql = sprintf "insert into %s (%s) values (%s)",
       $table, join(",", @fields), join(",", ("?")x@fields);
   my $sth = $dbh->prepare_cached($sql);
   return $sth->execute(@values);
}

sub _do_query {
    my %args = @_;
    my ($dbh,$where,$columns, $table) = @args{qw(dbh where columns table)};
    my ($where_clause,@bind) = SQL::Abstract->new->where($where);
    my $sql = 'select ' .
          ( join ',', @$columns ) .
          " from ". $table .
          $where_clause;
    my $sth = $dbh->prepare($sql) or die $dbh->errstr;
    $sth->execute(@bind);
    return $sth;
}

sub _values_differ {
    my ($x,$y) = @_;
    return 1 if defined($x) && !defined($y);
    return 1 if defined($y) && !defined($x);
    return 0 if !defined($x) && !defined($y);
    return 0 if $x eq $y;
    return 0 if ( 
        $x=~(/^-?(?:\d+(?:\.\d*)?|\.\d+)$/) # from perldoc -q number
        && $y=~(/^-?(?:\d+(?:\.\d*)?|\.\d+)$/) && $x==$y);
    return 0 if $x=~/^\s*$/ && $y=~/^\s*$/; # ignore whitespace changes
    return 1;
}

sub _get_from_hash {
    my $s = shift;
    my $package = $s->{package} || 'main::';
    defined(my $var     = $s->{name}) or die "missing name for from_hash";
    defined(my $key     = $s->{key}) or die "missing key for from_hash";
    my $val;
    {
        no strict 'refs';
        $val = ${ $package . $var }{$key};
    }
    return $val;
}

sub _get_from_scalar {
    my $s = shift;
    my $package = $s->{package} || 'main::';
    defined(my $var     = $s->{name}) or die "missing name for from_scalar";
    my $val;
    {
        no strict 'refs';
        $val = ${ $package . $var };
    }
    return $val;
}

sub _get_from_method_call {
    my ($s,$obj) = @_;
    my $name = $s->{name} or die "missing method name for method_call";
    return $obj->$name;
}

sub _get_from_sub {
    my $s = shift;
    return $s->{subroutine}->();
}

sub _audit_column_values {
    my $obj = shift;
    # Returns a hash from column name to value.
    my %spec = %{ $obj->auditColumns };
    my %h    = ();
    while ( my ( $column_name, $how ) = each %spec ) {
        ref($how) eq 'ARRAY' or die "bad auditColumns spec for $column_name";
        $h{$column_name} =
            $how->[0] eq 'from_hash'   ? _get_from_hash( $how->[1] )
          : $how->[0] eq 'from_scalar' ? _get_from_scalar( $how->[1] )
          : $how->[0] eq 'from_method' ? _get_from_method_call($how->[1], $obj )
          : $how->[0] eq 'from_sub'    ? _get_from_sub($how->[1])
          : die("unknown column specification: $how->[0]");
    }
    defined($h{parent_id} = $obj->id) or Carp::confess("no parent id");
    return %h;
}

=item add_audit_triggers

Adds all the triggers below to a class.

=cut

sub add_audit_triggers {
    my $class = shift;
    $class->add_trigger(after_create => \&Class::DBI::Audit::after_create);
    $class->add_trigger(before_update => \&Class::DBI::Audit::before_update);
    $class->add_trigger(after_update  => \&Class::DBI::Audit::after_update);
    $class->add_trigger(before_delete => \&Class::DBI::Audit::before_delete);
}

=item after_create

A subroutine to be used in the after_create trigger.

=cut

sub after_create {
    my $obj = shift;
    my $new = _do_query(
        dbh     => $obj->db_Main(),
        table   => $obj->table,
        columns => [ $obj->columns('Audit') ],
        where   => { $obj->primary_column => $obj->id }
    )->fetch_hash;
    for my $column ( $obj->columns('Audit') ) {
        my $val = $new->{$column};
        next unless defined($val);
        _insert_hash(
            $obj->db_Main(),
            _audit_table($obj),
            {
                query_type  => 'insert',
                column_name => $column,
                value_after => $val,
                _audit_column_values($obj),
            }
        );
    }
}

=item before_update

A subroutine to be used in the before_update trigger.

=cut

sub before_update {
    my $obj = shift;
    my $old = _do_query(
        dbh     => $obj->db_Main(),
        table   => $obj->table,
        columns => [ $obj->columns('Audit') ],
        where   => { $obj->primary_column => $obj->id }
    )->fetch_hash;
    $obj->_attribute_set( _audit_fields_old => $old );
}

=item after_update

To be used in the after_update trigger.

=cut

sub after_update {
    my $obj = shift;
    my ($old) = $obj->_attrs(qw(_audit_fields_old));
    my $new = _do_query(
        dbh     => $obj->db_Main(),
        table   => $obj->table,
        columns => [ $obj->columns('Audit') ],
        where   => { $obj->primary_column => $obj->id }
    )->fetch_hash;
    for my $column ($obj->columns('Audit')) {
        my $new_val = $new->{$column};
        my $old_val = $old->{$column};
        next unless _values_differ($new_val,$old_val);
        _insert_hash(
            $obj->db_Main(),
            _audit_table($obj),
            {
                query_type   => 'update',
                column_name  => $column,
                value_before => $old_val,
                value_after  => $new_val,
                _audit_column_values($obj),
            }
        );
    }
}

=item before_delete

To be used in the before_delete trigger.

=cut

sub before_delete {
    my $obj = shift;
    my $old = _do_query(
        dbh     => $obj->db_Main(),
        table   => $obj->table,
        columns => [ $obj->columns('Audit') ],
        where   => { $obj->primary_column => $obj->id }
    )->fetch_hash;

    for my $column ($obj->columns('Audit')) {
        _insert_hash(
            $obj->db_Main(),
            _audit_table($obj),
            {
                _audit_column_values($obj),
                column_name  => $column,
                query_type   => 'delete',
                value_before => $old->{$column},
            });
    }
}

=item column_history

Fetch the history of a column from the audit table.
Returns an array of hashrefs whose keys correspond
to the values in the audit table.

=cut

sub column_history {
    my ( $obj, $column ) = @_;
    my @vals = _do_query(
        dbh     => $obj->db_Main(),
        columns => [ '*' ],
        where   => { parent_id => $obj->id, column_name => $column },
        table   => _audit_table($obj)
    )->fetchall_hash;
    return @vals;
}

=back

=head1 NOTES

Data in the audit table is always added, never deleted or
changed.  Some databases may be optimized for such tables
(e.g. the MySQL "archive" engine)

If a field with just whitespace is changed to another field 
with just whitespace, this is ignored.  (But NULLs changing
to not NULLs and vice versa are logged.)

If a field that looks like a number is changed to another one that looks like a
number with the same value, this is ignored.  See _values_differ() in
the source code.

Most likely, value_before and value_after will have some redundancy (since the
next value_before should be the previous value_after); this is intentional,
since it'll cause any non-audited changes to the cdbi table to show up.

All the triggers get data directly from the database using the primary key + table +
primary key value.  This is to avoid side effects (e.g. accidentally populating
some fields of the object), and to ensure that the audit tables contain a record
of the actual data in the table, rather than anything in memory, or anything
that was inflated or filtered via select triggers.

=head1 TODO

Provide a mechanism for overriding _values_differ().

=cut

1;

