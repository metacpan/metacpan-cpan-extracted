#!perl

use strict;
use warnings;
use Test::More;

use Catmandu;
use Catmandu::Util qw(:io);
use XML::LibXML::XPathContext;

BEGIN {
    use_ok 'Catmandu::Importer::XSD';
}

require_ok 'Catmandu::Importer::XSD';

{
    my $importer = Catmandu->importer('XSD' ,
            files   => 't/demo/order/id*.xml' ,
            root    => '{}shiporder' ,
            schemas => 't/demo/order/*.xsd' ,
    );

    ok $importer , 'got an importer';

    my $order = $importer->to_array;

    is @$order , 2 , 'got two orders';

    is $order->[0]->{orderperson} , 'John Smith'  , 'John Smith';
    is $order->[1]->{orderperson} , 'Olga Brown'  , 'Olga Brown';
}

{
    my $importer = Catmandu->importer('XSD' ,
            file    => 't/demo/order/list.xml' ,
            xpath   => '/Container/List//Record/Payload/*' ,
            root    => '{}shiporder' ,
            schemas => 't/demo/order/*.xsd' ,
    );

    ok $importer , 'got an importer';

    my $order = $importer->to_array;

    is @$order , 2 , 'got two orders';

    is $order->[0]->{orderperson} , 'John Smith'  , 'John Smith';
    is $order->[1]->{orderperson} , 'Olga Brown'  , 'Olga Brown';
}

done_testing 10;
