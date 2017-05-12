package Catmandu::Importer::PLoS;

use Catmandu::Sane;
use Moo;
use Furl;
use XML::LibXML::Simple qw(XMLin);

with 'Catmandu::Importer';


# INFO:
# http://api.plos.org/solr/search-fields/


# Constants. -------------------------------------------------------------------

use constant BASE_URL    => 'http://api.plos.org/search';


# Properties. ------------------------------------------------------------------

# required.
has base => (is => 'ro', default => sub { return BASE_URL; });
has query => (is => 'ro', required => 1);

# optional.
has api_key => (is => 'ro');

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n => (is => 'ro', default => sub { 0 });
has _numFound => (is => 'ro', default => sub { 0 });
has _start => (is => 'ro', default => sub { 0 });
has _rows => (is => 'ro', default => sub { 10 });


# Internal Methods. ------------------------------------------------------------

# Internal: HTTP GET something.
#
# $url - the url.
#
# Returns the raw response object.
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
# $in - the raw XML input.
#
# Returns a hash representation of the given XML.
sub _hashify {
  my ($self, $in) = @_;

  my $xs = XML::LibXML::Simple->new();
  my $out = $xs->XMLin(
	  $in, 
	  ForceArray => [ 'doc' ]
  );

  return $out;
}

# Internal: Make a call to the PLoS API.
#
# Returns the XML response body.
sub _api_call {
  my ($self) = @_;

  # construct the url
  my $url = $self->base;
  $url .= '?q='.$self->query;
  $url .= '&start='.$self->{_start};
  $url .= '&rows='.$self->{_rows};
  $url .= '&api_key='.$self->api_key if $self->api_key;

  # http get the url.
  my $res = $self->_request($url);

  # return the response body.
  return $res->{content};
}

# Internal: gets the next set of results.
#
# Returns a array representation of the resultset.
sub _nextRecordSet {
  my ($self) = @_;

  # fetch the xml response and hashify it.
  my $xml = $self->_api_call();
  my $hash = $self->_hashify($xml);

  # on first request, get total number of results.
  $self->{_numFound} = $hash->{result}->{numFound} unless $self->_numFound;

  # get to the point.
  my $set = $hash->{result}->{doc};

  # return a reference to the hash.
  return \@{$set};
}

# Internal: gets the next record from our current resultset.
#
# Returns a hash representation of the next record.
sub _nextRecord {
  my ($self) = @_;

  # fetch recordset if we don't have one yet.
  $self->{_currentRecordSet} = $self->_nextRecordSet unless $self->_currentRecordSet;

  # check for a exhaused recordset.
  if ($self->{_n} >= $self->_rows) {
    $self->{_currentRecordSet} = $self->_nextRecordSet;
	$self->{_start} += $self->_rows;
    $self->{_n} = 0;
  }

  # return the next record.
  return $self->_currentRecordSet->[$self->{_n}++];
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

  Catmandu::Importer::PLoS - Package that imports PLoS data.

=head1 SYNOPSIS

  use Catmandu::Importer::PLoS;

  my %attrs = (
    query => 'github',
    api_key => ''
  );

  my $importer = Catmandu::Importer::PLoS->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
