package DB2::Row;

use diagnostics;
use Carp;
use strict;
use warnings;

our $VERSION = '0.23';

=head1 NAME

DB2::Row Framework wrapper around rows using DBD::DB2

=head1 SYNOPSIS

    package myRow;
    use DB2::Row;
    our @ISA = qw( DB2::Row );
    
    ...
    
    use myDB;
    use myTable;
    
    my $db = myDB->new;
    my $tbl = $db->get_table('myTable');
    my $row = $tbl->find($id);
    print $row->col_name;

=head1 FUNCTIONS

=over 4

=item C<new>

Do not call this - you should get your row through your table object. 
To create a new row, see C<DB2::Table::create_row>

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, ref $class || $class;

    my $init = shift;
    if ($init)
    {
        %{$self->{CONFIG}} = %$init;
        if (exists $self->{CONFIG}{_db_object})
        {
            $self->{_db_object} = $self->{CONFIG}{_db_object};
            delete $self->{CONFIG}{_db_object};
        }
        %{$self->{ORIGVALUE}} = %{$self->{CONFIG}};
    }

    foreach my $p ($self->_table->column_list)
    {
        next if exists $self->{CONFIG}{$p};

        my $col = $self->_table->get_column($p);
        $self->{CONFIG}{$p} = $col->{default} if exists $col->{default};
    }

    return $self;
}

sub _modified
{ scalar keys %{shift->{modified}} > 0; }

sub _db
{ shift->{_db_object} }

sub _table
{
    my $self = shift;
    unless (exists $self->{_table})
    {
        $self->{_table} = $self->_db->get_table_for_row_type(ref $self);
    }
    $self->{_table};
}

=item C<save>

Save the current row.  Will happen automatically if it can.  Only
really need to call this if you're interested in any generated identity
column for a new row.

=cut

sub save
{
    my $self = shift;
    if ($self and $self->_modified)
    {
        my $rc = $self->_table->save($self);

        # if we have any "generated" value, see if we can find it.
        my $genColumn = $self->_table->generatedIdentityColumn;
        if ($genColumn and not defined $self->column($genColumn))
        {
            my $stmt = 'values (IDENTITY_VAL_LOCAL())';
            my $sth = $self->_table->_prepare($stmt);
            $sth->execute;
            my $id = $sth->fetchrow_array();
            $self->column($genColumn, $id);
            $sth->finish();
        }

        $self->{ORIGVALUE} = { %{$self->{CONFIG}} };

        delete $self->{modified};
        $self->_table->commit;
        return $rc;
    }
    return '0E0';
}

=item C<discard_changes>

If you do not want your changes up to this point to be kept,
C<discard_changes> will do the obvious

=cut

sub discard_changes
{
    my $self = shift;
    if ($self->_modified)
    {
        $self->{CONFIG} = { %{$self->{ORIGVALUE}} };
        delete $self->{modified};
    }
}

=item C<timestamp_to_time>

Converts a DB2 timestamp column to a perl ("C") time value

=cut

my $timestamp_re = qr/(\d{4})-(\d\d)-(\d\d)[- ](\d\d)[.:](\d\d)[.:](\d\d)[.:](\d{6})/;

sub timestamp_to_time
{
    my $self = shift;
    my $ts = shift;

    if (not defined $ts)
    {
        return undef;
    }

    my ($year, $mon, $mday, $hour, $min, $sec) =
        ($ts =~ $timestamp_re);
    $year -= 1900;
    $mon  -= 1;
    timegm($sec, $min, $hour, $mday, $mon, $year);
}

=item C<time_to_timestamp>

Converts a perl ("C") time value to a DB2 timestamp string.

=cut

sub time_to_timestamp
{
    my $self = shift;
    my $time = shift;

    if (not defined $time)
    {
        return undef;
    }

    # if you pass in a timestamp, you'll get it back.
    if ($time =~ $timestamp_re)
    {
        return $time;
    }

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    sprintf "%04d-%02d-%02d-%02d.%02d.%02d.%06d", 
        ($year + 1900), $mon + 1, $mday, $hour, $min, $sec, 0;
}

