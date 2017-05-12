package DBIx::Class::FrozenColumns;
use base qw/DBIx::Class/;

use strict;
use warnings;

our $VERSION = 1.0;

__PACKAGE__->mk_group_accessors(inherited => qw/_frozen_columns _dirty_frozen_columns/);
__PACKAGE__->_frozen_columns({});

=head1 NAME

DBIx::Class::FrozenColumns - Store virtual columns inside another column.

=head1 SYNOPSIS

    package Artist;
    __PACKAGE__->load_components(qw/FrozenColumns Core/);
    __PACKAGE__->add_columns(qw/name description frozen/);
    __PACKAGE__->add_frozen_columns(
        frozen => qw/biography url img50x50 img100x100/
    );

    $artist->url('http://cpan.org');
    $artist->get_column('url');
    $artist->get_dirty_columns; # 'url' and 'frozen' are dirty
    $artist->update; #updates column 'frozen' (using Storable::freeze)

    $artistRS->create({
        name     => 'theodor bastard',
        img50x50 => '50x50.gif',
    }); #that's ok. 'img50x50' will be stored in 'frozen'

    my @artists = $artistRS->search({
        name => '.....',
        url  => 'http://cpan.org',
    }); # Error! no such column 'url'

    package Artist;
    __PACKAGE__->add_frozen_columns(
        biography => qw/childhood adolescence youth present/,
    );

    $artist->childhood('bla-bla-bla');
    $artist->update; #Updates column 'frozen'.

=head1 DESCRIPTION

This module allows you to store multiple columns in one. This is useful when
you want to store dynamic number of columns in database or you just don't know
what columns will be stored there. Or when you can't (or don't want) to alter
your tables in database.

Module allows you to transparently use this columns as if they were normal
columns in your table. With one obvious restriction: you cannot search rows in a
table and therefore you cannot add relationships using these columns (search is
needed to build reverse relationship).

Module handles its own dirty column management and will not update the parent
field unless any columns is changed.

Note: The component needs to be loaded before Core and plugin 'Ordered'.
If you get an error like 'no such column: <frozencolumn>' while updating a row
then try to move this module more closer to the start of the load_components
list.

Also note that frozen column IS NOT a real column of your result class.
This impose some restrictions on use of this columns such as searching, adding
relationships, has_column, get_columns, etc.
See L</EXTENDED METHODS> for the list of method that will work with frozen
columns (as will methods that use it).

Module unpacks frozen columns only once when you first accessing it and packs
when you call update.

You can also create frozen columns in another frozen column any level deep.
The only restriction is that they all use the same storing mechanism.

=head1 METHODS

=head2 add_frozen_columns

    __PACKAGE__->add_frozen_columns ($data_column, @columns)
    __PACKAGE__->add_frozen_columns ($hashref)

Adds frozen @columns to your result source class. These columns will be stored in
$data_column using Storable freeze/thaw algorithm.
If $hashref is specified instead, then below params is expected in it:
    data_column - same as $data_column
    columns     - same as @columns
    type        - class with custom mechanism of storing/restoring frozen cols
See below for more information about L</Custom frozen class>.

=head2 add_dumped_columns ($data_column, @columns)

Same as L</add_frozen_columns> but uses Data::Dumper mechanism.

=head2 add_json_columns ($data_column, @columns)

Same as L</add_frozen_columns> but uses JSON::XS mechanism.

=cut

sub add_frozen_columns {
    my $this = shift;
    my ($type, $data_column, @frozen_columns);

    if(ref $_[0]) {
        my $params = shift;
        $type           = $params->{type};
        $data_column    = $params->{data_column};
        @frozen_columns = @{$params->{columns}||[]};
    }
    else {
        $type = 'DBIx::Class::FrozenColumns::Frozen';
        ($data_column, @frozen_columns) = @_;
    }

    $this->throw_exception('Cannot store frozen columns inside another frozen column of different type')
     if exists $this->_frozen_columns->{$data_column}
        and $this->_frozen_columns->{$data_column}{type} ne $type;

    $this->add_column($data_column)
     unless $this->has_column($data_column) or $this->_frozen_columns->{$data_column};

    my %frozen_columns = %{$this->_frozen_columns};
    foreach my $f_column (@frozen_columns) {
        $this->throw_exception('Cannot override existing column with frozen one')
         if $this->has_column($f_column) or $this->_frozen_columns->{$f_column};

        $frozen_columns{$f_column} = {
            column => $data_column,
            type   => $type,
        };

        no strict 'refs';
        *{"${this}::$f_column"} = sub {
            my $self = shift;
            return $self->get_column($f_column) unless @_;
            $self->set_column($f_column, shift);
        };
    }

    $this->_frozen_columns(\%frozen_columns);
}

