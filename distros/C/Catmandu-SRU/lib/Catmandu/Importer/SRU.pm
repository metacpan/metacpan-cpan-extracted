package Catmandu::Importer::SRU;

use Catmandu::Sane;
use Moo;
use Furl;
use XML::LibXML::Simple qw(XMLin);

with 'Catmandu::Importer';


# INFO:
# http://www.loc.gov/standards/sru/


# Constants. -------------------------------------------------------------------

use constant VERSION => '1.1';
use constant OPERATION => 'searchRetrieve';
use constant RECORDSCHEMA => 'dc';


# Properties. ------------------------------------------------------------------

# required.
has base => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has version => (is => 'ro', default => sub { return VERSION; });
has operation => (is => 'ro', default => sub { return OPERATION; });
has recordSchema => (is => 'ro', default => sub { return RECORDSCHEMA; });

# optional.
has sortKeys => (is => 'ro');

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n => (is => 'ro', default => sub { 0 });
has _start => (is => 'ro', default => sub { 1 });
has _max_results => (is => 'ro', default => sub { 10 });


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
	  ForceArray => [ 'record' ],
	  NsStrip => 1
  );

  return $out;
}

# Internal: Makes a call to the SRU API.
#
# Returns the XML response body.
sub _api_call {
  my ($self) = @_;

  # construct the url
  my $url = $self->base;
  $url .= '?version='.$self->version;
  $url .= '&operation='.$self->operation;
  $url .= '&query='.$self->query;
  $url .= '&recordSchema='.$self->recordSchema;
  $url .= '&sortKeys='.$self->sortKeys if $self->sortKeys;
  $url .= '&startRecord='.$self->_start;
  $url .= '&maximumRecords='.$self->_max_results;

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
  my $xml = $self->_api_call;
  my $hash = $self->_hashify($xml);

  # sru specific error checking.
  if (my $error = $hash->{'diagnostics'}->{'diagnostic'}) {
    warn 'SRU DIAGNOSTIC: ', $error->{'message'};
  }

  # get to the point.
  my $set = $hash->{'records'}->{'record'};

  # return a reference to a array.
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
  if ($self->_n >= $self->_max_results) {
	  $self->{_currentRecordSet} = $self->_nextRecordSet;
	  $self->{_start} += $self->_max_results;
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

  Catmandu::Importer::SRU - Package that imports SRU data

=head1 SYNOPSIS

  use Catmandu::Importer::SRU;

  my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)'
  );

  my $importer = Catmandu::Importer::SRU->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

  `base` & `query` are required.
  `version` & `operation` have sensible defaults, '1.1' and 'searchRetrieve' respectively.

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
