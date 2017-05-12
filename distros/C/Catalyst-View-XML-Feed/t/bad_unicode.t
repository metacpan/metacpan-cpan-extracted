use strict;
use warnings;
use DateTime;
use utf8;
use Test::More;

use Catalyst::View::XML::Feed;

my $view = Catalyst::View::XML::Feed->new();
my $out = $view->render(bless({}, 'MyApp'), {
    format      => 'RSS 2.0',
    id          => 'http://foo.com/blog/',
    title       => "Example feed",
    link        => 'http://foo.com/blog/',
    modified    => DateTime->now,
    description => 'Desc',
    entries     => [
        {
            id          => 'http://foo.com/blog/post/1',
            link        => 'http://foo.com/blog/post/1',
            title       => "fooè",
            modified    => DateTime->now,
            content     => "content"
        },
    ],
});
unlike $out, qr{title>foo&#xC3;&#xA8;</title};
like $out, qr{<title>foo&#xE8;</title>};

done_testing;

