#!perl -T
use strict;

use Test::More tests => 2;
use App::scrape 'scrape';
use Data::Dumper;

my $html = join '', <DATA>;
my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;
(my $relevant) = $tree->findnodes('//p');
my @posts = scrape(
    $html,
    ['./a'],
    { 
        absolute => [qw[href src rel]],
        tree => $relevant,
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
], "Links get extracted correctly"
    or diag Dumper \@posts;

@posts = scrape(
    $html,
    ['a@href'],
    { 
        absolute => [qw[href src rel]],
        tree => $relevant,
        base => 'http://example.com',
    },
);

is_deeply \@posts, [
    [
      'http://example.com/foo'
    ],
], "Links get extracted correctly"
    or diag Dumper \@posts;

__DATA__
<html>
<body>
<p id="interesting">
<a href="foo">Some link</a>
<a name="bar">A name</a>
</p>
<a name="baz" href="baz">A named link</a>
<a href="http://google.com">An absolute link</a>
</body>
</html>