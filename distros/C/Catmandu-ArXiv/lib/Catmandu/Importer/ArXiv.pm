package Catmandu::Importer::ArXiv;

use Catmandu::Sane;
use Catmandu::Importer::XML;
use Catmandu::Fix::Condition::is_valid_orcid as => 'is_valid_orcid';
use Moo;
use Furl;

with 'Catmandu::Importer';

# INFO:
# http://arxiv.org/help/api/index/

use constant BASE_URL => 'http://export.arxiv.org/api/query?';

has base => ( is => 'ro', default => sub { return BASE_URL; } );
has query => ( is => 'ro' );
has id    => ( is => 'ro' ); # can be a comma seperated list
has start => ( is => 'ro' );
has limit => ( is => 'ro' );

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
    die $res->status_line unless $res->is_success;

    return $res;
}

sub _call {
    my ($self) = @_;

    my $url;
    if ($self->query && is_valid_orcid({orcid => $self->query}, 'orcid')) {
        $url = "https://arxiv.org/a/" . $self->query . ".atom2";
    }
    else {
        $url = $self->base;
        $url .= 'search_query=' . $self->query if $self->query;
        $url .= '&id_list=' . $self->id        if $self->id;
        $url .= '&start=' . $self->start       if $self->start;
        $url .= '&max_results=' . $self->limit if $self->limit;
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

  Catmandu::Importer::ArXiv - Package that imports data from http://arxiv.org/.

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

=item query

Search by query.

=item id

Search by one or many arXiv ids. This parameter accepts a comma-separated list of ids. This parameter accepts also an ORCID ID.

=item start

Start parameter for pagination.

=item limit

Limit parameter for pagination.

=back

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::Importer::Inspire>

=cut
