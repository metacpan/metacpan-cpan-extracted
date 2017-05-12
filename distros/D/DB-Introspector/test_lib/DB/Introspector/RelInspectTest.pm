package DB::Introspector::RelInspectTest;

use strict;
use base qw( DB::IntrospectorBaseTest );

use DB::Introspector::Util::RelInspect;


sub test_find_mapped_paths_between_tables {
    my $self = shift;

    my $users               = $self->_introspector->find_table("users");
    my $grouped_user_images =
      $self->_introspector->find_table("grouped_user_images");

    $self->assert( defined $users, "table users is not defined" );
    $self->assert(  defined $grouped_user_images, 
                    "table grouped_user_images is not defined" );

    my $paths = DB::Introspector::Util::RelInspect
              ->find_mapped_paths_between_tables( $users, $grouped_user_images);

    $self->assert( defined $paths, "paths is undefined" );
    $self->assert( @$paths == 1, "path length is ".@$paths." expected 1" );


    my ($path) = @$paths; 
    $self->assert( defined $path, "path is undefined" );
    $self->assert( $path->head_table->name eq $users->name,
        "invalid table name found " . $path->head_table->name );

    $self->assert( $path->tail_table->name eq $grouped_user_images->name,
        "invalid table name found " . $path->tail_table->name );

    $self->assert( $path->length == 2,
        "path length is " . $path->length . " when expected 2" );


    my @expected_head_columns = qw( user_id );
    my @head_columns = $path->head_columns;

    foreach my $index (0..$#expected_head_columns) {
        $self->assert(
         $expected_head_columns[$index] eq $head_columns[$index],
         "expected $expected_head_columns[$index] found $head_columns[$index]");
    }
}

sub test_find_path_between_two_tables {
    my $self = shift;

    my $users               = $self->_introspector->find_table("users");
    my $groups               = $self->_introspector->find_table("groups");

    $self->assert( defined $users, "table users is not defined" );
    $self->assert( defined $groups, "table groups is not defined" );

    my $paths = DB::Introspector::Util::RelInspect
                        ->find_paths_between_two_tables( $users, $groups);

    $self->assert( defined $paths, "paths is undefined" );
    $self->assert( @$paths == 1, "path length is ".@$paths." expected 1" );


    my ($path) = @$paths;
    $self->assert( defined $path, "path is undefined" );

    $self->assert( $path->length == 2,
        "path length is " . $path->length . " when expected 2" );

    $self->assert( $path->head_table->name eq $users->name,
        "invalid table name found " . $path->head_table->name );

    $self->assert( $path->tail_table->name eq $groups->name,
        "invalid table name found " . $path->tail_table->name );


}

1;
