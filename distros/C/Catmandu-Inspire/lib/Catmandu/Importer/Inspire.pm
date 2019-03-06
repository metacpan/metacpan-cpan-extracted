package Catmandu::Importer::Inspire;

use Catmandu::Sane;
use Catmandu::Importer::XML;
use Furl;
use Moo;

with 'Catmandu::Importer';

use constant BASE_URL       => 'https://inspirehep.net/';
use constant DEFAULT_FORMAT => 'endnote';

has base => ( is => 'ro', default => sub { return BASE_URL; } );
has fmt  => ( is => 'ro', default => sub { return DEFAULT_FORMAT; } );
has doi  => ( is => 'ro' );
has query => ( is => 'ro' );
has id    => ( is => 'ro' );
has limit => ( is => 'ro', default => sub { return 25; } );

my %FORMAT_MAPPING = (
    'endnote' => 'xe',
    'nlm'     => 'xn',
    'marc'    => 'xm',
    'dc'      => 'xd',
);

my %PATH_MAPPING = (
    'endnote' => 'record',
    'nlm'     => 'article',
    'marc'    => 'record',
    'dc'      => 'dc:dc',
);

sub BUILD {
    my $self = shift;

    Catmandu::BadVal->throw("Either ID or DOI or a QUERY is required.")
        unless $self->id || $self->doi || $self->query;

    Catmandu::BadVal->throw(
        "Format '$self->fmt' is not allowed. Possible choices are endnote, nlm, marc, dc."
    ) unless exists $FORMAT_MAPPING{ $self->fmt };
}

sub _request {
    my ( $self, $url ) = @_;

    my $furl = Furl->new(
        agent   => 'Mozilla/5.0',
        timeout => 10,
    );

    my $res = $furl->get($url);
    die $res->status_line unless $res->is_success;

    return $res;
}

sub _parse {
    my ( $self, $in ) = @_;

    my $path = $PATH_MAPPING{ $self->fmt };
    my $xml = Catmandu::Importer::XML->new( file => \$in, path => $path );
    return $xml->to_array;
}

sub _call {
    my ($self) = @_;

    my $url = $self->base;
    my $fmt = $FORMAT_MAPPING{ $self->fmt };

    if ( $self->id ) {
        $url .= 'record/' . $self->id . '/export/' . $fmt;
    }
    else {
        $url .= 'search?p=';
        ( $self->doi )
            ? ( $url .= 'doi%3A' . $self->doi )
            : ( $url .= $self->query );

        $url .= '&of=' . $fmt;
        $url .= '&rg=' . $self->limit;
        $url .= '&action_search=Suchen';
    }

    my $res = $self->_request($url);

    return $res->{content};
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
        return pop @$stack;
    };
}

1;

=head1 NAME

  Catmandu::Importer::Inspire - Package that imports Inspire data http://inspirehep.net/.

=head1 SYNOPSIS

  use Catmandu::Importer::Inspire;

  my %attrs = (
    id => '1203476',
    fmt => 'endnote',
  );

  my $importer = Catmandu::Importer::Inspire->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=head1 CONFIGURATION

=over

=item id

Retrieve record by its Inspire ID.

=item doi

Retrieve record by its DOI from Inspire database.

=item query

Get results by an arbitrary query.

=item fmt

Specify the format to be delivered. Default is to 'endnote'. Other formats are 'nlm', 'marc' and 'dc'. 

=item limit

Maximum number of records. Default is to 25.

=back

=head1 SEE ALSO

L<Catmandu::Iterable>, L<Catmandu::ArXiv>, L<Catmandu::CrossRef>

=cut
