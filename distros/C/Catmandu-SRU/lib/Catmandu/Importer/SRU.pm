package Catmandu::Importer::SRU;

use Catmandu::Sane;
use Catmandu::Importer::SRU::Parser;
use Catmandu::Util qw(:is :check);
use URI::Escape qw(uri_escape uri_escape_utf8);
use Moo;
use HTTP::Tiny;
use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;
use namespace::clean;

our $VERSION = '0.428';

with 'Catmandu::Importer';

# required.
has base         => (is => 'ro', required => 1);
has query        => (is => 'ro', required => 1);
has version      => (is => 'ro', default  => sub {'1.1'});
has operation    => (is => 'ro', default  => sub {'searchRetrieve'});
has recordSchema => (is => 'ro', default  => sub {'dc'});
has userAgent    => (is => 'ro', default  => sub {'Mozilla/5.0'});
has http_client => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        HTTP::Tiny->new(agent => $_[0]->userAgent);
    }
);

# optional.
has sortKeys => (is => 'ro');
has parser =>
    (is => 'rw', default => sub {'simple'}, coerce => \&_coerce_parser);
has limit => (
    is      => 'ro',
    isa     => sub {check_natural($_[0]);},
    lazy    => 1,
    default => sub {10}
);
has total => (is => 'ro');

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n                => (is => 'ro', default => sub {0});
has _start            => (is => 'ro', default => sub {1});

# Internal Methods. ------------------------------------------------------------
my $NS_SRW            = "http://www.loc.gov/zing/srw/";
my $NS_SRW_DIAGNOSTIC = "http://www.loc.gov/zing/srw/diagnostic/";

