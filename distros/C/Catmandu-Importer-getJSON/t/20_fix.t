use strict;
use Test::More;

use Catmandu::Fix::get_json;
sub get_dry { Catmandu::Fix::get_json->new(@_, dry => 1) }

is_deeply get_dry("http://example.com/json")
    ->fix({}),
	{url => "http://example.com/json"}, 'plain URL';

is_deeply get_dry("http://example.com/json")
    ->fix({foo => "bar"}),
	{url => "http://example.com/json"}, 'plain URL, override';

is_deeply get_dry("http://example.com/json", path => "tmp.test")
    ->fix({foo => "bar"}),
	{foo => "bar", tmp => {test => {url => "http://example.com/json"}}},
    'plain URL, path';

is_deeply get_dry("http://example.com/{name}.json", vars => 'path')
    ->fix({path => { name => 'foo', foo => 'bar' }}),
    { url => "http://example.com/foo.json" },
    'URL template with variables';

is_deeply get_dry("http://example.com/{name}.json", vars => 'path')
    ->fix({path => "http://example.org/1" }),
    { }, 'URL template n/a variables';

is_deeply get_dry("http://example.com/", vars => 'path')
    ->fix({path => { name => 'foo' }}),
    { url => "http://example.com/?name=foo" },
    'URL with query variables';

is_deeply get_dry("http://example.com/some", vars => 'path')
    ->fix({path => "/path" }),
    { url => 'http://example.com/some/path' },
    'URL with path';

is_deeply get_dry("http://example.com/{name}.json", vars => 'path')
    ->fix({path => "/path" }),
    { url => 'http://example.com/%7Bname%7D.json/path' },
    'URL template with path';

is_deeply get_dry("my")
    ->fix({my => "http://example.org/" }),
    { my => { url => "http://example.org/" } },
    'URL from field';

is_deeply get_dry("my", vars => 'q', path => '')
    ->fix({ my => "http://example.org/", q => '/path' }),
    { url => "http://example.org/path" },
    'URL from field, with path';

is_deeply get_dry("my", vars => 'q', path => '')
    ->fix({ my => "http://example.org/", q => { some => 42 } }),
    { url => "http://example.org/?some=42" },
    'URL from field, with vars';

is_deeply get_dry("my", vars => 'q', path => '')
    ->fix({ my => "http://example.org/{some}", q => { some => 42 } }),
    { url => "http://example.org/42" },
    'URL template from field';

done_testing;
