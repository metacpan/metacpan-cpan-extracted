package Catmandu::Importer::ArXiv;

our $VERSION = '0.212';

use Catmandu::Sane;
use Catmandu::Importer::XML;
use Catmandu::Fix::Condition::is_valid_orcid as => 'is_valid_orcid';
use Moo;
use Furl;
use URI;

with 'Catmandu::Importer';

# INFO:
# https://arxiv.org/help/api/index/

has base_api => ( is => 'ro', default => sub { return "https://export.arxiv.org/api/query"; } );
has base_frontend => (is => 'ro', default => sub { return "https://arxiv.org"; } );
has query => ( is => 'ro' );
has id    => ( is => 'ro' ); # can be a comma seperated list
has start => ( is => 'ro', default => sub { return 0; } );
has limit => ( is => 'ro' , default => sub { return 20; });

sub BUILD {
    my $self = shift;

    Catmandu::BadVal->throw("Either id or query required.")
        unless $self->id || $self->query;
}

sub _request {
    my ( $self, $url ) = @_;

    my $furl = Furl->new(
        agent   => 'Mozilla/5.0',
        timeout => 20,
    );

    my $res = $furl->get($url);
    return $res;
}

sub _call {
    my ($self) = @_;

    my $url;
    if ($self->query && is_valid_orcid({orcid => $self->query}, 'orcid')) {
        my $u1 = URI->new($self->base_frontend);
        $u1->path("a/" . $self->query . ".atom2");
        $url =  $u1->as_string;
    }
    else {
        my $u2 = URI->new($self->base_api);
        $u2->query_form(
            search_query => $self->query // '',
            id_list => $self->id // '',
            start => $self->start,
            max_results => $self->limit,
        );
        $url = $u2->as_string;
    }

    my $res = $self->_request($url);

    return $res->{content};
}

sub _parse {
    my ( $self, $in ) = @_;

    my $xml = Catmandu::Importer::XML->new( file => \$in, path => 'entry' );
    return $xml->to_array;
}

sub _get_record {
    my ($self) = @_;

    my $xml   = $self->_call;
    my $stack = $self->_parse($xml);
    return $stack;
}

sub generator {
    my ($self) = @_;

    return sub {
        state $stack = $self->_get_record;
        my $rec = pop @$stack;
        $rec->{entry} ? return $rec->{entry} : return undef;
    };
}

1;

=head1 NAME

  Catmandu::Importer::ArXiv - Package that imports data from https://arxiv.org/.

=head1 SYNOPSIS

  use Catmandu::Importer::ArXiv;

  my %attrs = (
    query => 'all:electron'
  );

  my $importer = Catmandu::Importer::ArXiv->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=head1 CONFIGURATION

=over

=item base_api

The API endpoint. Default is https://export.arxiv.org/api/query

=item base_frontend

The arXiv base url. Default is https://arxiv.org

=item query

Search by query.

=item id

Search by one or many arXiv ids. This parameter accepts a comma-separated list of ids.
This parameter accepts also an ORCID iD.

=item start

Start parameter for pagination.

=item limit

Limit parameter for pagination.

=back

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Importer::Inspire>

=cut
