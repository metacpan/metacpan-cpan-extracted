use strict;
use Test::More;
use lib 't';
use MockFurl;
use Catmandu::Importer::getJSON;

sub test_importer(@) { ##no critic
    my ($url, $requests, $content, $expect, $msg) = @_;

    my $importer = Catmandu::Importer::getJSON->new(
        file => \ do { join "\n", map { $_->[0] } @$requests },
        client => MockFurl::new( content => $content ),
    );
    $importer->url($url) if defined $url;

    $expect = [ map { $expect } @$requests ] if ref $expect ne 'ARRAY';
    is_deeply $importer->to_array, $expect, $msg;
    is_deeply $importer->client->urls, [ map { $_->[1] } @$requests ];
}

my @requests = (
    [ '{ } ' => 'http://example.org/' ],
    [ '{"q":"&"}' => 'http://example.org/?q=%26' ],
    [ '/path?q=%20 ' => 'http://example.org/path?q=%20' ],
);

test_importer 'http://example.org/', \@requests,
    '{"x":"\u2603"}' => {x=>"\x{2603}"},
    'URI';

test_importer
    'http://example.{tdl}/{?foo}{?bar}',
    [
        [ 'http://example.org' => 'http://example.org' ],
        [ '{"tdl":"com"}' => 'http://example.com/' ],
        [ '{"tdl":"com","bar":"doz"}' => 'http://example.com/?bar=doz' ],
    ],
    '{}' => { },
    'URI::Template';

is_deeply(Catmandu::Importer::getJSON->new(
    client => MockFurl::new( content => '{"hello":"World"}' ),
    from   =>  'http://example.org',
)->to_array, [{hello=>"World"}], '--from');

is_deeply(Catmandu::Importer::getJSON->new(
    dry => 1, url => 'http://example.{tdl}/',
    file => \'{"tdl":"org"}'
)->to_array, [{url=>"http://example.org/"}],'--dry');

test_importer undef,
    [ ["http://example.info" => "http://example.info" ] ],
    '[{"n":1},{"n":2}]' => [{"n"=>1},{"n"=>2}],
    'JSON array response';

my $importer = Catmandu::Importer::getJSON->new(
    client => MockFurl::new( content => '[{"n":1},{"n":2}]' ),
    from   => 'http://example.org',
);
is_deeply $importer->first, {n => 1}, 'array response 1/2';
is_deeply $importer->rest->first, { n => 2}, 'array response 2/2';

{
    my $warning; local $SIG{__WARN__} = sub { $warning = shift };
    is_deeply(Catmandu::Importer::getJSON->new(
        file => \"x\n\nhttp://example.org/",
        dry => 1,
        warn => 1,
    )->to_array, [{ url => "http://example.org/" }]);
    is $warning, "failed to construct URL: x\n", "warning";
}

done_testing;
