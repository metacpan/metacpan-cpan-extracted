use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::RDF;

sub check_add(@) { ## no critic
    my $options = shift;
    my $data    = shift;
    my $result  = shift;

    my $file = "";
    my $exporter = Catmandu::Exporter::RDF->new(file => \$file, %$options);

    $exporter->add($data);
    $exporter->commit;

    if (ref $result) {
        $result->($file);
    } else {
        is $file, $result, $_[0];
    }
}


check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://example.org/',
    dc_title => 'Subject',
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/title> \"Subject\" .\n",
    'expand predicate URI';

check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://example.org/',
    dc_title => 'Subject@',
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/title> \"Subject\" .\n",
    'literal object';

check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://example.org/',
    dct_extent => '42^xsd_integer',
} => "<http://example.org/> <http://purl.org/dc/terms/extent> 42 .\n",
    'literal object with datatype';

check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://example.org/',
    'http://example.org/predicate' => { '_id' => 'http://example.com/object' },
} => "<http://example.org/> <http://example.org/predicate> <http://example.com/object> .\n",
    'uri object';

check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://example.org/',
    a => 'foaf_Organization',
} => "<http://example.org/> a <http://xmlns.com/foaf/0.1/Organization> .\n",
    '"a" for rdf:type';

=todo
check_add { type => 'ttl', ns => '20130816' }, {
    '_id' => 'http://example.org/',
    'http://example.org/predicate' => { },
} => "<http://example.org/> <http://example.org/predicate> _:b1 .\n",
    'blank node object';
=cut

check_add { type => 'ttl', ns => '20130816' }, {
    _id => 'http://www.gbv.de/',
    geo_location => {
        geo_lat => '9.93492',
        geo_long => '51.5393710',
    } 
} => sub {
    my $ttl = shift;
    ok $ttl =~ qr{_:[a-zA-Z0-9]+ <http://www.w3.org/2003/01/geo/wgs84_pos\#lat> "9.93492"} 
    && $ttl =~ qr{<http://www.w3.org/2003/01/geo/wgs84_pos\#long> "51.5393710"}
    && $ttl =~ qr{<http://www.gbv.de/> <http://www.w3.org/2003/01/geo/wgs84_pos\#location> _:[a-zA-Z0-9]+},
        'nested RDF';
};


## fixes

check_add { type => 'ttl', ns => '20130816', 
    fix => ["move_field('_id','\_id')","prepend('\_id','http://example.org/');"]
}, {
    _id => 123,
    dc_title => 'Foo',
} => "<http://example.org/123> <http://purl.org/dc/elements/1.1/title> \"Foo\" .\n",
    'fix subject URI';

check_add { type => 'ttl', ns => '20130816', 
    fix => [
        "append('dc:extent','^xsd:integer');"
    ]
}, {
    _id => 'http://example.org/',
    dc_extent => 42,
} => "<http://example.org/> <http://purl.org/dc/elements/1.1/extent> \"42\" .\n",
    'fix predicate';

done_testing;
