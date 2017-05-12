package DB::Introspector::Base::ForeignKey;

use base qw( DB::Introspector::Base::Object );

use strict;

use constant DELETE_RULE_NO_ACTION => 'NO ACTION';
use constant DELETE_RULE_CASCADE => 'CASCADE';
use constant DELETE_RULE_SET_NULL => 'SET NULL';
use constant DELETE_RULE_SET_DEFAULT => 'SET DEFAULT';

sub name { return ""; }

sub local_for_foreign_column {
    my $self = shift;
    my $foreign_column_name = shift;

    my $index = $self->foreign_column_index($foreign_column_name);
    return undef unless defined($index);

    my @local_columns = $self->local_column_names;
    return $local_columns[$index];
}

sub foreign_for_local_column {
    my $self = shift;
    my $local_column_name = shift;

    my $index = $self->local_column_index($local_column_name);
    return undef unless defined($index);

    my @foreign_columns = $self->foreign_column_names;
    return $foreign_columns[$index];
}

sub local_column_index {
    my $self = shift; 
    my $local_column_name = shift;

    my @local_columns = $self->local_column_names;

    foreach my $index (0..$#local_columns) {
        return $index if($local_columns[$index] eq $local_column_name);
    }

    return undef;
}

sub foreign_column_index {
    my $self = shift; 
    my $foreign_column_name = shift;

    my @foreign_columns = $self->foreign_column_names;

    foreach my $index (0..$#foreign_columns) {
        return $index if($foreign_columns[$index] eq $foreign_column_name);
    }

    return undef;
}

sub foreign_table {
    my $self = shift;
    die("foreign_table not defined for ".ref($self));
}

sub foreign_column_names {
    my $self = shift;
    die("foreign_column_names not defined for ".ref($self));
}

sub local_column_names {
    my $self = shift;
    die("local_column_names not defined for ".ref($self));
}

sub new {
    my $class = shift;
    my $local_table = shift;
    my $dependency = shift;

    my $self = bless(
        { _local_table   => $local_table, _is_dependency => $dependency },
        ref($class) || $class);


    return $self;
}

sub is_dependency {
    my $self = shift;
    return $self->{_is_dependency};
}

sub enabled { 1; }

sub delete_rule { return DELETE_RULE_NO_ACTION; };



sub local_table {
    my $self = shift;
    return $self->{_local_table};
}


1;
__END__

=head1 NAME

DB::Introspector::Base::ForeignKey

=head1 SYNOPSIS


 use DB::Introspector;

 my $introspector = DB::Introspector->get_instance($dbh);

 my $table = $introspector->find_table('users');

 foreach my $foreign_key ($table->foreign_keys) {

    print "Foreign Key name:\t".$foreign_key->name."\n";

    print "Foreign Key local table:\t".$foreign_key->local_table->name."\n";

    print "Foreign Key foreign table:\t".$foreign_key->foreign_table->name."\n";

 }

     
=head1 DESCRIPTION

DB::Introspector::Base::ForeignKey is a class that represents a table's foreign
key. The 'local_table' is the table that depends on the foreign table. This
(local_table) can be considered the child table because data in the local table depends on the existence of data in the foreign table.

=head1 ABSTRACT METHODS

=over 4



=item $foreign_key->foreign_table

=over 4

Returns: The table that the 'local_table' depends on. 

=back


=item $foreign_key->foreign_column_names

=over 4

Returns: an array (@) of foreign column names in order such that they can be
mapped to the local column names. 

=back


=item $foreign_key->local_column_names

=over 4

Returns: an array (@) of local column names in order such that they can be
mapped to the foreign column names. 

=back


=back

=head1 METHODS

=over 4

=item DB::Introspector::Base::ForeignKey->new($local_table);

=over 4

Params:

=over 4

$local_table - a DB::Introspector::Base::Table instance

=back

Returns: an instance of a DB::Introspector::Base::ForeignKey

=back



=item $foreign_key->local_table

=over 4

Returns: The child table in this foreign key relationship

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

The DB::Introspector::Base::ForeignKey module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
