package AuthenNZRealMeTestHelper;

use strict;
use warnings;

use Test::Builder;

require XML::LibXML;
require XML::LibXML::XPathContext;

use FindBin;
use File::Spec;

use Exporter qw(import);

our @EXPORT = qw(
    test_conf_dir
    test_data_file
    xml_found_node_ok
    xml_node_content_is
);

my @namespaces = (
    [ nssaml    => 'urn:oasis:names:tc:SAML:2.0:assertion' ],
    [ nssamlp   => 'urn:oasis:names:tc:SAML:2.0:protocol' ],
    [ nssoapenv => 'http://schemas.xmlsoap.org/soap/envelope/' ],
);

my $Test = Test::Builder->new();

sub test_conf_dir {
    return File::Spec->catdir($FindBin::Bin, 'test-conf');
}

sub test_data_file {
    return File::Spec->catdir($FindBin::Bin, 'test-data', shift);
}


sub xml_found_node_ok {
    my($xml, $xpath) = @_;

    my $desc = "found node at path: $xpath";
    my $ok   = 0;
    my $msg  = '';
    if(my $dom = _parse_saml_xml($xml)) {
        my @nodes = $dom->findnodes($xpath);
        if(@nodes == 1) {
            $ok = 1;
        }
        else {
            $msg = "expected 1 match, found: " . @nodes;
        }
    }
    $Test->ok($ok, $desc);
    $Test->diag($msg) if $msg;
}


sub xml_node_content_is {
    my($xml, $xpath, $expected) = @_;

    my $desc = "node at path $xpath contains '$expected'";
    my $ok   = 0;
    my $msg  = '';
    if(my $dom = _parse_saml_xml($xml)) {
        my @nodes = map { $_->to_literal } $dom->findnodes($xpath);
        if(@nodes == 1) {
            if($nodes[0] eq $expected) {
                $ok = 1;
            }
            else {
                $msg = "expected '$expected' got '$nodes[0]'";
            }
        }
        else {
            $msg = "expected 1 match, found: " . @nodes;
        }
    }
    $Test->ok($ok, $desc);
    $Test->diag($msg) if $msg;
}


sub _parse_saml_xml {
    my($xml) = @_;

    my $xc = eval {
        my $parser = XML::LibXML->new();
        my $doc    = $parser->parse_string( $xml );
        my $xc     = XML::LibXML::XPathContext->new( $doc->documentElement() );
    };
    if($@) {
        $Test->diag("Parse failed. Error: '$@'");
        $Test->diag("XML: '$xml'");
        return;
    }

    foreach my $ns (@namespaces) {
        $xc->registerNs(@$ns);
    }

    return $xc;
}

1;

