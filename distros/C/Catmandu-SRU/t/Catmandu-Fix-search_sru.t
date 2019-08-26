use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::HTTP::LocalServer;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::search_sru';
    use_ok $pkg;
}

require_ok $pkg;

{
    my $server
        = Test::HTTP::LocalServer->spawn(file => 't/files/sru_oai_dc.xml');
    my $search = $pkg->new('key', $server->url)->fix({key => 'value'});
    ok defined $search->{key}, 'default parser';
    is scalar @{$search->{key}}, 2, 'got records';
    $search = $pkg->new('nested.key', $server->url)
        ->fix({nested => {key => 'value'}});
    is scalar @{$search->{nested}->{key}}, 2, 'nested path';
    $search = $pkg->new('key.*', $server->url)->fix({key => ['foo', 'bar']});
    ok defined $search->{key}->[0]->[0], 'array path';
    $server->stop;

}

{
    my $server = Test::HTTP::LocalServer->spawn(file => 't/files/21.xml');
    my $search = $pkg->new('key', $server->url, parser => 'marcxml')
        ->fix({key => 'value'});
    ok defined $search->{key}, 'marcxml parser';
    $search = $pkg->new(
        'key', $server->url,
        parser => 'marcxml',
        fixes  => 'remove_field(record);'
    )->fix({key => 'value'});
    is_deeply $search->{key},
        [{_id => '011197684'}, {_id => '016305078'}, {_id => '01216822X'}],
        'got fixed records';
    $server->stop;

}

done_testing;
