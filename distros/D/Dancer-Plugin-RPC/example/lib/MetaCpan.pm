package MetaCpan;
use Moo;
use Scalar::Util 'blessed';

has mc_client => (
    is       => 'ro',
    isa      => sub { blessed($_[0]) eq 'MetaCpanClient' },
    required => 1
);

sub mc_search {
    my $self = shift;
    my $args = shift;
    my $response = $self->mc_client->call($args->{query});
    if (exists $response->{hits}) {
        my @hits = map {
            {
                author       => $_->{_source}{author},
                date         => $_->{_source}{date},
                distribution => $_->{_source}{distribution},
                module       => $_->{_source}{main_module},
                name         => $_->{_source}{name},
                version      => $_->{_source}{version},
            }
        } sort {
               $a->{_source}{main_module} cmp $b->{_source}{main_module}
            || $a->{_source}{version_numified} <=> $b->{_source}{version_numified}
        } @{ $response->{hits}{hits} };

        return {hits => \@hits};
    }
    return {hits => [ ]};
}

1;

=head1 NAME

MetaCpan - Interface to  MetaCpan (https://fastapi.metacpan.org/v1/release/_search)

=head1 SYNOPSIS

    use MetaCpanClient;
    use MetaCpan;
    my $mc_client = MetaCpanClient->new(
        endpoint => 'https://fastapi.metacpan.org/v1/release/_search',
    );
    my $mc = MetaCpan->new(mc_client => $mc_client);

    my $hits = $mc->mc_search({query => 'Dancer::Plugin::RPC'});

=head1 DESCRIPTION

=head2 mc_search({query => $query})

Returns a summary of the hits that MetaCpan returns.

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
