package Catmandu::Importer::Blacklight;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use REST::Client;
use URI::Escape;
use JSON::MaybeXS;
use Moo;
use feature 'state';

with 'Catmandu::Importer';

has url     => (is => 'ro', required => 1);
has q       => (is => 'ro', required => 1);
has client  => (is => 'lazy');

sub _build_client {
    my $self;
    REST::Client->new();
}

sub generator {
    my ($self) = @_;

    sub {
        state $response = $self->query($self->q(),1);
        state $idx      = 0;

        unless (defined($response)) {
            print STDERR "Catmandu::Importer::Blacklight no response from: " . $self->url . "\n";
            return undef;
        }

        if (defined $response && ! defined $response->{docs}->[$idx]) {
            $response = $self->query($self->q(),$response->{pages}->{next_page});
            $idx = 0;  
        }

        return unless defined($response->{docs}->[0]);

        my $doc = $response->{docs}->[$idx];
        my $id  = $doc->{id};

        $idx++;

        { '_id' => $id , %$doc};
    };
}

sub query {
    my ($self,$q,$page)  = @_;

    return undef unless defined($page) && $page =~ /^\d+$/;

    my $url        = sprintf "%s?q=%s&page=%d" , $self->url, uri_escape($q), $page;
    my $response   = $self->client->GET($url, { Accept => 'application/json' });

    return undef unless ($response->responseCode eq '200');

    my $json   = $response->responseContent;
    my $perl   = decode_json($json);

    $perl->{response};
}

1;

__END__

=head1 NAME

Catmandu::Importer::Blacklight - Import records from a Blacklight catalog

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert Blacklight --url http://lib.ugent.be/catalog -q Schopenhauer

    # In perl
    use Catmandu::Importer::Blacklight;

    my $importer = Catmandu::Importer::Blacklight->new(
                    url => "...",
                    q   => "..."
      );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 CONFIGURATION

=over

=item url

Blacklight catalog Base URL. Required

=item q

Query string to search. Required

=back

=head1 DESCRIPTION

Every Catmandu::Importer is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::Blacklight methods are not idempotent: Blacklight
feeds can only be read once.

=head1 SEE ALSO

L<http://projectblacklight.org/> ,
L<Catmandu::Importer> ,
L<Catmandu::Iterable>

=cut
