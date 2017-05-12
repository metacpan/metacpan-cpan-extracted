use strictures;
use Test::More import => [qw(done_testing is_deeply)];
use Data::HAL qw();

my $hal = Data::HAL->new(
    links => [
        Data::HAL::Link->new(relation => 'self', href => 'http://example.com/a-resource'),
        Data::HAL::Link->new(relation => 'profile', href => 'http://example.com/docs'),
        Data::HAL::Link->new(relation => 'curies', name => 'example', href => 'http://example.com/rel#{rel}', templated => 1),
        Data::HAL::Link->new(relation => 'example:foo', href => '/a-foo-thing'),
        Data::HAL::Link->new(relation => 'example:bar', href => '/some-bar'),
    ],
);

is_deeply [$hal->http_headers], [
    'Content-Type' => 'application/hal+json; profile="http://example.com/docs"',
    'Link' => '<http://example.com/a-resource>; rel=self',
    'Link' => '<http://example.com/docs>; rel=profile',
    'Link' => '</a-foo-thing>; rel="http://example.com/rel#foo"',
    'Link' => '</some-bar>; rel="http://example.com/rel#bar"',
];

done_testing;
