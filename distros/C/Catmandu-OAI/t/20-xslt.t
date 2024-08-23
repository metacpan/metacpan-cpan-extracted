use strict;
use warnings;
use version;
use Catmandu::Importer::OAI;
use Test::More;

my $dom = XML::LibXML->load_xml( location => 't/epicur.xml' );

sub oai_xslt {
    Catmandu::Importer::OAI->new( 
        url => 'http://example.org/', xslt => 't/transform.xsl', @_
    )->handle_record($dom)
}

is_deeply oai_xslt( handler => 'raw' ), {
    _metadata => "<?xml version=\"1.0\"?>\n<urn_new url=\"https://journals.ub.uni-heidelberg.de/index.php/ip/article/view/16490/12358\">urn:nbn:de:bsz:16-ip-164907</urn_new>\n"
};

is_deeply oai_xslt( handler => 'struct' ), {
   '_metadata' => [
     'urn_new', 
     { url => 'https://journals.ub.uni-heidelberg.de/index.php/ip/article/view/16490/12358' },
     [ 'urn:nbn:de:bsz:16-ip-164907' ]
   ]
};

is_deeply oai_xslt(), { urn_new => [ 'urn:nbn:de:bsz:16-ip-164907' ] };

done_testing;
