#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/hide_table.conf';
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestAppCustomConfig"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/autocrud/dbic/track', "Get tracks ajax page");
$mech->content_contains(
    qq{<option value="http://localhost/autocrud/dbic/$_"},
    "Tables list page contains a link to $_ table"
) for qw( artist copyright track );
$mech->content_lacks(
    qq{<option value="http://localhost/autocrud/dbic/album"},
    "Tables list page contains NO link to album table"
);



#warn $mech->content;
__END__