sub add_dumped_columns {
    shift->add_frozen_columns({
        type        => 'DBIx::Class::FrozenColumns::Dumped',
        data_column => shift,
        columns     => [@_],
    });
}

sub add_json_columns {
    shift->add_frozen_columns({
        type        => 'DBIx::Class::FrozenColumns::JSON',
        data_column => shift,
        columns     => [@_],
    });
}

=head2 frozen_columns

Returns hash of frozen columns where keys are the names of fcolumns and values 
are hashes with the following properties:

'type' - type of fcolumn (frozen or dumped or some custom).
'column' - parent column where fcolumn is stored.

=cut

sub frozen_columns {$_[0]->_frozen_columns}

=head2 frozen_columns_list

Returns list of names of all frozen columns registered with the result source.

=cut

sub frozen_columns_list {keys %{$_[0]->_frozen_columns}}

=head1 EXTENDED METHODS

=head2 new

Accepts initial values for frozen columns.

    $artistRS->new({img50x50 => '50x50.gif'});

=cut

sub new {
    my $self = shift;
    my ($attrs) = @_;
    my %fattrs;

    foreach my $attr (keys %$attrs) {
        next unless exists $self->_frozen_columns->{$attr};
        $fattrs{$attr} = delete $attrs->{$attr};
    }

    my $ret = $self->next::method(@_);
    while ( my($k,$v) = each %fattrs ) {
        $ret->store_column($k, $v);
    }
    return $ret;
}


=head2 get_column

=cut

sub get_column {
    my ($self, $column) = @_;

    if (my $frozen_info = $self->_frozen_columns->{$column}) {
        $self->_ensure_column_unpacked( $frozen_info->{column}, $frozen_info->{type} );
        return $self->get_column( $frozen_info->{column} )->{$column};
    }

    return $self->next::method($column);
}

=head2 get_columns

Returns DBIC's get_columns with frozen columns hash.
IMPORTANT: until $row is not in storage this method will return basic get_columns
result without frozen columns. This is needed for correct work of insert method.

=cut

sub get_columns {
    my $self = shift;
    return $self->next::method(@_) unless $self->in_storage;
    my %data = $self->next::method(@_);
    foreach my $f_column ( keys %{$self->_frozen_columns} ) {
        $data{$f_column} = $self->get_column($f_column);
    }
    return %data;
}

=head2 store_column

=cut

sub store_column {
    my ($self, $column, $value) = @_;

    if (my $frozen_info = $self->_frozen_columns->{$column}) {
        $self->_ensure_column_unpacked( $frozen_info->{column}, $frozen_info->{type} );
        return $self->get_column( $frozen_info->{column} )->{$column} = $value;
    }

    return $self->next::method($column, $value);
}

=head2 set_column

=cut

sub set_column {
    my ($self, $column, $value) = @_;

    if (my $frozen_info = $self->_frozen_columns->{$column}) {
        my $data_column = $frozen_info->{column};
        my $old = $self->get_column($column);
        my $ret = $self->store_column($column, $value);

        if(defined $old ^ defined $ret or (defined $old && $old ne $ret)) {
            $self->set_column( $data_column, $self->get_column($data_column) );
            my $frozen_dirty = $self->_dirty_frozen_columns || {};
            $frozen_dirty->{$column} = 1;
            $self->_dirty_frozen_columns($frozen_dirty);
        }

        return $ret;

    }

    return $self->next::method($column, $value);
}

=head2 get_dirty_columns

Returns real and frozen dirty columns.
Note that changing frozen column will result in marking at least 2 columns as
dirty.

=cut

sub get_dirty_columns {
    my $self = shift;
    return $self->next::method(@_) unless $self->_dirty_frozen_columns;
    my %data = $self->next::method(@_);
    foreach my $f_column ( keys %{$self->_dirty_frozen_columns} ) {
        $data{$f_column} = $self->get_column($f_column);
    }
    return %data;
}

