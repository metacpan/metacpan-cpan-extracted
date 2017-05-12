package Catmandu::Importer::PubMed;

use Catmandu::Sane;
use Moo;
use Furl;
use XML::LibXML::Simple qw(XMLin);

with 'Catmandu::Importer';


# INFO:
# http://www.ncbi.nlm.nih.gov/books/NBK25499/


# Constants. -------------------------------------------------------------------

use constant EUTILS_BASE    => 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
use constant ESEARCH_AFFIX  => 'esearch.fcgi';
use constant EFETCH_AFFIX   => 'efetch.fcgi';
use constant DATABASE       => 'pubmed';


# Properties. ------------------------------------------------------------------

# required.
has base => (is => 'ro', default => sub { return EUTILS_BASE; });
has db => (is => 'ro', default => sub { return DATABASE; });
has term => (is => 'ro', required => 1);

# optional.
has field => (is => 'ro');
has datetype => (is => 'ro');
has reldate => (is => 'ro');
has mindate => (is => 'ro');
has maxdate => (is => 'ro');

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n => (is => 'ro');


# Internal Methods. ------------------------------------------------------------

# Internal: Does a generic HTTP GET request.
#
# $url - The url of the resource to get.
#
# Returns the raw response body.
sub _request {
  my ($self, $url) = @_;

  my $furl = Furl->new(
    agent => 'Mozilla/5.0',
    timeout => 10
  );

  my $res = $furl->get($url);
  die $res->status_line unless $res->is_success;

  return $res;
}

# Internal: Converts XML to a perl hash.
#
# $url - The raw XML input.
#
# Returns a hash from the given XML.
sub _hashify {
  my ($self, $in) = @_;

  my $xs = XML::LibXML::Simple->new();
  my $out = $xs->XMLin(
	  $in,
	  ForceArray => [ 'PubmedData' ]
  );

  return $out;
}

# Internal: eSearch request (text searches).
#
# Responds to a text query with the list of matching UIDs in a given database
# (for later use in ESummary, EFetch or ELink), along with the term translations
# of the query.
#
# Returns eSearch XML document.
sub _eSearch {
  my ($self) = @_;

  my $url = $self->base . ESEARCH_AFFIX
                     . '?db=' . $self->db
                     . '&term=' . $self->term
                     . '&usehistory=y';

  $url .= '&field=' . $self->field if ($self->field);
  $url .= '&datetype=' . $self->datetype if ($self->datetype);
  $url .= '&reldate=' . $self->reldate if ($self->reldate);
  $url .= '&mindate=' . $self->mindate if ($self->mindate);
  $url .= '&maxdate=' . $self->maxdate if ($self->maxdate);

  # Fetch.
  my $res = $self->_request($url);

  return $res->{content};
}

# Internal: eFetch request (data record downloads).
#
# Responds to a list of UIDs in a given database
# with the corresponding data records in a specified format.
#
# $webEnv   - webEnv param.
# $queryKey - query_key param.
#
# Returns Formatted data records (e.g. abstracts, FASTA).
sub _eFetch {
  my ($self, $webEnv, $queryKey) = @_;

  my $url = $self->base . EFETCH_AFFIX
                     . '?db=' . $self->db
                     . '&query_key=' . $queryKey
                     . '&WebEnv=' . $webEnv
                     . '&retmode=xml';

  my $res = $self->_request($url);

  return $res->{content};
}

# Internal: gets the set of results.
#
# Returns a array representation of the resultset.
sub _getRecordSet {
  my ($self) = @_;

  # fetch the eSearch xml response and extract webEnv & queryKey.
  my $eSearchResult = $self->_eSearch();

  my $webEnv;
  if ( $eSearchResult =~ /<WebEnv>(\S+)<\/WebEnv>/) { $webEnv = $1; }
  die "Couldn't extract webEnv." unless $webEnv;

  my $queryKey;
  if ($eSearchResult =~ /<QueryKey>(\d+)<\/QueryKey>/) { $queryKey = $1; }
  die "Couldn't extract queryKey." unless $queryKey;

  # fetch the eFetch xml response and hashify it.
  my $eFetchResult = $self->_eFetch($webEnv, $queryKey);
  my $hash = $self->_hashify($eFetchResult);
  $hash = $hash->{'PubmedArticle'};

  # return a reference to a array.
  return \@{$hash};
}

sub _nextRecord {
  my ($self) = @_;

  # fetch recordset if we don't have one yet.
  $self->{_currentRecordSet} = $self->_getRecordSet unless $self->_currentRecordSet;

  # return the next record.
  return $self->{_currentRecordSet}->[$self->{_n}++];
}


# Public Methods. --------------------------------------------------------------

sub generator {
  my ($self) = @_;

  return sub {
    $self->_nextRecord;
  };
}


# PerlDoc. ---------------------------------------------------------------------

=head1 NAME

  Catmandu::Importer::PubMed - Package that imports PubMed data.

=head1 SYNOPSIS

  use Catmandu::Importer::PubMed;

  my %attrs = (
    term => 'github'
  );

  my $importer = Catmandu::Importer::PubMed->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