=item C<time_to_date>

Convert time to date.  Converts a C/perl time to DB2's DATE format.

=cut

sub time_to_date
{
    my $self = shift;
    my $time = shift;

    if (not defined $time)
    {
        return undef;
    }

    if ($time =~ /^\d+$/)
    {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
        return sprintf "%04d-%02d-%02d", ($year + 1900), $mon + 1, $mday;
    }
    elsif ($time =~ m.^(\d{2})/(\d{2})/(\d{4})$.)
    {
        # assume mm/dd/yyyy?
        my ($m, $d, $y) = ($1, $2, $3);
        if ($m > 12)
        {
            # bad assumption?
            my $t = $m;
            $m = $d;
            $d = $t;
        }
        return sprintf("%04d-%02d-%02d", $y, $m, $d);
    }
    elsif ($time =~ /^(\d{2}).(\d{2}).(\d{4})$/)
    {
        # assume dd.mm.yyyy
        my ($d, $m, $y) = ($1, $2, $3);
        if ($m > 12)
        {
            # bad assumption?
            my $t = $m;
            $m = $d;
            $d = $t;
        }
        return sprintf("%04d-%02d-%02d", $y, $m, $d);
    }
}

=item C<validate_column>

Override this if you need to validate changes to a column.  Normally
you can leave this to the database itself, but you may want to do this
earlier than that.  You can also use this to massage the value before
it is kept.

The parameters are:

  self
  column name
  new value

To keep the value as given, simply return it.  To modify (massage) the
value, return the modified value.  To prevent the update, die.

Remember to call your SUPER before validating yourself to allow for
future enhancements in C<DB2::Row>.  The base function may perform
massaging such as converting time to timestamp, etc., in the future, so
you can get that for free then.  Currently this behaviour is done in
the C<column> method, but it may move into here in the future.

Beware not to try to update the current column directly or indirectly
through this method as you could easily end up with infinite recursion.

=cut

sub validate_column
{
    my $self = shift;
    my $column = shift;
    my $value = shift;

    $value;
}

=item C<column>

This get/set method allows you to retrieve or update any given column
for this row.  With a single parameter, it will return the current
value of that column.  The second parameter will be the new value to
use.  This value will be validated before being used.

=cut

sub column
{
    my $self = shift;
    my $name = uc shift;
    my $type = ref($self);

    if (scalar @_)
    {
        # modifying?
        my $col_type = uc $self->_table->get_column($name, 'type');
        if (scalar @_)
        {
            my $val = shift;

            # eval because validate_column may die.
            eval
            {
                if ($col_type eq 'TIMESTAMP')
                {
                    $val = $self->time_to_timestamp($val);
                }
                elsif ($col_type eq 'DATE')
                {
                    $val = $self->time_to_date($val);
                }
                elsif ($col_type eq 'NULLBOOL')
                {
                    $val = $val ? 'Y' : defined $val ? 'N' : undef;
                }
                elsif ($col_type eq 'BOOL')
                {
                    $val = $val ? 'Y' : 'N';
                }
                $val = $self->validate_column($name, $val);
                $self->{CONFIG}{$name} = $val;

                # if it's not what we started with, keep track of it.
                if (not exists $self->{ORIGVALUE}{$name} or
                    (not defined $val and defined $self->{ORIGVALUE}{$name}) or
                    $val ne $self->{ORIGVALUE}{$name})
                {
                    $self->{modified}{$name} = 1;
                }
                # if it is where we started, it may be BACK to the original
                # setting - clear the modification tag.
                else
                {
                    delete $self->{modified}{$name};
                    delete $self->{modified} unless $self->_modified;
                }
            }
        }
        my $rc = $self->{CONFIG}{$name};
        #if (not defined $self->{CONFIG}{$name})
        #{
        #    $rc = undef;
        #}
        #els
        return $rc;
    }

    (my $name_mod = $name) =~ s/^IS_?//;
    if (defined $self->_table->get_column($name_mod))
    {
        my $type = uc $self->_table->get_column($name_mod, 'type');
        my $rc = $self->{CONFIG}{$name_mod};

        if ($type eq 'BOOL')
        {
            $rc = $rc eq 'Y';
        }
        elsif ($type eq 'NULLBOOL')
        {
            $rc =
                not defined $rc ? undef :
                uc $rc eq 'Y'   ? 1 : 0;
        }

        return $rc;
    }

    croak "Can't do '$name' in $type";
    undef;

}

