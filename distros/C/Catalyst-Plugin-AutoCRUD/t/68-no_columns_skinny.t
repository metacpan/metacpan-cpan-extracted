#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/no_columns_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album/browse", "Get HTML for album table");
my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

my @links = $mech->find_all_links(class => 'cpac_link');
ok(scalar @links == 6, 'six of columns in table');

ok($mech->find_link(class => 'cpac_link', text => 'Id'), 'first heading is Id');
ok($mech->find_link(class => 'cpac_link', text => 'Deleted'), 'fourth heading is Deleted');
ok($mech->find_link(class => 'cpac_link', text => 'Recorded'), 'third heading is Recorded');
ok($mech->find_link(class => 'cpac_link', text => 'Custom Title'), 'second heading is Custom Title');
ok($mech->find_link(class => 'cpac_link', text => 'Artist'), 'fifth heading is Artist Id');
ok($mech->find_link(class => 'cpac_link', text => 'Sleeve Notes'), 'sixth heading is Sleeve Notes');

__END__