sub _coerce_parser {
    my ($parser) = @_;

    return $parser if is_invocant($parser) or is_code_ref($parser);

    if (is_string($parser) && !is_number($parser)) {
        my $class
            = $parser =~ /^\+(.+)/
            ? $1
            : "Catmandu::Importer::SRU::Parser::$parser";

        my $parser;
        eval {$parser = Catmandu::Util::require_package($class)->new;};
        if ($@) {
            croak $@;
        }
        else {
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

    my $res = $self->http_client->get($url);
    die join(" ", grep defined, $res->{status}, $res->{reason})
        unless $res->{success};

    return $res;
}

# Internal: Converts XML to a perl hash.
#
# $in - the raw XML input.
#
# Returns a hash representation of the given XML.
sub _hashify {
    my ($self, $in) = @_;

    my $parser     = XML::LibXML->new();
    my $doc        = $parser->parse_string($in);
    my $root       = $doc->documentElement;
    my @namespaces = $root->getNamespaces;

    my $xc = XML::LibXML::XPathContext->new($root);
    $xc->registerNs("srw", $NS_SRW);
    $xc->registerNs("d",   $NS_SRW_DIAGNOSTIC);

    my $meta    = {requestUrl => $self->url};
    my $records = {};

    for ($xc->findnodes('/srw:searchRetrieveResponse')) {

        for ($xc->findnodes('./srw:diagnostics/d:diagnostic', $_)) {
            my %diag = (uri => $xc->findvalue('./d:uri', $_));
            $diag{message} = $_
                for grep {$_ ne ''} ($xc->findvalue('./d:message', $_));
            $diag{details} = $_
                for grep {$_ ne ''} ($xc->findvalue('./d:details', $_));
            push @{$meta->{diagnostics}}, \%diag;
        }

        for my $tag (
            qw(version numberOfRecords resultSetId resultSetIdleTime nextRecordPosition)
            )
        {
            for ($xc->findnodes("./srw:$tag", $_)) {
                $meta->{$tag} = $xc->findvalue(".", $_);
            }
        }

        for my $tag (qw(echoedSearchRetrieveRequest extraResponseData)) {
            for ($xc->findnodes("./srw:$tag", $_)) {
                $meta->{$tag} = {};
                for ($xc->findnodes('./*', $_)) {
                    if (defined $_->prefix) {
                        $xc->registerNs($_->prefix, $_->namespaceURI());
                    }
                    my $ns_uri     = $_->namespaceURI;
                    my $subTagName = is_string($ns_uri)
                        && $ns_uri eq $NS_SRW ? $_->localname : $_->tagName;
                    $meta->{$tag}->{$subTagName} = $xc->findvalue(".", $_);
                }
            }
        }
    }

    if ($xc->exists('/srw:searchRetrieveResponse/srw:records')) {
        $records->{record} = [];

        for (
            $xc->findnodes(
                '/srw:searchRetrieveResponse/srw:records/srw:record')
            )
        {
            my $recordSchema  = $xc->findvalue('./srw:recordSchema',  $_);
            my $recordPacking = $xc->findvalue('./srw:recordPacking', $_);
            my $recordData     = $xc->find('./srw:recordData/*', $_)->pop();
            my $recordPosition = $xc->findvalue('./srw:recordPosition', $_);

            # Copy all the root level namespaces to the record Element.
            for (@namespaces) {
                my $ns_prefix = $_->declaredPrefix;
                my $ns_uri    = $_->declaredURI;

                # Skip the SRW namespaces
                unless ($ns_uri =~ m{$NS_SRW}) {
                    $recordData->setNamespace($ns_uri, $ns_prefix, 0);
                }
            }

            push @{$records->{record}},
                {
                recordSchema   => $recordSchema,
                recordPacking  => $recordPacking,
                recordData     => $recordData,
                recordPosition => $recordPosition
                };
        }
    }

    return {records => $records, meta => $meta};
}

sub url {
    my ($self) = @_;

    my $limit = $self->limit;
    my $start = $self->_start;
    my $total = $self->total;
    if (is_natural($total) && ($start - 1 + $limit) > $total) {
        $limit = $total - ($start - 1);
    }

    # construct the url
    my $url = $self->base;
    $url .= '?version=' . uri_escape($self->version);
    $url .= '&operation=' . uri_escape($self->operation);
    $url .= '&query=' . uri_escape_utf8($self->query);
    $url .= '&recordSchema=' . uri_escape($self->recordSchema);
    $url .= '&sortKeys=' . uri_escape_utf8($self->sortKeys)
        if $self->sortKeys;
    $url .= '&startRecord=' . uri_escape($start);
    $url .= '&maximumRecords=' . uri_escape($limit);

    return $url;
}

# Internal: gets the next set of results.
#
# Returns a array representation of the resultset.
sub _nextRecordSet {
    my ($self, $quiet) = @_;

    # fetch the xml response and hashify it.
    my $res  = $self->_request($self->url);
    my $xml  = $res->{content};
    my $hash = $self->_hashify($xml);

    $self->_emit_diagnostics($hash) unless $quiet;

    # get to the point.
    my $meta = $hash->{'meta'};
    my $set  = $hash->{'records'}->{'record'};

    # return records and metareference to a array.
    {record => \@{$set}, meta => $meta};
}

# Internal: gets the next record from our current resultset.
#
# Returns a hash representation of the next record.
sub _nextRecord {
    my ($self) = @_;

    # fetch recordset if we don't have one yet.
    $self->{_currentRecordSet} = $self->_nextRecordSet
        unless $self->_currentRecordSet;

    # check for a exhaused recordset.
    if ($self->_n >= $self->limit) {
        $self->{_start} += $self->limit;
        $self->{_n}                = 0;
        $self->{_currentRecordSet} = $self->_nextRecordSet;
    }

    # return the next record or metadata.
    my $record = $self->{_currentRecordSet}->{record}->[$self->{_n}++];

    if (defined $record) {
        if (is_code_ref($self->parser)) {
            $record = $self->parser->($record);
        }
        else {
            $record = $self->parser->parse($record);
        }
    }

    $record;
}

# Internal: emit warnings for diagnostics
sub _emit_diagnostics {
    my ($self, $hash) = @_;

    for my $diag (@{$hash->{meta}{diagnostics} // []}) {
        warn join ' : ',
            grep {defined} map {$diag->{$_}} qw(uri message details);
    }
}

# Public Methods. --------------------------------------------------------------

sub generator {
    my ($self) = @_;

    if (ref $self->parser eq 'Catmandu::Importer::SRU::Parser::meta') {
        my $done;
        return sub {
            return if $done;
            $done = 1;
            $self->{_currentRecordSet} = $self->_nextRecordSet(1);
            $self->{_currentRecordSet}->{meta};
        };
    }

    return sub {
        $self->_nextRecord;
    };
}

sub count {
    my ($self) = @_;

    my $url
        = $self->base
        . '?version='
        . uri_escape($self->version)
        . '&operation='
        . uri_escape($self->operation)
        . '&query='
        . uri_escape_utf8($self->query)
        . '&recordSchema='
        . uri_escape($self->recordSchema)
        . '&maximumRecords=0';

    # fetch the xml response and hashify it.
    my $xml  = $self->_request($url)->{content};
    my $hash = $self->_hashify($xml);

    $self->_emit_diagnostics($hash);

    int($hash->{meta}->{numberOfRecords});
}

1;
__END__

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

=head1 DESCRIPTION

This L<Catmandu::Importer> imports records via SRU.

SRU diagnostics are emitted as warnings except for parser set to C<meta>.

=head1 CONFIGURATION

=over

=item base

Base URL of the SRU server (required)

=item query

CQL query (required)

=item limit

Number of records to fetch in one batch, set to C<10> by default.
This is translated to SRU request parameter C<maximumRecords>.

Records are fetched in multiple batches of this size or less.

=item total

Total number of records this importer may return.

Not set by default

=item recordSchema

Set to C<dc> by default

=item sortkeys

Optional sorting

=item operation

Set to C<searchRetrieve> by default

=item version

Set to C<1.1> by default

=item userAgent

HTTP user agent, set to C<Mozilla/5.0> by default.

=item http_client

Instance of L<HTTP::Tiny> or compatible class to fetch URLs with.

=item parser

Controls how records are parsed before importing. The following options
are possible:

=over 2

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
