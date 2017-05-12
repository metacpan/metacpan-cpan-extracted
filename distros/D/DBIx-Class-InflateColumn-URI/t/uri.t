#!perl -wT
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 32;
    };

    use_ok('URI');
};


my $schema = DBIC::Test->init_schema;


## Test Resources, which has no class level options set
{
    my $resources = $schema->resultset('Resources')->search;

    is($resources->count, 3);

    ## load em up and check codes/formats/values
    my $resource = $resources->next;
    isa_ok($resource, 'DBIC::TestSchema::Resources');
    isa_ok($resource->url, 'URI');
    is($resource->url->as_string, 'http://search.cpan.org/search?query=DBIx%3A%3AClass%3A%3AInflateColumn%3A%3AURI&mode=all', 'as_string');
    is($resource->url->scheme, 'http', 'scheme');
    is($resource->url->host, 'search.cpan.org', 'host');
    is($resource->url->path, '/search', 'path');

    $resource = $resources->next;
    isa_ok($resource, 'DBIC::TestSchema::Resources');
    isa_ok($resource->url, 'URI');
    is($resource->url->as_string, 'http://www.google.com/search?q=DBIx%3A%3AClass%3A%3AInflateColumn%3A%3AURI', 'as_string');
    is($resource->url->scheme, 'http', 'scheme');
    is($resource->url->host, 'www.google.com', 'host');
    is($resource->url->path, '/search', 'path');

    $resource = $resources->next;
    isa_ok($resource, 'DBIC::TestSchema::Resources');
    isa_ok($resource->url, 'URI');
    is($resource->url->as_string, 'ftp://ftp.us.debian.org/debian/pool/main/libd/libdbix-class-inflatecolumn-uri-perl/libdbix-class-inflatecolumn-uri-perl_0.01000-1_all.deb', 'as_string');
    is($resource->url->scheme, 'ftp', 'scheme');
    is($resource->url->host, 'ftp.us.debian.org', 'host');
    is($resource->url->path, '/debian/pool/main/libd/libdbix-class-inflatecolumn-uri-perl/libdbix-class-inflatecolumn-uri-perl_0.01000-1_all.deb', 'path');

    ## create with values
    my $row1 = $schema->resultset('Resources')->create({
        label => 'rt',
        url   => 'https://rt.cpan.org/Dist/Display.html?Queue=DBIx-Class-InflateColumn-URI',
    });

    isa_ok($row1, 'DBIC::TestSchema::Resources');
    isa_ok($row1->url, 'URI');
    is($row1->url->as_string, 'https://rt.cpan.org/Dist/Display.html?Queue=DBIx-Class-InflateColumn-URI', 'as_string');
    is($row1->url->scheme, 'https', 'scheme');
    is($row1->url->host, 'rt.cpan.org', 'host');
    is($row1->url->path, '/Dist/Display.html', 'path');

    ## create with objects/deflate
    my $row2 = $schema->resultset('Resources')->create({
        label => 'annocpan',
        url   => URI->new('http://www.annocpan.org/?mode=search&field=Module&name=DBIx%3A%3AClass%3A%3AInflateColumn%3A%3AURI'),
    });

    isa_ok($row2, 'DBIC::TestSchema::Resources');
    isa_ok($row2->url, 'URI');
    is($row2->url->as_string, 'http://www.annocpan.org/?mode=search&field=Module&name=DBIx%3A%3AClass%3A%3AInflateColumn%3A%3AURI', 'as_string');
    is($row2->url->scheme, 'http', 'scheme');
    is($row2->url->host, 'www.annocpan.org', 'host');
    is($row2->url->path, '/', 'path');

};

