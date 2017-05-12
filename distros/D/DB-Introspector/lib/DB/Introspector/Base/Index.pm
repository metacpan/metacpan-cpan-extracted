package DB::Introspector::Base::Index;

use base qw( DB::Introspector::Base::Object );

use strict;

sub column_names {
    my $self = shift;
    die("column_names not defined for ".ref($self));
}

sub new {
    my $class = shift;
    my $table = shift;
    my $unique = shift;

    my $self = bless({  _table   => $table, 
                        _unique => $unique 
                     }, ref($class) || $class);

    return $self;
}

sub unique {
    my $self = shift;
    return $self->{_unique};
}


sub table {
    my $self = shift;
    return $self->{_table};
}


1;
__END__

=head1 NAME

DB::Introspector::Base::Index

=head1 SYNOPSIS


 use DB::Introspector;

 my $introspector = DB::Introspector->get_instance($dbh);

 my $table = $introspector->find_table('users');

 foreach my $index ($table->indexes) {
    print "INDEX (". join(",", $index->column_names). ")\n";
 }

     
=head1 DESCRIPTION

DB::Introspector::Base::Index is a class that represents a table's index.  

=head1 ABSTRACT METHODS

=over 4


=item $index->column_names

=over 4

Returns: an array (@) of column names in the order in which the index was
declared.

=back


=back

=head1 METHODS

=over 4

=item DB::Introspector::Base::Index->new($table, $is_unique);

=over 4

Params:

=over 4

$table - a DB::Introspector::Base::Table instance

$is_unique - a boolean describing whether or not this index is a unique index (meaning it requires all of its elemets to be unique.

=back

Returns: an instance of a DB::Introspector::Base::Index

=back


=item $index->table

=over 4

Returns: The table that this index is apart of.

=back


=item $index->unique

=over 4

Returns: whether or not this is a unique index

=back

=back

=head1 SEE ALSO

=over 4

L<DB::Introspector>

L<DB::Introspector::Base::Table>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::Index module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
