package DBIx::Class::IndexSearch::ResultSet::Dezi;

use Moo;
extends 'DBIx::Class::ResultSet';

use Carp;
=head1 SUBROUTINES/METHODS

=head2 search_dezi ( $self, \%search, \%attributes )

Searches the Dezi webservice for results and maps the results over
to inflate objects.

=cut
sub search_dezi {
    my ( $self, $search, $attributes ) = @_;

    my $result_class = $self->result_class;

    my @search = ref $search eq 'ARRAY' ? @{$search} :
                 ref $search eq 'HASH'  ? %{$search} :
                 croak 'search_dezi only accepts an arrayref or a hashref';

    my $map_field = $result_class->map_to;
    my @ids;

    while ( my $column = shift @search ) {
        my $value = shift @search;
        if ( $result_class->index_key_exists($column) ) {
            my $dezi = $result_class->webservice;
            my $response = $dezi->search( q => $value );

            @ids = map {
              $_->{$map_field}->[0]
            } 
            @{$response->results};
        }
    }

    return $self->search({ $map_field => \@ids });
}

1;
