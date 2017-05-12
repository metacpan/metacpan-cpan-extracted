#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# basic Metadata processing - tables list
for (qw( /site/mysite/schema/foobar /site/mysite )) {
    $mech->get_ok($_, "Get tables list page ($_)");
    is($mech->ct, 'text/html', "Tables list page content type ($_)");
    $mech->content_contains(
        q{please select a table},
        "Tables list page content ($_)"
    );
}

$mech->content_contains(
    qq{<a href="http://localhost/site/mysite/schema/dbic/source/$_">},
    "Tables list page contains a link to $_ table"
) for qw( album artist copyright track );

my @links = $mech->find_all_links( url_regex => qr/localhost/ );
$mech->links_ok( [$_], 'Check table link '. $_->url ) for @links;

my $VERSION = $Catalyst::Plugin::AutoCRUD::VERSION;
foreach (qw( album artist copyright track )) {
    $mech->get_ok("/site/mysite/schema/dbic/source/$_", "Get autocrud for $_ table");
    $mech->title_is(ucfirst($_) ." List - Powered by CPAC v$VERSION", "Page title for $_");
}

#warn $mech->content;
__END__
