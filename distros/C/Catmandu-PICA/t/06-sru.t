use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    eval {
        require Catmandu::SRU;
        require Catmandu::Importer::SRU;
        $Catmandu::SRU::VERSION >= 0.427;
    } or do {
        plan skip_all => "Catmandu::SRU >= 0.427 required";
    };
}

use Catmandu::Importer::SRU::Parser::picaxml;
use Catmandu::Importer::SRU::Parser::ppxml;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockHTTPClient;

note "Catmandu::Importer::SRU::Parser::picaxml";
{
    my %attrs = (
        base         => 'http://www.unicat.be/sru',
        query        => 'sru_picaxml.xml',
        recordSchema => 'picaxml',
        http_client  => MockHTTPClient->new,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);

    isa_ok( $importer, 'Catmandu::Importer::SRU' );
    can_ok( $importer, 'each' );
    can_ok( $importer, 'to_array' );
    can_ok( $importer, 'first' );
    is( $importer->url,
        'http://www.unicat.be/sru?version=1.1&operation=searchRetrieve&query=sru_picaxml.xml&recordSchema=picaxml&startRecord=1&maximumRecords=10',
        'query url'
    );

    my $marcparser = Catmandu::Importer::SRU::Parser::picaxml->new;
    my @parsers    = (
        'picaxml', '+Catmandu::Importer::SRU::Parser::picaxml',
        $marcparser, sub { $marcparser->parse( $_[0] ); }
    );

    foreach my $parser (@parsers) {
        my $importer
            = Catmandu::Importer::SRU->new( %attrs, parser => $parser );
        ok( my $obj = $importer->first, 'parse pica' );
        ok( exists $obj->{_id},    'pica has _id' );
        ok( exists $obj->{record}, 'pica has record' );
    }
}

note "Catmandu::Importer::SRU::Parser::ppxml";
{
    my %attrs = (
        base         => 'http://www.unicat.be/sru',
        query        => 'sru_ppxml.xml',
        recordSchema => 'PicaPlus-xml',
        http_client  => MockHTTPClient->new,
    );

    my $importer = Catmandu::Importer::SRU->new(%attrs);

    isa_ok( $importer, 'Catmandu::Importer::SRU' );
    can_ok( $importer, 'each' );
    is( $importer->url,
        'http://www.unicat.be/sru?version=1.1&operation=searchRetrieve&query=sru_ppxml.xml&recordSchema=PicaPlus-xml&startRecord=1&maximumRecords=10'
    );

    my $parser  = Catmandu::Importer::SRU::Parser::ppxml->new;
    my @parsers = (
        'ppxml', '+Catmandu::Importer::SRU::Parser::ppxml',
        $parser, sub { $parser->parse( $_[0] ); }
    );

    foreach my $parser (@parsers) {
        my $importer
            = Catmandu::Importer::SRU->new( %attrs, parser => $parser );
        ok( my $obj = $importer->first, 'parse pica' );
        ok( exists $obj->{_id},    'pica has _id' );
        ok( exists $obj->{record}, 'pica has record' );
    }
}

done_testing;
