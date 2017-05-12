package DB::Introspector::Util::RelInspect;

use strict;
use DB::Introspector::ForeignKeyPath;
use DB::Introspector::MappedPath;

use vars qw( $SINGLETON );

sub _instance {
    my $class = shift;
    $SINGLETON ||= bless(\$class, $class);
    return $SINGLETON;
}

sub find_mapped_paths_between_tables {
    my $class = shift;
    my $root_table = shift;
    my $child_table = shift;
    my $path = shift ||  new DB::Introspector::MappedPath();
    my $path_list = shift || [];

    if( $root_table->name eq $child_table->name ) {
        unshift(@$path_list, $path);
        return [];
    }

    foreach my $foreign_key ($root_table->dependencies) {
        next if($foreign_key->local_table->name 
             eq $foreign_key->foreign_table->name);
        my $internal_path = $path->clone();
        $internal_path->append_foreign_key($foreign_key);
        $class->find_mapped_paths_between_tables( $foreign_key->local_table,
                                           $child_table, 
                                           $internal_path, 
                                           $path_list );
    }

    return $path_list;
}

sub find_paths_between_two_tables {
    my $class = shift;
    my $table_a = shift;
    my $table_b = shift;
    my $stop_at_first_contact = shift;

    my $visited = shift || {};
    my $path = shift;
    my $path_list = shift || [];

    if( $table_a->name eq $table_b->name && defined($path)) {
        push(@$path_list, $path); 
        return $path_list if($stop_at_first_contact);
    }

    $path ||= new DB::Introspector::ForeignKeyPath;

    return $path_list if( $visited->{$table_a->name} );
    local $visited->{$table_a->name} = 1;

    foreach my $foreign_key ( $table_a->foreign_keys ) {
        my $internal_path = $path->clone();
        $internal_path->append_foreign_key($foreign_key);
        $class->find_paths_between_two_tables( $foreign_key->foreign_table,
                                           $table_b,
                                           $stop_at_first_contact,
                                           $visited, 
                                           $internal_path,
                                           $path_list ); 
    }


    foreach my $foreign_key ( $table_a->dependencies ) {
        my $internal_path = $path->clone();
        $internal_path->append_foreign_key($foreign_key);
        $class->find_paths_between_two_tables( $foreign_key->local_table,
                                           $table_b,
                                           $stop_at_first_contact, 
                                           $visited, 
                                           $internal_path,
                                           $path_list ); 
    }


   return $path_list;
}


1;
__END__

=head1 NAME

DB::Introspector::Util::RelInspect

=head1 SYNOPSIS

 use DB::Introspector::Util::RelInspect;

 my @paths = DB::Introspector::Util::RelInspect
             ->find_mapped_paths_between_tables( $parent_table, $child_table );
     
=head1 DESCRIPTION

DB::Introspector::Util::RelInspect is a utility class that contains methods
that deal with relationship traversal.

=head1 METHODS

=over 4


=item find_paths_between_tables($table_1, $table_2, $option_stop_at_first_contact)

=over 4

Params:

=over 4

$table_1 - the first element of each path DB::Introspector::Base::Table

$table_2 - the last element of each path DB::Introspector::Base::Table

$option_stop_at_first_contact (1|0) - stop once the destination table
($table_2) has been encountered, rather than continuing to find paths from the
destination back to the destination

=back

Returns: (\@) of DB::Introspector::ForeignKeyPath instances.
All paths between $parent_table and $child_table.

=back



=item find_mapped_paths_between_tables($parent_table, $child_table)

=over 4

Params:

=over 4

$parent_table - the first element of each path

$child_table - the last element of each path 

=back

Returns: (\@) of DB::Introspector::MappedPath instances.
All paths between $parent_table and $child_table where $child_table
depends on $parent_table, even indirectly.

=back



=back


=head1 SEE ALSO

=over 4

L<DB::Introspector>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Util::RelInspect module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
