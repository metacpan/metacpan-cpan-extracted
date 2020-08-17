package Client::MetaCpan;
use Moo;

use JSON;

with 'Client::HTTP';

sub call {
    my $self = shift;
    my ($query) = @_;

    $query =~ s{::}{-}g;
    my $params = $http->www_form_urlencode("q=$query");

    (my $endpoint = $self->base_uri->as_string) =~ s{/+$}{};
    my $response = $self->client->get("$endpoint/?$params");

    my $content = eval { decode_json($response->{content}) };
    return $content if !$@;
    return { error => $@, data => $response->{content} };
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
