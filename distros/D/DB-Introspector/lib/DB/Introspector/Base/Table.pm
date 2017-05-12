package DB::Introspector::Base::Table;

use base qw( DB::Introspector::Base::Object );

use strict;

sub new {
    my $class = shift;
    my $name = shift;
    my $owner = shift;

    return bless({_name => $name, _owner=>$owner}, ref($class) || $class);
}


sub name {
    my $self = shift;
    return $self->{_name};
}

sub owner {
    my $self = shift;
    return $self->{_owner};
}

sub indexes {
    my $self = shift;
    die("indexes is not defined for ".(ref($self))); 
}

sub columns {
    my $self = shift;
    die("columns is not defined for ".(ref($self))); 
}

sub primary_key {
    my $self = shift;
    die("primary_key is not defined for ".(ref($self))); 
}

sub primary_key_names {
    my $self = shift;
    return map { $_->name; } $self->primary_key;
}

sub primary_key_column {
    my $self = shift;
    my $column_name = shift;

    unless( $self->{primary_key_column_name_map} ) {
        my %columns;
        foreach my $column ($self->primary_key) {
            $columns{$column->name} = $column;
        }
        $self->{primary_key_column_name_map} = \%columns;
    }

    return $self->{primary_key_column_name_map}{$column_name};

}

sub is_primary_key_column {
    my $self = shift;
    my $column = shift;

    my $local_column = $self->primary_key_column($column->name) 
        || return 0;

    return ($local_column == $column);
}

sub is_primary_key_column_name {
    my $self = shift;
    my $column_name = shift;

    return defined($self->primary_key_column($column_name)); 
}

sub non_primary_key_columns {
    my $self = shift;

    return grep { !$self->is_primary_key_column($_) } $self->columns;
} 

sub non_primary_key_column_names {
    my $self = shift;

    return map { $_->name; } $self->non_primary_key_columns;
} 

sub column_names {
    my $self = shift;
    return map { $_->name; } $self->columns;
}

sub column {
    my $self = shift;
    my $name = shift;

    unless( defined $self->{_columns} ) {
        $self->{_columns} = {};
        foreach my $column ($self->columns) {
            $self->{_columns}{$column->name} = $column;
        }
    }

    return $self->{_columns}{$name};
}

sub foreign_keys {
    my $self = shift;
    die("foreign_keys is not defined for ".(ref($self))); 
    # returns @ of foreign_keys
}

sub dependencies {
    my $self = shift;
    die("dependencies is not defined for ".(ref($self))); 
}

sub foreign_key_names {
    my $self = shift;
    return map { $_->name; } $self->foreign_keys;
}

sub foreign_key {
    my $self = shift;
    my $name = shift;

    unless( defined $self->{_foreign_keys} ) {
        $self->{_foreign_keys} = {};
        foreach my $foreign_key ($self->foreign_keys) {
            $self->{_foreign_keys}{$foreign_key->name} = $foreign_key;
        }
    }

    return $self->{_foreign_keys}{$name};
}

1;
__END__

=head1 NAME

DB::Introspector::Base::Table

=head1 SYNOPSIS

 use DB::Introspector;
 
 my $table = $introspector->find_table('users');

 print "table name is: ".$table->name."\n";
 
 foreach my $column ($table->columns) {

     print "column ".$column->name."\n";

 }
 
 foreach my $foreign_key ($table->foreign_keys) {

     print "foreign key ("
         .join(",",$foreign_key->local_column_names).") -> "
         .$foreign_key->foreign_table->name." ("
         .join(",",$foreign_key->foreign_column_names).")\n";

 }

=head1 DESCRIPTION

DB::Introspector::Base::Table is an abstract class that provides a higher level
representation for a database table. This representation includes methods for
discovering foreign keys, columns, and more cool stuff.

=head1 ABSTRACT METHODS

=over 4


=item $table->primary_key

=over 4

Returns: an array (@) of DB::Introspector::Base::Column instances foreach
column in the primary key of this $table instance

=back


=item $table->columns

=over 4

Returns: an array (@) of DB::Introspector::Base::Column instances foreach
column in the $table instance, whose assumed order is equivalent to that which
is in the database from which they were extracted.

=back


=item $table->foreign_keys

=over 4

Returns: an array (@) of DB::Introspector::Base::ForeignKey instances. 

=back


=item $table->dependencies

=over 4

Returns: an array (@) of DB::Introspector::Base::ForeignKey instances
from the child tables to this table instance.

=back


=back


=head1 METHODS

=over 4



=item DB::Introspector::Base::Table->new($table_name, $owner_name)

=item $introspector->find_table($table_name)

=over 4

Params:

=over 4

$table_name - the name of the table being instantiated

$owner_name - the name of the owner of the table.

=back

Returns: a new DB::Introspector::Base::Table instance.

=back



=item $table->name

=over 4

Returns: the name of this table

=back


=item $table->owner

=over 4

Returns: the name of the owner of this table

=back


=item $table->column_names

=over 4

Returns: an array (@) of the names of the columns in assumed database order

=back


=item $table->primary_key_column($column_name)

=over 4

Returns: the DB::Introspector::Base::Column instance for the column name
$column_name or undef if there exists no primary key column by that name.

=back



=item $table->column($column_name)

=over 4

Returns: the DB::Introspector::Base::Column instance for the column name
$column_name

=back


=item $table->foreign_key_names

=over 4

Returns: an array (@) of the names of the foreign_keys in assumed database
order

=back


=item $table->foreign_key($foreign_key_name)

=over 4

Returns: the DB::Introspector::Base::ForeignKey instance for the foreign_key
name $foreign_key_name

=back


=item $table->is_primary_key_column($column)

=over 4

Param:

=over 4

$column - DB::Introspector::Base::Column instance

=back

Returns: 1 if $column is a primary key column and 0 otherwise.

=back


=item $table->is_primary_key_column_name($column_name)

=over 4

Returns: 1 if $column_name is a primary key column name and 0 otherwise.

=back


=item $table->non_primary_key_columns

=over 4

Returns: an array (@) of non primary key columns

=back



=head1 SEE ALSO

=over 4

L<DB::Introspector>

L<DB::Introspector::Base::Column>

L<DB::Introspector::Base::ForeignKey>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::Table module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