=item C<as_hash>

This is intended to help template users by returning the current row
as a hash/hashref.  For example, if you have a set of rows, @rows,
you can give them to HTML::Template as:

    loop => [ map { $_->as_hash(1) } @rows ],

The optional parameter will force a scalar return (hashref) despite an
array context, such as the map context above.

=cut

sub as_hash
{
    my $self = shift;
    my $force_scalar = shift;

    my %ret = map {
        $_ => $self->column($_);
    } $self->_table->column_list();
    (not $force_scalar && wantarray) ? %ret : \%ret;
}

=item C<find>

Shortcut to calling C<DB2::Table::find_id>.

=cut

sub find
{
    my $self = shift;

    unless ((ref $self and $self->isa(__PACKAGE__)) or
            $self eq __PACKAGE__ or ($self and $self->isa(__PACKAGE__)))
    {
        unshift @_,$self;
    }
    $self->_table->find_id(@_);
}

=item C<find_where>

Shortcut to calling C<DB2::Table::find_where>

=cut

sub find_where
{
    my $self = shift;

    unless ((ref $self and $self->isa(__PACKAGE__)) or
            $self eq __PACKAGE__ or ($self and $self->isa(__PACKAGE__)))
    {
        unshift @_,$self;
    }

    $self->_table->find_where(@_);
}

=item C<table_name>

Shortcut to calling C<DB2::Table::full_table_name>

=cut

sub table_name
{
    my $self = shift;
    $self->_table->full_table_name;
}

=item C<count>

Shortcut to calling C<DB2::Table::count>

=cut

sub count
{
    my $self = shift;
    $self->_table->count(@_);
}

=item C<count_where>

Shortcut to calling C<DB2::Table::count_where>

=cut

sub count_where
{
    my $self = shift;
    $self->_table->count_where(@_);
}

=item C<delete>

Shortcut to calling C<DB2::Table::delete> for this ID

=cut

sub delete
{
    my $self = shift;
    $self->_table->delete($self);
}

sub DESTROY
{
    my $self = shift;
    $self->save if $self;
}

=item C<SELECT>

Shortcut to calling C<DB2::Table::SELECT>

=cut

sub SELECT
{
    my $self = shift;

    $self->_table->SELECT(@_);
}

=item C<dbi_err>

=item C<dbi_errstr>

=item C<dbi_state>

The relevant variable from DBI for the last problem occurring on this
table.

=cut

sub dbi_err    { shift->_table->dbi_err }
sub dbi_errstr { shift->_table->dbi_errstr }
sub dbi_state  { shift->_table->dbi_state }

=item Dump

Dumps the current values of this row without any internal variables
that Data::Dumper would follow.

=cut

sub Dump
{
    my $self = shift;
    my @cols = $self->_table()->column_list();

    ref ($self) . '={' . join(', ', map {
                my $val = $self->column($_);
                $val = defined $val ? "'$val'" : "<NULL>";
                "$_ => " . $val;
            } @cols) . '}';
}

=back

=head2 C<AUTOLOAD>ed functions

Any column defined by the corresponding DB2::Table object is also a
get/set accessor method for DB2::Row.  For example, if you have a
column named "LASTNAME" in your table, C<$row_obj-E<gt>lastname()> will
retrieve that column from the $row_obj object, while
C<$row_obj-E<gt>lastname('Smith')> will set that objects' lastname to
'Smith'.

=cut

sub AUTOLOAD
{
    my $self = shift;
    our $AUTOLOAD;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    $self->column($name, @_);
}

1;
