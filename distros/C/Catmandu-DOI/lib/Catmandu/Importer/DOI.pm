package Catmandu::Importer::DOI;

use Catmandu::Sane;
use Moo;
use Furl;
use XML::LibXML::Simple qw(XMLin);

with 'Catmandu::Importer';


# INFO:
# http://help.crossref.org/#retrieving_doi_information


# Constants. -------------------------------------------------------------------

use constant BASE_URL => 'http://doi.crossref.org/search/doi';


# Properties. ------------------------------------------------------------------

has base => (is => 'ro', default => sub { return BASE_URL; });

# required.

## doi to get the meta data for.
has doi => (is => 'ro', required => 1);

## usr is your CrossRef-supplied login name.
has usr => (is => 'ro', required => 1); 

## pwd is your CrossRef password.
has pwd => (is => 'ro', required => 1);

# optional.

## format is the desired results format ( xsd_xml | unixref | unixsd | info).
has format => (is => 'ro', default => sub { 'unixref' }); 

# internal.
has _api_key => (is => 'lazy', builder => '_get_api_key');
has _current_result => (is => 'ro');


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
  my $out = $xs->XMLin($in);

  return $out;
}

# Internal: Constructs api key.
#
# Returns a string representing our api key.
sub _get_api_key {
	my ($self) = @_;
	
	return $self->usr.':'.$self->pwd;
}

# Internal: Makes a call to the PLoS API.
#
# Returns the XML response body.
sub _api_call {
  my ($self) = @_;

  # construct the url
  my $url = $self->base;
  $url .= '?pid='.$self->_api_key;
  $url .= '&doi='.$self->doi;
  $url .= '&format='.$self->format;

  # http get the url.
  my $res = $self->_request($url);

  # return the response body.
  return $res->{content};
}

# Internal: gets the result.
#
# Returns a hash representation of the result.
sub _get_record {
  my ($self) = @_;

  unless ($self->_current_result) {
	  # fetch the xml response and hashify it.
	  my $xml = $self->_api_call;
	  my $hash = $self->_hashify($xml);

	  # get to the point.
	  $self->{_current_result} = $hash->{doi_record}->{crossref};
  };

  return $self->_current_result;
}


# Public Methods. --------------------------------------------------------------

sub to_array {
	return [$_[0]->_get_record]; 
}

sub first {
	return [$_[0]->_get_record];
}

*last = \&first;

sub generator {
  my ($self) = @_;
  my $return = 1;

  return sub {
	  # hack to make iterator stop.
	  if ($return) {
		  $return = 0;
		  return $self->_get_record;
	  }
	  return undef;
  };
}


# PerlDoc. ---------------------------------------------------------------------

=head1 NAME

  Catmandu::Importer::DOI - Package that imports DOI data.
  Take an existing DOI and lookup the metadata for it.

=head1 SYNOPSIS

  use Catmandu::Importer::DOI;

  my %attrs = (
    doi => '<doi>',
    usr => '<your-crossref-username>',
	pwd => '<your-crossref-password>',
	format => '<xsd_xml | unixref | unixsd | info>'
  );

  my $importer = Catmandu::Importer::DOI->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;