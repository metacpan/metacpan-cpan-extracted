package Catmandu::OCLC::VIAFAuthorityCluster;

use REST::Client;
use URI::Escape;
use Catmandu;

our $MARC_HEADER = qq|<marc:collection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd" xmlns:marc="http://www.loc.gov/MARC21/slim">|;
our $MARC_FOOTER = qq|</marc:collection>|;

sub read {
	my $identifier = shift;
    my $client     = REST::Client->new(host => 'http://www.viaf.org');
    my $path       = sprintf "/viaf/%s/marc21.xml", $identifier;
	my $res        = $client->GET($path);
	
	return undef unless $res->responseCode eq '200';

	my $content    = $MARC_HEADER . $res->responseContent . $MARC_FOOTER;
	$content =~ s{mx:}{marc:}g;

	my $fh;
	open($fh, '<', \$content);

	my $importer   = Catmandu->importer(MARC, type=>'XML' , fh => $fh);

	my $record     = $importer->first;

	close($fh);

	delete $record->{_id};

	return $record;
}

1;