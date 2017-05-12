package ActiveResource::Formats::XmlFormat;
use common::sense;
use XML::Hash;

sub extension { "xml" }

sub mime_type { "application/xml" }

sub decode {
    my $self = shift;
    my $xml = shift;

    $xml =~ s{^<\?xml version="1\.0" encoding="UTF-8"\?>\n}{}s;
    unless ($xml =~ m{<.+?>}s) {
        return {};
    }

    my $c = XML::Hash->new;
    my $hash = $c->fromXMLStringtoHash($xml);

    return $hash;
}

sub encode {
    my $self = shift;
    my $hash = shift;

    my $c = XML::Hash->new;
    my $xml = $c->fromHashtoXMLString($hash);
    return '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . $xml;
}


1;
