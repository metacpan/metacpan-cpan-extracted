package Catmandu::Importer::SRU;

use Catmandu::Sane;
use Catmandu::Importer::SRU::Parser;
use Catmandu::Util qw(:is);
use URI::Escape;
use Moo;
use Furl;
use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;

with 'Catmandu::Importer';

# required.
has base => (is => 'ro', required => 1);
has query => (is => 'ro', required => 1);
has version => (is => 'ro', default => sub { '1.1' });
has operation => (is => 'ro', default => sub { 'searchRetrieve' });
has recordSchema => (is => 'ro', default => sub { 'dc' });
has userAgent => (is => 'ro', default => sub { 'Mozilla/5.0' });
has furl => (is => 'ro', lazy => 1, builder => sub {
    Furl->new( agent => $_[0]->userAgent );
});

# optional.
has sortKeys => (is => 'ro');
has parser => (is => 'rw', default => sub { 'simple' }, coerce => \&_coerce_parser );

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n => (is => 'ro', default => sub { 0 });
has _start => (is => 'ro', default => sub { 1 });
has _max_results => (is => 'ro', default => sub { 10 });

# Internal Methods. ------------------------------------------------------------

sub _coerce_parser {
  my ($parser) = @_;

  return $parser if is_invocant($parser) or is_code_ref($parser);

  if (is_string($parser) && !is_number($parser)) {
      my $class = $parser =~ /^\+(.+)/ ? $1
        : "Catmandu::Importer::SRU::Parser::$parser";

      my $parser;
      eval {
          $parser = Catmandu::Util::require_package($class)->new;
      };
      if ($@) {
        croak $@;
      } else {
        return $parser;
      }
  }

  return Catmandu::Importer::SRU::Parser->new;
}

# Internal: HTTP GET something.
#
# $url - the url.
#
# Returns the raw response object.
sub _request {
  my ($self, $url) = @_;

  my $res = $self->furl->get($url);
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

  my $parser = XML::LibXML->new();
  my $doc    = $parser->parse_string($in);
  my $root   = $doc->documentElement;
  my $xc     = XML::LibXML::XPathContext->new( $root );
  $xc->registerNs("srw","http://www.loc.gov/zing/srw/");
  $xc->registerNs("d","http://www.loc.gov/zing/srw/diagnostic/");
  
  my $diagnostics = {};

  if ($xc->exists('/srw:searchRetrieveResponse/srw:diagnostics')) {
    $diagnostics->{diagnostic} = [];

    for ($xc->findnodes('/srw:searchRetrieveResponse/srw:diagnostics/*')) {
       my $uri     = $xc->findvalue('./d:uri',$_);
       my $message = $xc->findvalue('./d:message',$_);
       my $details = $xc->findvalue('./d:details',$_);

       push @{$diagnostics->{diagnostic}} , 
                { uri => $uri , message => $message , details => $details } ;
    }
  }

  my $records = { };

  if ($xc->exists('/srw:searchRetrieveResponse/srw:records')) {
      $records->{record} = [];

      for ($xc->findnodes('/srw:searchRetrieveResponse/srw:records/srw:record')) {
        my $recordSchema   = $xc->findvalue('./srw:recordSchema',$_);
        my $recordPacking  = $xc->findvalue('./srw:recordPacking',$_);
        my $recordData     = '' . $xc->find('./srw:recordData/*',$_)->pop();
        my $recordPosition = $xc->findvalue('./srw:recordPosition',$_);
       
        push @{$records->{record}} , 
              { recordSchema => $recordSchema , recordPacking => $recordPacking , 
                recordData => $recordData , recordPosition => $recordPosition };
      }
  }

  return { diagnostics => $diagnostics , records => $records };
}

