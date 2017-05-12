package Class::DBI::Sybase;

=head1 NAME

Class::DBI::Sybase - Extensions to Class::DBI for Sybase

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI::Sybase';
  Music::DBI->set_db('Main', "dbi:Sybase:server=$server", $username, $password);

  package Artist;
  use base 'Music::DBI';
  __PACKAGE__->set_up_table('Artist');
  
  # ... see the Class::DBI documentation for details on Class::DBI usage

=head1 DESCRIPTION

This is an extension to Class::DBI that currently implements:

    * Automatic column name discovery.
    * Works with IDENTITY columns to auto-generate primary keys.
    * Works with TEXT columns for create() and update()
    * Allow for CaseSensitive columns (for JavaDeveloperDesignedDBs)
	* Allow for tables with multiple primary key columns
	
Instead of setting Class::DBI as your base class, use this.

=head1 BUGS

DBD::Sybase currently has a bug where a statement handle can be marked as
active, even though it's not. We override sth_to_objects to call finish() on the handle.

=head1 AUTHORS

* Dan Sully E<lt>daniel@cpan.orgE<gt> - Original Author

* Michael Wojcikewicz E<lt>theothermike@gmail.comE<gt> - Current Maintainer

* Paul Sandulescu E<lt>archpollux@gmail.comE<gt> - Patches

* Thai Nguyen E<lt>useevil@gmail.comE<gt> - Patches

=head1 SEE ALSO

L<Class::DBI>, L<DBD::Sybase>

=cut


use strict;
use base 'Class::DBI';

use vars qw($VERSION);
$VERSION = '0.5';

# new Column and ColumnGrouper classes for CaseSensitivity

sub _die { require Carp; Carp::croak(@_); }

# This is necessary to get the last ID back
__PACKAGE__->set_sql( MakeNewObj => <<'');
SET NOCOUNT ON
INSERT INTO __TABLE__ (%s)
VALUES (%s)
SELECT @@IDENTITY


# This is necessary for CaseSensitivity
__PACKAGE__->__grouper( Class::DBI::Sybase::ColumnGrouper->new() );

sub set_up_table
{
    my ( $class, $table ) = @_;
    my $dbh = $class->db_Main();

    $class->table($table);

    # find the primary key and column names.
    my $sth = $dbh->prepare("sp_columns $table");
    $sth->execute();

    my $col = $sth->fetchall_arrayref;
    $sth->finish();

    _die( 'The "' . $class->table() . '" table has no primary key' ) unless $col->[0][3];

    $class->columns( All => map { $_->[3] } @$col );
    $class->columns( Primary => $col->[0][3] );

    # find any text columns that will get quoted upon INSERT
    $class->columns( TEXT => map { $_->[5] eq 'text' ? $_->[3] : () } @$col );

    # now find the IDENTITY column
    $sth = $dbh->prepare("sp_help $table");
    $sth->execute();

    # the first two resultsets contain no info about finding the identity column
    $sth->fetchall_arrayref() for 1 .. 2;
    $col = $sth->fetchall_arrayref();

    my ($identity) = grep( $_->[9] == 1, @$col ); # the 10th column contains a boolean denoting whether it's an IDENTITY
    $class->columns( IDENTITY => $identity->[0] ) if $identity;    # store the IDENTITY column
}

# Fixes a DBD::Sybase problem where the handle is still active.
# allows for CaseSensitive columns
sub sth_to_objects
{
    my ( $class, $sth, $args ) = @_;

    $class->_croak("sth_to_objects needs a statement handle") unless $sth;

    unless ( UNIVERSAL::isa( $sth => "DBI::st" ) )
    {
        my $meth = "sql_$sth";
        $sth = $class->$meth();
    }
    $sth->finish() if $sth->{Active};

    # reimplement the rest of Class::DBI::sth_to_objects, without NAME_lc
    my ( %data, @rows );

    eval {
        $sth->execute(@$args) unless $sth->{Active};
        $sth->bind_columns( \( @data{ @{ $sth->{NAME} } } ) );
        push @rows, {%data} while $sth->fetch;
    };

    return $class->_croak( "$class can't $sth->{Statement}: $@", err => $@ ) if $@;
    return $class->_ids_to_objects( \@rows );
}

