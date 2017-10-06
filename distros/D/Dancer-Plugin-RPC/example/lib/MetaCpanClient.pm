package MetaCpanClient;
use Moo;

use JSON;

with 'HTTPClient';

sub call {
    my $self = shift;
    my ($query) = @_;

    $query =~ s{::}{-}g;
    (my $endpoint = $self->endpoint->as_string) =~ s{/+$}{};
    my $response = $self->client->request(
        GET => $endpoint . "/?q=$query"
    );

    my $content = eval { decode_json($response->{content}) };
    return $content if !$@;
    return { error => $@, data => $response->{content} };
}

1;