sub _ensure_column_unpacked {
    my ($self, $column, $type) = @_;
    unless ( ref (my $packed = $self->get_column($column)) ) {
        $self->store_column($column, $type->recover(\$packed));
    }
}

=head2 has_column_loaded

Returns true if data_column of frozen column has loaded.

=cut

sub has_column_loaded {
    my ($self, $column) = @_;

    if (my $frozen_info = $self->_frozen_columns->{$column}) {
        return $self->has_column_loaded( $frozen_info->{column} );
    }

    $self->next::method($column);
}

=head2 is_column_changed

=cut

sub is_column_changed {
    my ($self, $column) = @_;

    if ($self->_frozen_columns->{$column}) {
        my $frozen_dirty = $self->_dirty_frozen_columns;
        return $frozen_dirty && exists $frozen_dirty->{$column};
    }

    $self->next::method($column);
}

=head2 is_changed

=cut

sub is_changed {
    my $self = shift;

    if(wantarray) {
        my @columns = $self->next::method(@_);
        my $frozen_dirty = $self->_dirty_frozen_columns;
        push @columns, keys %$frozen_dirty if $frozen_dirty;
        return @columns;
    }

    return 1 if $self->next::method(@_) or keys %{$self->_dirty_frozen_columns||{}};
}

=head2 update

=cut

sub update {
    my $self = shift;
    $self->_dirty_frozen_columns(undef);
    $self->next::method(@_);
}


=head2 insert

=cut

sub insert {
    my $self = shift;
    $self->_dirty_frozen_columns(undef);
    $self->next::method(@_);
}

=head1 Custom frozen class

Such a class must be derived from 'DBIx::Class::FrozenColumns::Base' and is
responsible for fetching and storing frozen columns to/from a real database column.
The corresponding methods are 'recover' and 'stringify'.

The best explanation is an expamle:

    package DBIx::Class::FrozenColumns::Frozen;
    use base qw/DBIx::Class::FrozenColumns::Base/;

    use strict;
    use Storable qw/freeze thaw/;

    sub stringify {
         freeze(shift);
    }

    sub recover {
        my ($this, $dataref) = @_;
        my $data = defined $$dataref ? eval {thaw($$dataref)} || {} : {};
        bless ($data, ref $this || $this);
    }

Information actually stored in database can be used by any other programs as a simple
hash (possibly containing another hashes like itself).

=cut

package DBIx::Class::FrozenColumns::Base;
use strict;
use overload '.'      => sub {$_[0]->stringify},
             '""'     => sub {$_[0]->stringify},
             'ne'     => sub{1},
             'eq'     => sub{undef},
             fallback => 1;

package DBIx::Class::FrozenColumns::Frozen;
use base qw/DBIx::Class::FrozenColumns::Base/;

use strict;
use Storable qw/freeze thaw/;

sub stringify {
     freeze(shift);
}

sub recover {
    my ($this, $dataref) = @_;
    my $data = defined $$dataref ? eval {thaw($$dataref)} || {} : {};
    bless ($data, ref $this || $this);
}


package DBIx::Class::FrozenColumns::Dumped;
use base qw/DBIx::Class::FrozenColumns::Base/;

use strict;
use Data::Dumper qw/Dumper/;

sub stringify {
    local $Data::Dumper::Indent = 0;
    Dumper(shift);
}

sub recover {
    my ($this, $dataref) = @_;
    our $VAR1;
    my $data = defined $$dataref ? eval "$$dataref" || {} : {};
    bless ($data, ref $this || $this);
}


package DBIx::Class::FrozenColumns::JSON;
use base qw/DBIx::Class::FrozenColumns::Base/;

use strict;
use JSON::XS;
my $json = JSON::XS->new; #utf8 will be handled automatically (<dbtype>_enable_utf8 required)

sub stringify {ref $_[0] ? $json->encode({%{$_[0]}}) : undef}
sub recover {
    my ($this, $dataref) = @_;
    my $data = defined $$dataref ? eval {$json->decode($$dataref)} || {} : {};
    bless $data, ref $this || $this;
}


=head1 CAVEATS

=over

=item *

You cannot search rows in a table using frozen columns

=item *

You cannot add relationships using frozen columns

=back

=head1 SEE ALSO

L<Storable>, L<Data::Dumper>.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
