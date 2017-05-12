package DB::Introspector::Base::FunctionalIndex;

use base qw( DB::Introspector::Base::Index );

use strict;


1;
__END__

=head1 NAME

DB::Introspector::Base::FunctionalIndex

=head1 EXTENDS

DB::Introspector::Base::Index

=head1 SYNOPSIS


 use DB::Introspector;

 my $introspector = DB::Introspector->get_instance($dbh);

 my $table = $introspector->find_table('users');

 foreach my $index ($table->indexes) {
    print "INDEX (". join(",", $index->column_names). ")\n";
 }

     
=head1 DESCRIPTION

Represents a functional index of a table. This implementation is a very barebones quick fix that still fits into the DB::Introspector::Base framework.

In the future, I would like to create a collection of datastructures that can generically describe a functional index expression, which could then be returned by the FunctionIndex package. This would require that driver implementations be able to parse expressions.

=head1 ABSTRACT METHODS

=over 4

=item $index->column_names

=over 4

Returns: an array (@) of column names in the order in which the index was
declared. If the column name is an expression then it is the expression as it is declared in the database.

=back

=item $index->is_expression($column_name)

=over 4

Returns: 1 if this column is an expression and 0 otherwise.

=back

=back

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Index>

=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::FunctionalIndex module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
