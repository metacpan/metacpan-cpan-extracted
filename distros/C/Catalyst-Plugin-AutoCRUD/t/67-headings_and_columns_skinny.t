#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# on skinny table test restricted columns and custom names

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/headings_and_columns_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album/browse", "Get HTML for album table");
#my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

my @links = $mech->find_all_links(class => 'cpac_link');
ok(scalar @links == 2, 'number of columns in table');

ok($mech->find_link(class => 'cpac_link', text => 'Id'), 'first heading is Id');
ok($mech->find_link(class => 'cpac_link', text => 'TheTitle'), 'second heading is TheTitle');

__END__

