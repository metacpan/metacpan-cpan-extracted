package Catmandu::CA::API::QueryBuilder;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use JSON;

has field_list => (is => 'ro', required => 1);

has query => (is => 'lazy');

sub _build_query {
    my $self = shift;

    if (scalar @{$self->field_list} == 0) {
        return encode_json({});
    }

    my $query = {
        'bundles' => {}
    };

    foreach my $field (@{$self->field_list}) {
        my $def = sprintf('%s', $field);
        $query->{'bundles'}->{$def} = {
            'returnAsArray' => JSON::true,
            'locale' => 'nl_BE'
        };
    }

    return encode_json($query);
}

1;
__END__