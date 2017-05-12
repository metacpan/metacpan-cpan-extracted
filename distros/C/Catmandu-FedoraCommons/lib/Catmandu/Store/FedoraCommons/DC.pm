package Catmandu::Store::FedoraCommons::DC;

use Moo;
use XML::LibXML;
use Data::Validate::Type qw(:boolean_tests);

has fedora => (is => 'ro' , required => 1);

# REQUIRED METHODS FOR A MODEL

sub get {
    my ($self,$pid) = @_;
    
    return undef unless $pid;
    
    my $res   = $self->fedora->getDatastreamDissemination( pid => $pid , dsID => 'DC');
    
    return undef unless $res->is_ok;
    
    my $data  = $res->parse_content;
    my $perl  = $self->deserialize($data);
    
    { _id => $pid , %$perl };
}

sub update {
    my ($self,$obj) = @_;
    my $pid = $obj->{_id};

    return undef unless $pid;
    
    my ($valid,$reason) = $self->valid($obj);
    
    unless ($valid) {
        warn "data is not valid";
        return undef;
    }
    
    my $xml    = $self->serialize($obj);
    my $result = $self->fedora->modifyDatastream( pid => $pid , dsID => 'DC', xml => $xml);

    return $result->is_ok;
}

# HELPER METHODS

# Die fast data validator
sub valid {
    my ($self,$perl) = @_;
    
    unless (is_hashref($perl)) {
        return wantarray ? (0, "not a HASH ref") : undef ;
    }
    
    unless (Data::Validate::Type::filter_hashref($perl, allow_empty => 0)) {
        return wantarray ? (0, "empty HASH ref") : undef;
    }
    
    my $found = undef;
    
    for my $key (keys %$perl) {
        my $value = $perl->{$key};
        
        next if $key eq '_id';
        
        unless ($key =~ m{^(contributor|coverage|creator|date|description|format|identifier|language|publisher|relation|rights|source|subject|title|type)$}) {
            return wantarray ? (0, "unknown field $key") : undef;
        }
    
        unless (is_arrayref($value)) {
            return wantarray ? (0, "field $key isn't an ARRAY") : undef;
        }
        
        for my $value_str (@$value) {
            unless (is_string($value_str)) {
                return wantarray ? (0, "field $key value isn't a string") : undef;
            }
        }
        
        $found = 1;
    }
    
    unless (defined $found) {
        return wantarray ? (0, "need at least one field") : undef;
    }
    
    return wantarray ? (1,"ok") : 1;
}

sub serialize {
    my ($self,$perl) = @_;
    my $dom  = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $dc = $dom->createElementNS('http://www.openarchives.org/OAI/2.0/oai_dc/','oai_dc:dc');
    $dom->setDocumentElement($dc);
    
    for my $dc_elem (qw(contributor coverage creator date description format identifier language publisher relation rights source subject title type)) {
        
        next unless (exists $perl->{$dc_elem} && ref $perl->{$dc_elem} eq 'ARRAY');
        
        for my $dc_value (@{$perl->{$dc_elem}}) {
            my $node = $dom->createElementNS('http://purl.org/dc/elements/1.1/',"dc:$dc_elem");
            $node->appendTextNode($dc_value);
            $dc->appendChild($node);
        }
    }
    
    my $xml = $dom->toString(2);
    
    $xml =~ s{<\?[^>]+\?>}{};
        
    return $xml;
}

sub deserialize {
    my ($self,$xml) = @_;
    my $dom  = XML::LibXML->load_xml(string => $xml);
    my $xc = XML::LibXML::XPathContext->new( $dom );
    $xc->registerNs('oai_dc','http://www.openarchives.org/OAI/2.0/oai_dc/');
    $xc->registerNs('dc','http://purl.org/dc/elements/1.1/');
    
    my $result = {};
    my @nodes  = $xc->findnodes("//oai_dc:dc/*");
        
    for my $node (@nodes) {
        my $name  = $node->nodeName;
        my $value = $node->textContent;
        
        $name =~ s/\w+://;
        
        push @{ $result->{$name} } , $value;
    }
    
    return $result;
}

1;