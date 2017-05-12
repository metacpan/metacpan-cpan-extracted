#!perl

use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Util qw(:io);
use XML::LibXML::XPathContext;

BEGIN {
    use_ok 'Catmandu::XSD';
}

require_ok 'Catmandu::XSD';

binmode(STDOUT, ":utf8");

{
    my $xsd = Catmandu::XSD->new(
            root => "{}shiporder" ,
            schemas => "t/demo/order/*.xsd" ,
    );

    ok $xsd , 'got an xsd for shiporders';

    my $xml = read_file("t/demo/order/id_0.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed order/id_0.xml';

    is $perl->{orderperson} , 'John Smith'  , 'shiporder.orderperson';
    is $perl->{item}->[0]->{price} , '10.90' , 'shipoder.item[0].price';

    my $out = $xsd->to_xml($perl);

    ok $out , 'to_xml(shiporder)';

    like $out , qr/.*<shiporder orderid="889923">.*/ , 'looks like xml';
}

{
    my $xsd = Catmandu::XSD->new(
            root => "{urn:isbn:1-931666-22-9}ead",
            schemas => "t/demo/ead/*.xsd" ,
    );

    ok $xsd , 'got an xsd for ead';

    my $xml = read_file("t/demo/ead/test.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed ead/test.xml';

    is $perl->{eadheader}
            ->{filedesc}
            ->{titlestmt}
            ->{titleproper}
            ->[0]
            ->{encodinganalog} , "Title" , 'ead.eadheader.filedesc.titlestmt.titleproper[0][@encodinganalog]';

    is $perl->{eadheader}
            ->{filedesc}
            ->{titlestmt}
            ->{titleproper}
            ->[0]
            ->{_}
            ->textContent, 'Prudence Wayland-Smith Papers' , 'ead.eadheader.filedesc.titlestmt.titleproper[0]';

    is $perl->{archdesc}
            ->{did}
            ->{head}
            ->{_}
            ->textContent , 'Overview of the Collection' , 'ead.did[0].head';
}

{
    my $xsd = Catmandu::XSD->new(
            root    => "{urn:isbn:1-931666-22-9}ead",
            schemas => "t/demo/ead/*.xsd" ,
            mixed   => 'TEXTUAL'
    );

    ok $xsd , 'got an xsd for ead TEXTUAL mode';

    my $xml = read_file("t/demo/ead/test.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed ead/test.xml';

    is $perl->{eadheader}
            ->{filedesc}
            ->{titlestmt}
            ->{titleproper}
            ->[0]
            ->{encodinganalog} , "Title" , 'ead.eadheader.filedesc.titlestmt.titleproper[0][@encodinganalog]';

    is $perl->{eadheader}
            ->{filedesc}
            ->{titlestmt}
            ->{titleproper}
            ->[0]
            ->{_} , 'Prudence Wayland-Smith Papers' , 'ead.eadheader.filedesc.titlestmt.titleproper[0]';

    is $perl->{archdesc}
            ->{did}
            ->{head}
            ->{_} , 'Overview of the Collection' , 'ead.did[0].head';
}

{
    my $xsd = Catmandu::XSD->new(
            root => "{http://www.loc.gov/mods/v3}mods",
            schemas => [
                "t/demo/mods/mods-3-3.xsd" ,
                "t/demo/mods/xlink.xsd" ,
                "t/demo/mods/xml.xsd" ,
            ]
    );

    ok $xsd , 'got an xsd for mods';

    my $xml = read_file("t/demo/mods/test.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed mods/test.xml';

    my $mods = $perl->{gr_modsGroup};

    is [choose($mods,'name')]
            ->[0]
            ->{ID} , 'ug_802001229613' , 'mods.name[0][@ID]';

    is choose($mods,'language')
            ->{languageTerm}
            ->[0]
            ->{authority} , 'iso639-2b' , 'mods.language.languageTerm[0][@authority]';

    is choose($mods,'language')
            ->{languageTerm}
            ->[0]
            ->{_} , 'eng' , 'mods.language.languageTerm[0][@authority].text()';

    like choose($mods,'abstract')
            ->{_} , qr/^Wastewater treatment plants/ , 'mods.abstract';
}

{
    my $xsd = Catmandu::XSD->new(
            root    => "{http://www.loc.gov/mods/v3}mods",
            schemas => [
                "t/demo/mods/mods-3-6.xsd" ,
                "t/demo/mods/xlink.xsd" ,
                "t/demo/mods/xml.xsd" ,
            ]
    );

    ok $xsd , 'got an xsd for mods';

    my $xml = read_file("t/demo/mods/test2.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed mods/test.xml';

    my $mods = $perl->{gr_modsGroup};

    my $holding_external = [ choose($mods,'location') ]->[0]->{holdingExternal}->{_};

    my $xc = XML::LibXML::XPathContext->new($holding_external);

    ok $xc , 'created a xpath context for holdings';

    $xc->registerNs('dcterms','http://purl.org/dc/elements/1.1/');

    is $xc->findvalue('//dcterms:accessRights') , 'restricted' , 'dcterms:accessRights';
}

{
    my $xsd = Catmandu::XSD->new(
            root    => "{http://www.loc.gov/METS/}mets",
            schemas => [
                "t/demo/mets/mets.xsd" ,
                "t/demo/mets/xlink.xsd" ,
            ] ,
            prefixes => [
                { 'http://www.loc.gov/mods/v3' => 'mods' }
            ]
    );

    ok $xsd , 'got an xsd for mets';

    my $xml = read_file("t/demo/mets/mets.xml");

    my $perl = $xsd->parse($xml);

    ok $perl , 'parsed mets/mets.xml';

    my $mods = $perl->{dmdSec}->[0]->{mdWrap}->{xmlData}->{'{http://www.loc.gov/mods/v3}mods'}->[0];

    my $xc = XML::LibXML::XPathContext->new($mods);

    ok $xc , 'created a xpath context for holdings';

    $xc->registerNs('mods','http://www.loc.gov/mods/v3');

    is $xc->findvalue('mods:titleInfo/mods:title') , 'Alabama blues' , 'mods:title';

    my $out  = $xsd->to_xml($perl);

    ok $out , 'got xml';

    like $out , qr/<mods:mods xmlns:mods/ , 'well..looks like XML'
}

done_testing 34;

sub choose {
    my ($arr,$name) = @_;

    my @ret = ();
    for (@$arr) {
        my ($key) = keys %$_;
        push @ret , $_->{$key} if $key eq $name;
    }

    wantarray ? @ret : pop @ret;
}
