#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# normal number of skinny columns, but the headings should be
# modified as per the config.

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/headings_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album/browse", "Get HTML for album table");

my @links = $mech->find_all_links(class => 'cpac_link');
ok(scalar @links == 6, 'number of columns in table');

ok($mech->find_link(class => 'cpac_link', text => 'TheTitle'), 'second heading is TheTitle');
ok($mech->find_link(class => 'cpac_link', text => 'Recorded'), 'undefined heading is ignored');

__END__

