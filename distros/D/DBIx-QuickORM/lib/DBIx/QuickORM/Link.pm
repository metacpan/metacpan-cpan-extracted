package DBIx::QuickORM::Link;
use strict;
use warnings;

our $VERSION = '0.000019';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key/;

use DBIx::QuickORM::Util::HashBase qw{
    <local_table
    <local_columns
    <other_table
    <other_columns
    <unique
    <key
    <aliases
    <created
    <compiled
};

sub init {
    my $self = shift;

    croak "'local_table' is a required attribute" unless $self->{+LOCAL_TABLE};
    croak "'other_table' is a required attribute" unless $self->{+OTHER_TABLE};
    croak "'unique' is a required attribute"      unless defined $self->{+UNIQUE};

    croak "'local_columns' is a required attribute" unless $self->{+LOCAL_COLUMNS};
    croak "'other_columns' is a required attribute" unless $self->{+OTHER_COLUMNS};

    croak "'local_columns' must be an arrayref with at least 1 element" unless ref($self->{+LOCAL_COLUMNS}) eq 'ARRAY' && @{$self->{+LOCAL_COLUMNS}} >= 1;
    croak "'other_columns' must be an arrayref with at least 1 element" unless ref($self->{+OTHER_COLUMNS}) eq 'ARRAY' && @{$self->{+OTHER_COLUMNS}} >= 1;

    $self->{+KEY} //= column_key(@{$self->{+LOCAL_COLUMNS}});

    $self->{+ALIASES} //= [];

    return;
}

sub merge {
    my $self = shift;
    my ($other) = @_;

    croak "Links do not have the same 'local' table ($self->{+LOCAL_TABLE} vs $other->{+LOCAL_TABLE})"
        unless $self->{+LOCAL_TABLE} eq $other->{+LOCAL_TABLE};

    croak "Links do not have the same 'other' table ($self->{+OTHER_TABLE} vs $other->{+OTHER_TABLE})"
        unless $self->{+OTHER_TABLE} eq $other->{+OTHER_TABLE};

    croak "Links do not have the same columns ([$self->{+KEY}] vs [$other->{+KEY}])"
        unless $self->{+KEY} eq $other->{+KEY};

    my $new = {%$self, %$self};

    if ($new->{+CREATED}) {
        if ($other->{+CREATED}) {
            $new->{+CREATED} .= ", " . $other->{+CREATED}
                unless $new->{+CREATED} =~ m/\Q$other->{+CREATED}\E/;
        }
    }
    else {
        $new->{+CREATED} = $other->{+CREATED};
    }

    push @{$new->{+ALIASES}} => @{$other->{+ALIASES}};

    return bless($new, blessed($self));
}

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+LOCAL_COLUMNS} //= [@{$self->{+LOCAL_COLUMNS}}];
    $params{+OTHER_COLUMNS} //= [@{$self->{+OTHER_COLUMNS}}];
    $params{+ALIASES}       //= [@{$self->{+ALIASES}}];
    $params{+UNIQUE}        //= $self->{+UNIQUE};
    $params{+KEY}           //= column_key(@{$params{+LOCAL_COLUMNS}});

    my $out = blessed($self)->new(%$self, %params);
    delete $out->{+COMPILED};
    delete $out->{+CREATED};

    return $out;
}

sub parse {
    my $class = shift;
    my ($schema, $connection, $source, $link);

    while (my $r = ref($_[0])) {
        my $item = shift @_;

        if (blessed($item)) {
            if    ($item->isa(__PACKAGE__))                         { return $item }
            elsif ($item->isa('DBIx::QuickORM::Schema'))            { $schema = $item; next }
            elsif ($item->isa('DBIx::QuickORM::Connection'))        { $connection = $item; next }
            elsif ($item->DOES('DBIx::QuickORM::Role::Source')) { $source = $item; next }
        }
        else {
            if ($r eq 'HASH') { $link = $item; next }
            if ($r eq 'SCALAR') { $link = $item; next };
        }

        croak "Not sure what to do with arg '$item'";
    }

    my %params = @_;

    $link        //= delete $params{link};
    $schema      //= delete $params{schema};
    $connection  //= delete $params{connection};
    $source //= delete $params{source};
    $schema      //= $connection->schema if $connection;

    if (ref($link) eq 'SCALAR') {
        croak "Cannot use a table name (scalar ref: \\$$link) to lookup a link without an source" unless $source;
        my ($out, @extra) = $source->links($$link);
        croak "There are multiple links to table '$$link'" if @extra;
        return $out // croak "No link to table '$$link' found";
    }

    $link = { %{$link // {}}, %params };

    my $local_table = delete $link->{+LOCAL_TABLE};
    my $other_table = delete $link->{+OTHER_TABLE} // delete $link->{table};

    my $fields = delete $link->{fields};
    my $local_columns = delete $link->{+LOCAL_COLUMNS} // delete $link->{local_fields} // delete $link->{local};
    my $other_columns = delete $link->{+OTHER_COLUMNS} // delete $link->{other_fields} // delete $link->{other};

    my @keys = keys %$link;
    if (@keys == 1) {
        ($other_table) = @keys;
        my $val = delete $link->{$other_table};

        croak "You must provide an arrayref of columns" unless $val;

        my $cref = ref($val);
        unless ($cref) {
            $val = [$val];
            $cref   = 'ARRAY';
        }

        if ($cref eq 'ARRAY') {
            $local_columns //= $val;
            $other_columns //= $val;
        }
        elsif ($cref eq 'HASH') {
            %$link = (%$link, %$val);
            $local_columns = delete $link->{+LOCAL_COLUMNS} // delete $link->{local_fields} // delete $link->{local};
            $other_columns = delete $link->{+OTHER_COLUMNS} // delete $link->{other_fields} // delete $link->{other};
        }
    }

    $local_table //= $source ? $source->name : croak "No local_table or source provided";
    croak "no other_table provided" unless $other_table;

    my ($local, $other);
    if ($schema) {
        $local = $schema->table($local_table) or croak "local table '$local_table' does not exist in the provided schema";
        $other = $schema->table($other_table) or croak "other table '$other_table' does not exist in the provided schema";
    }

    $local_columns //= $fields // croak "no local_columns provided";
    $other_columns //= $fields // croak "no other_columns provided";

    $local_columns = [$local_columns] unless ref $local_columns;
    $other_columns = [$other_columns] unless ref $other_columns;

    croak "expected an arrayref in 'local_columns' got '$local_columns'" unless ref($local_columns) eq 'ARRAY' && @$local_columns;
    croak "expected an arrayref in 'other_columns' got '$other_columns'" unless ref($other_columns) eq 'ARRAY' && @$other_columns;

    my $unique = $link->{+UNIQUE};
    $unique //= $other->unique->{column_key(@$other_columns)} ? 1 : 0 if $other;
    croak "'unique' not defined, and no schema provided to check" unless defined $unique;

    return $class->new(
        LOCAL_TABLE()   => $local_table,
        OTHER_TABLE()   => $other_table,
        LOCAL_COLUMNS() => $local_columns,
        OTHER_COLUMNS() => $other_columns,
        UNIQUE()        => $unique,
    );
}

1;