sub _column_placeholder
{
    my $self         = shift;
    my $column       = shift;
    my $data         = shift;
    my @text_columns = $self->columns('TEXT');

	# if its a text column, we need to $dbh -> quote() it, rather than using a placeholder, limitation of Sybase TDS libraries
    if ( $data && grep { $_ eq $column } @text_columns )
    {
        return $self->db_Main->quote($data);
    }
    else
    {
        return $self->SUPER::_column_placeholder($column);
    }
}

sub _insert_row
{
    my $self             = shift;
    my $data             = shift;
    my @primary_columns = $self->primary_columns();
    my @identity_columns = $self->columns('IDENTITY');
    my @text_columns     = $self->columns('TEXT');

    eval {
        my @columns;
        my @values;

        # Omit the IDENTITY column to let it be Auto Generated
        for my $column ( keys %$data )
        {
            next if defined $identity_columns[0] && $column eq $identity_columns[0];

            push @columns, $column;

            # Omit the text column since it needs to be quoted
            push @values, $data->{$column} unless grep { $_ eq $column } @text_columns;
        }
        my $sth = $self->sql_MakeNewObj(
            join( ', ', @columns ),
            join( ', ', map $self->_column_placeholder( $_, $data->{$_} ), @columns )
            ,    # this uses the new placeholder methods that quotes
        );
        $self->_bind_param( $sth, \@columns );
        $sth->execute(@values);

        my $id = $sth->fetchrow_arrayref()->[0];

        $data->{ $identity_columns[0] } = $id
            if @identity_columns == 1
            && !defined $data->{ $identity_columns[0] };
        $sth->finish if $sth->{Active};
    };

    if ($@)
    {
        my $class = ref $self;
        return $self->_croak(
            "Can't insert new $class: $@",
            err    => $@,
            method => 'create'
        );
    }

    return 1;
}

sub _update_vals
{
    my $self             = shift;
    my @text_columns     = $self->columns('TEXT');
    my @identity_columns = $self->columns('IDENTITY');

    my @changed = $self->is_changed();
    my @columns;

    foreach my $changed (@changed)
    {

        # omit TEXT and IDENTITY columns from the update clause since they are quoted
        next if grep { $_ eq $changed } @identity_columns;
        next if grep { $_ eq $changed } @text_columns;

        push @columns, $changed;
    }

    return $self->_attrs(@columns);
}

sub _update_line
{
    my $self             = shift;
    my @changed          = $self->is_changed;
    my @identity_columns = $self->columns('IDENTITY');
    my @columns;

    foreach my $changed (@changed)
    {

        # omit IDENTITY columns from the update clause since they are cannot be
        # changed without first setting IDENTITY_INSERT to ON
        push @columns, $changed unless grep { $_ eq $changed } @identity_columns;
    }

    # use our custom _column_placeholder that quotes TEXT columns
    return join( ', ', map "$_ = " . $self->_column_placeholder( $_, $self->$_() ), @columns );
}

sub _make_method
{
    my ( $class, $name, $method ) = @_;

    return if defined &{"$class\::$name"};

    $class->_carp("Column '$name' in $class clashes with built-in method")
        if Class::DBI->can($name)
        and not( $name eq "id" and join( " ", $class->primary_columns ) eq "id" );

    no strict 'refs';
    *{"$class\::$name"} = $method;

    $class->_make_method( $name => $method );
}

sub _column_class {'Class::DBI::Sybase::Column'}    # for CaseSensitivity

sub _set_columns
{
    my ( $class, $group, @columns ) = @_;
    my @cols = map ref $_ ? $_ : $class->_column_class->new($_), @columns;

    # Careful to take copy
    $class->__grouper( Class::DBI::Sybase::ColumnGrouper->clone( $class->__grouper )->add_group( $group => @cols ) );
    $class->_mk_column_accessors(@cols);

    return @columns;
}

1;

package Class::DBI::Sybase::Column;

use strict;
use base 'Class::DBI::Column';
use Carp;

# dont lower case
sub name_lc { shift->name }

1;

package Class::DBI::Sybase::ColumnGrouper;

use strict;
use Carp;
use Storable 'dclone';

use base qw( Class::DBI::ColumnGrouper );

sub add_column 
{
	my ($self, $col) = @_;

    # dont lower case
	croak "Need a Column, got $col" unless $col->isa("Class::DBI::Column");
	$self->{_allcol}->{ $col->name } ||= $col;
}

sub find_column 
{
	my ($self, $name) = @_;

    # dont lower case
	return $name if ref $name;
	return unless $self->{_allcol}->{ $name };
}

# TODO: LIMIT ?

