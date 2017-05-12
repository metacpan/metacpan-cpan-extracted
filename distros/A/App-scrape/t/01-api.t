#!perl -T
use strict;

use Test::More tests => 2;
use App::scrape 'scrape';
use Data::Dumper;

my $html = join '', <DATA>;
my @posts = scrape(
    $html,
    ['a'],
    { 
        absolute => [qw[href src rel]],
        base => 'http://example.com',
    },
);

is_deeply \@posts, [
         [
           'Some link'
         ],
         [
           'A name'
         ],
         [
           'A named link'
         ],
         [
           'An absolute link'
         ]
], "Links get extracted correctly"
    or diag Dumper \@posts;

@posts = scrape(
    $html,
    ['a@href'],
    { 
        absolute => [qw[href src rel]],
        base => 'http://example.com',
    },
);

is_deeply \@posts, [
    [
      'http://example.com/foo'
    ],
    [
      'http://example.com/baz'
    ],
    [
      'http://google.com'
    ]
], "Links get extracted correctly"
    or diag Dumper \@posts;

__DATA__
<html>
<body>
<a href="foo">Some link</a>
<a name="bar">A name</a>
<a name="baz" href="baz">A named link</a>
<a href="http://google.com">An absolute link</a>
</body>
</html>