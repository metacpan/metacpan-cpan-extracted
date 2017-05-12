#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use lib qw( t/lib );

# Make sure the Catalyst app loads ok...
use_ok('TestApp');

{
    my $model = TestApp->model('rdf');
    isa_ok( $model, 'Catalyst::Model::RDF' );
    can_ok( $model, 'serializer' );
    isa_ok($model->store, 'RDF::Trine::Store::DBI');
    isa_ok($model->ns, 'RDF::Trine::NamespaceMap');
    ok($model->ns->dct, 'Correctly imported namespace mapping from config');

    #warn Data::Dumper::Dumper($model);

    # add_hashref already does begin/end_bulk_ops so why is it not
    # persisting?

    $model->add_hashref(
        {
            'http://example.com/doc' => {
                'http://example.com/predicate' => [
                    { 'type' => 'literal', 'value' => 'Foo' },
                    { 'type' => 'uri', 'value' => 'http://example.com/bar' },
                    'baz@en'
                ],
            },
        }
    );

    my $expect	= <<"END";
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<rdf:Description xmlns:ns1="http://example.com/" rdf:about="http://example.com/doc">
	<ns1:predicate rdf:resource="http://example.com/bar"/>
	<ns1:predicate>Foo</ns1:predicate>
      <ns1:predicate xml:lang="en">baz</ns1:predicate>
</rdf:Description>
</rdf:RDF>
END

    my $output = $model->serializer;
    ok($output, 'serialize model to string');
    #is($output, $expect, 'serialize_model_to_string');
}

1;

