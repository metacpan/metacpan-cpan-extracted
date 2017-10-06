use Test::More;

BEGIN {
    eval {
        require URI;
        URI->new();
        1;
    } or do {
        plan skip_all => "URI is not available";
    };
}

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/URI/;
	use MooX::LazierAttributes;

	attributes (
		[qw/url schema_url autoescape_url queryForm/] => [URI, { coe }],
		'schema' => [URI->by('schema'), {coe}],
		'host' => [URI->by('host'), {coe}],
		'path' => [URI->by('path'), {coe}],
		'queryString', [URI->by('query_string'), {coe}],
		'queryForms', [URI->by('query_form'), {coe}],
		'frag', [URI->by('fragment'), {coe}],
		'query' => [URI->by('params'), {coe}],
		'escape' => [URI->by('escape'), {coe}],
		'unescape' => [URI->by('unescape'), {coe}],
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	url => q|example.lnation.com|, 
	schema_url => [q|example.lnation.com|, q|https|],
	autoescape_url => q|https://example.lnation.com?one= a b c&two=1!2£3|,
	queryForm => [q|https://example.lnation.com|, { a => 'b' }],
	schema => q|https://example.lnation.com/okays?one=two#yep|,
	host => q|https://example.lnation.com/okays?one=two#yep|,
	path => q|https://example.lnation.com/okays?one=two#yep|,
	frag => q|https://example.lnation.com/okays?one=two#yep|,
	queryString => q|https://example.lnation.com/okays?one=two#yep|,
	queryForms => q|https://example.lnation.com/okays?one=two#yep|,
	escape => q|!$^@$%|,
	unescape => q|%21%24%5E%40%24%25|,
);

is($thing->url->as_string, 'example.lnation.com');
# whys
is(sprintf('https://%s', $thing->schema_url->as_string), 'https://example.lnation.com');
is($thing->autoescape_url->as_string, 'https://example.lnation.com?one=%20a%20b%20c&two=1!2%C2%A33');
is($thing->queryForm->as_string, 'https://example.lnation.com?a=b');

is($thing->schema, 'https');
is($thing->host, 'example.lnation.com');
is($thing->path, '/okays');
is($thing->queryString, '?one=two');
is($thing->frag, '#yep');
is_deeply($thing->queryForms, { one => 'two' });
is($thing->escape, '%21%24%5E%40%24%25');
is($thing->unescape, '!$^@$%');
done_testing();
