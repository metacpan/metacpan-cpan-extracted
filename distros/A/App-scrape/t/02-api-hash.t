#!perl -T
use strict;

use Test::More tests => 2;
use App::scrape 'scrape';
use Data::Dumper;

my $html = join '', <DATA>;
my @posts = scrape(
    $html,
    {},
    { 
        absolute => [qw[href src rel]],
        base => 'http://example.com',
    },
);

is_deeply \@posts, [], "Empty links get extracted correctly"
    or diag Dumper \@posts;

@posts = scrape(
    $html,
    { 
      title => 'a',
      url   => 'a@href',
    },
    { 
        absolute => [qw[href src rel]],
        base => 'http://example.com',
    },
);

# This is actually ugly, as there is no way in the API yet
# to group things relative to other nodes. See Web::Scraper for that
is_deeply \@posts, [
    {
      'url' => 'http://example.com/foo',
      'title' => 'Some link'
    },
    {
      'url' => 'http://example.com/baz',
      'title' => 'A name'
    },
    {
      'url' => 'http://google.com',
      'title' => 'A named link'
    },
    {
      'url' => undef,
      'title' => 'An absolute link'
    }
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