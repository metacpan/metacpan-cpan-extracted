#!perl

use Data::Frame::Setup;

use Test2::V0;

use Data::Frame;
use PDL::Core qw(pdl);

my $a = pdl( 1, 2, 3, 4 );
my $b = $a >= 2;
my $c = [qw/foo bar baz quux/];

my $df = Data::Frame->new(
    columns => [
        z => $a,
        y => $b,
        x => $c,
    ]
);
Moo::Role->apply_roles_to_object( $df, qw(Data::Frame::Role::Rlike) );

subtest number_of_rows => sub {
    my @rows               = ( 3, 1 );
    my $df_select_array    = $df->select_rows(@rows);
    my $df_select_arrayref = $df->select_rows( [@rows] );
    my $df_select_pdl      = $df->select_rows( pdl [@rows] );
    is( $df_select_array->number_of_rows,
        scalar(@rows), 'number_of_rows(@rows)' );
    is( $df_select_arrayref->number_of_rows,
        scalar(@rows), 'number_of_rows($rows)' );
    is( $df_select_pdl->number_of_rows, scalar(@rows), 'number_of_rows($pdl)' );

    is( $df->select_rows()->number_of_rows, 0, 'number_of_rows()' );
    is( $df->select_rows( [] )->number_of_rows, 0, 'number_of_rows([])' );
};

subtest subset => sub {
    my $df_subset = $df->subset( sub { $_->('z') > 2 } );
    is( $df_subset->row_names->unpdl, [ 2 .. 3 ] );

    my $df_subset_autoload = $df->subset( sub { $_->z > 2 } );
    is( $df_subset_autoload->row_names->unpdl, [ 2 .. 3 ] );

    my $df_subset_further = $df_subset->subset( sub { $_->('z') == 3 } );
    is( $df_subset_further->row_names->unpdl, [2] );
};

done_testing;
