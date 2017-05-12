#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# the skinny table should have only two columns displayed,
# the rest skipped. note that accessor drives name for title.

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/columns_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album/browse", "Get HTML for album table");
#my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

my @links = $mech->find_all_links(class => 'cpac_link');
ok(scalar @links == 2, 'number of columns in table');
#print Dumper \@links;

ok($mech->find_link(class => 'cpac_link', text => 'Custom Title'), 'first heading is Custom Title');
ok($mech->find_link(class => 'cpac_link', text => 'Recorded'), 'second heading is Recorded');

__END__

