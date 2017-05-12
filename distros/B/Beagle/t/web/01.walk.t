use strict;
use warnings;

use Test::More;
use Beagle::Test;
use Beagle::Util;

if (is_windows()) {
    plan skip_all => 'test server do not work well on windows';
    exit;
}

use Test::WWW::Mechanize;
use Beagle::Handle;

Beagle::Test->init;
my $url = Beagle::Test->start_server( web_admin => 1 );

my $bh = Beagle::Handle->new();
my $article = Beagle::Model::Article->new(
    title => 'title foo',
    body  => 'body foo',
);
ok( $bh->create_entry($article), 'created article' );

my $m = Test::WWW::Mechanize->new;

my %walked = ( $url => 1 );
test_page($url);

sub test_page {
    my $url = shift;
    $m->get_ok($url);

    for my $link ( grep { !$walked{ $_->url_abs }++ }
        $m->find_all_links( url_regex => qr{^(?:\Q$url\E|/)\E}, ) )
    {
        test_page( $link->url_abs );
    }
}

done_testing();