sub url {
  my ($self) = @_;

  # construct the url
  my $url = $self->base;
  $url .= '?version=' . uri_escape($self->version);
  $url .= '&operation=' .uri_escape($self->operation);
  $url .= '&query=' . uri_escape($self->query);
  $url .= '&recordSchema=' . uri_escape($self->recordSchema);
  $url .= '&sortKeys=' . uri_esacpe($self->sortKeys) if $self->sortKeys;
  $url .= '&startRecord=' . uri_escape($self->_start);
  $url .= '&maximumRecords=' . uri_escape($self->_max_results);

  return $url;
}

# Internal: gets the next set of results.
#
# Returns a array representation of the resultset.
sub _nextRecordSet {
  my ($self) = @_;

  # fetch the xml response and hashify it.
  my $res  = $self->_request($self->url);
  my $xml  = $res->{content};
  my $hash = $self->_hashify($xml);

  # sru specific error checking.
  if (exists $hash->{'diagnostics'}->{'diagnostic'}) {
    for my $error (@{$hash->{'diagnostics'}->{'diagnostic'}}) {
        warn 'SRU DIAGNOSTIC: ', $error->{'message'} , ' : ' , $error->{'details'};
    }
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
	  $self->{_start} += $self->_max_results;
	  $self->{_n} = 0;
    $self->{_currentRecordSet} = $self->_nextRecordSet;
  }

  # return the next record.
  my $record = $self->_currentRecordSet->[$self->{_n}++];

  if (defined $record) {
      if (is_code_ref($self->parser)) {
          $record = $self->parser->($record);
      } else {
          $record = $self->parser->parse($record);
      }
  }
  return $record;
}

# Public Methods. --------------------------------------------------------------

sub generator {
  my ($self) = @_;

  return sub {
    $self->_nextRecord;
  };
}

=head1 NAME

  Catmandu::Importer::SRU - Package that imports SRU data

=head1 SYNOPSIS

  use Catmandu::Importer::SRU;

  my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml',
    parser => 'marcxml'
  );

  my $importer = Catmandu::Importer::SRU->new(%attrs);

  my $count = $importer->each(sub {
	my $schema   = $record->{recordSchema};
	my $packing  = $record->{recordPacking};
	my $position = $record->{recordPosition};
	my $data     = $record->{recordData};
    # ...
  });

  # Using Catmandu::Importer::SRU::Package::marcxml, included in this release

  my $importer = Catmandu::Importer::SRU->new(
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml' ,
    parser => 'marcxml' ,
  );

  # Using a homemade parser
  
  my $importer = Catmandu::Importer::SRU->new(
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml' ,
    parser => MyParser->new , # or parser => '+MyParser'
  );

=head1 CONFIGURATION

=over

=item base

base URL of the SRU server (required)

=item query

CQL query (required)

=item recordSchema

set to C<dc> by default

=item sortkeys

optional sorting

=item operation

set to C<searchRetrieve> by default

=item version

set to C<1.1> by default.

=item userAgent

HTTP user agent, set to C<Mozilla/5.0> by default.

=item furl

Instance of L<Furl> or compatible class to fetch URLs with.

=item parser

Controls how records are parsed before importing. The following options
are possible:

=over

=item

Instance of a Perl package that implements a C<parse> subroutine. See the
default value C<Catmandu::Importer::SRU::Parser> for an example.

=item

Name of a Perl package that implements a C<parse> subroutine. The name must be
prepended by C<+> or it prefixed with C<Catmandu::Importer::SRU::Parser::>. For
instance C<marcxml> will create a C<Catmandu::Importer::SRU::Parser::marcxml>.

=item

Function reference that gets passed the unparsed record.
 
=back

=back

=head1 METHODS

All methods of L<Catmandu::Importer> and by this L<Catmandu::Iterable> are
inherited. In addition the following methods are provided:

=head2 url

Return the current SRU request URL (useful for debugging).

=head1 SEE ALSO

L<Catmandu::Importer>,
L<Catmandu::Iterable>,
L<http://www.loc.gov/standards/sru/>

=cut

1;
