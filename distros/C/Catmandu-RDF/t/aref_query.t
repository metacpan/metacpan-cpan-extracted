use strict;
use warnings;
use Test::More;
use Catmandu ':all';

use Catmandu::Fix;
use Catmandu::Fix::aref_query as => 'my_query';

{
    my $fixer = Catmandu::Fix->new( fixes => ['aref_query(dc_title,title)'] );
    my $rdf = importer('RDF', file => 't/example.ttl')->first;
    ($rdf->{_uri}) = keys %$rdf;

    $fixer->fix($rdf);
    delete $rdf->{ $rdf->{_uri} };

    is_deeply $rdf, {
        '_uri' => 'http://example.org',
        title => "B\x{c4}R",
    }, 'simple RDF fix';
}

my $rdf = importer('RDF', file => 't/example.ttl')->first;

sub fix {
    my $rdf = shift;
    my_query($rdf, @_);
    delete $rdf->{$_[-1]};
}

is fix($rdf,'http://example.org','dc_title','label'), "B\x{c4}R";
is fix($rdf,'dc_title','label'), undef;

$rdf->{_url} = 'http://example.org';
is fix($rdf,'dc_title','label'), "B\x{c4}R", 'respect _url field';
is fix($rdf,'http://example.com','dc_title','label'), undef;

done_testing;
