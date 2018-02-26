package Catmandu::Importer::EuropePMC;

our $VERSION = '1.01';

use Catmandu::Sane;
use Catmandu::Importer::XML;
use Try::Tiny;
use Furl;
use Moo;

with 'Catmandu::Importer';

use constant BASE_URL => 'https://www.ebi.ac.uk/europepmc/webservices/rest';

has base_url   => ( is => 'ro', default => sub { return BASE_URL; } );
has source => ( is => 'ro', default => sub { return "MED"; } );
has module => ( is => 'ro', default => sub { return "search"; } );
has query  => ( is => 'ro' );
has pmid   => ( is => 'ro' );
has db     => ( is => 'ro' );
has page   => ( is => 'ro' );
has raw => (is => 'ro');

sub BUILD {
    my $self = shift;

    Catmandu::BadVal->throw("Either 'pmid' or 'query' is required.")
        unless $self->pmid || $self->query;

}

my %PATH_MAPPING = (
    search        => 'result',
    citations     => 'citation',
    references    => 'reference',
    databaseLinks => 'dbCrossReference'
);

sub _request {
    my ( $self, $url ) = @_;

    my $ua = Furl->new( timeout => 20 );

    my $res;
    try {
        $res = $ua->get($url);
        #die $res->status_line unless $res->is_success;

        $res->is_success ? return $res->content : return '';
    }
    catch {
        Catmandu::Error->throw("Status code: $res->status_line");
    };

}

sub _parse {
    my ( $self, $in ) = @_;

    my $path;
    ($self->raw) ? ($path = '')
        : ($path = $PATH_MAPPING{ $self->module });
    my $xml = Catmandu::Importer::XML->new( file => \$in, path => $path );

    return $xml->to_array;
}

sub _call {
    my ($self) = @_;

    my $url = $self->base_url;
    if ( $self->module eq 'search' ) {
        $url .= '/search?query=' . $self->query;
    }
    else {
        $url .= '/' . $self->source . '/' . $self->pmid . '/' . $self->module;
        $url .= '/' . $self->db if $self->db;
        $url .= '/' . $self->page if $self->page;
    }

    my $res = $self->_request($url);

    return $res;
}

sub _get_record {
    my ($self) = @_;

    return $self->_parse( $self->_call );
}

sub generator {

    my ($self) = @_;

    return sub {
        state $stack = $self->_get_record;
        my $rec = pop @$stack;
        if ($self->raw) {
            return $rec;
        } else {
        $rec->{ $PATH_MAPPING{ $self->module } }
            ? ( return $rec->{ $PATH_MAPPING{ $self->module } } )
            : return undef;
        }
    };

}

1;

=head1 NAME

  Catmandu::Importer::EuropePMC - Package that imports EuropePMC data.

=head1 API Documentation

  This module uses the REST service as described at http://www.ebi.ac.uk/europepmc/.

=head1 SYNOPSIS

  use Catmandu::Importer::EuropePMC;

  my %attrs = (
    source => 'MED',
    query => 'malaria',
    module => 'search',
    db => 'EMBL',
    page => '2',
  );

  my $importer = Catmandu::Importer::EuropePMC->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=head1 CONFIGURATION

=over

=item base_url

Specify the base url of the API. The default is 'https://www.ebi.ac.uk/europepmc/webservices/rest'.

=item source

The default is 'MED'.

=item query

Provide a search query. Either pmid or query is required.

=item pmid

Specify the PMID of the record you want to import. Either pmid or query is required.

=item module

The default is 'search', other possible values are 'databaseLinks', 'citations' and 'references'.

=item db

Set the name of the database. Use this when module is set to 'databaseLinks'.

=item page

Optional. Set the paging parameter.

=item raw

Optional. If set to true it delivers the raw xml object.

=back

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Iterable>, L<Catmandu::Fix>,

=cut
