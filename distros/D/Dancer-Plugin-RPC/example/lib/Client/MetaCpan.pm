package Client::MetaCpan;
use Moo;

use JSON;

with 'Client::HTTP';

sub call {
    my $self = shift;
    my ($query) = @_;

    $query =~ s{::}{-}g;
    (my $endpoint = $self->base_uri->as_string) =~ s{/+$}{};
    my $response = $self->client->request(
        GET => $endpoint . "/?q=$query"
    );

    my $content = eval { decode_json($response->{content}) };
    return $content if !$@;
    return { error => $@, data => $response->{content} };
}

1;

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
