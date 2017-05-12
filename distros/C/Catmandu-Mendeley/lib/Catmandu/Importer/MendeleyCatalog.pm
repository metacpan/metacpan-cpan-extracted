package Catmandu::Importer::MendeleyCatalog;

use Catmandu::Sane;
use Moo;
use OAuth::Lite2::Client::ClientCredentials;
use HTTP::Tiny;
use JSON::XS;
use Catmandu::Util qw(is_value);

with 'Catmandu::Importer';

my $DOCUMENT_CONTENT_TYPE = 'application/vnd.mendeley-document.1+json';
my $CATALOG_SEARCH_PATH = '/search/catalog';
my $CATALOG_PATH = '/catalog';
my @QUERY_FIELDS = qw(title author source abstract);
my @IDENTIFIER_FIELDS = qw(arxiv doi isbn issn pmid scopus filehash);

has client_id => (is => 'ro', required => 1);
has client_secret => (is => 'ro', required => 1);
has client => (is => 'lazy');
has params => (is => 'ro', default => sub { +{} });
has path => (is => 'rwp', default => sub { $CATALOG_SEARCH_PATH });

sub BUILD {
    my ($self, $args) = @_;
    my @query_keys = grep { is_value($args->{$_}) } @QUERY_FIELDS;
    my @identifier_keys = grep { is_value($args->{$_}) } @IDENTIFIER_FIELDS;
    my $params = $self->params;
    $params->{view} = $args->{view} || 'all';
    # get by id
    if (is_value($args->{id})) {
        $self->_set_path("$CATALOG_PATH/$args->{id}");
    # query search
    } elsif (is_value($args->{query})) {
        $params->{query} = $args->{query};
        $params->{limit} = $args->{limit} if is_value($args->{limit});
    # fielded search
    } elsif (@query_keys) {
        $params->{$_} = $args->{$_} for @query_keys;
        $params->{limit} = $args->{limit} if is_value($args->{limit});
    # identifier search
    } elsif (@identifier_keys) {
        $params->{$_} = $args->{$_} for @identifier_keys;
        $self->_set_path($CATALOG_PATH);
    } else {
        die "Missing required arguments";
    }
}

sub _build_client {
    my ($self) = @_;
    OAuth::Lite2::Client::ClientCredentials->new(
        id => $self->client_id,
        secret => $self->client_secret,
        access_token_uri => 'https://api.mendeley.com/oauth/token',
    );
}

sub generator {
    my ($self) = @_;
    sub {
        state $docs = $self->_get_documents;
        shift @$docs;
    };
}

sub _get_documents {
    my ($self) = @_;
    my $token = $self->client->get_access_token->access_token;
    my $http = HTTP::Tiny->new;
    my $path = $self->path;
    my $params = $http->www_form_urlencode($self->params);
    my $res = $http->get("https://api.mendeley.com/$path?$params", {
        headers => {
            Accept => $DOCUMENT_CONTENT_TYPE,
            Authorization => sprintf(q{Bearer %s}, $token)
        }
    });
    decode_json($res->{content});
}

1;

